#!/usr/bin/env bash
# rebuild-meta.sh — пересобирает все meta-файлы из wiki/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
META_DIR="$PROJECT_ROOT/meta"
WIKI_DIR="$PROJECT_ROOT/wiki"

mkdir -p "$META_DIR"

# Parse --index-only flag: rebuild only index.md, skip registry/backlinks
INDEX_ONLY=false
if [[ "${1:-}" == "--index-only" ]]; then
  INDEX_ONLY=true; shift; echo "Skipping registry.json and backlinks.json (--index-only mode)"
fi

if [[ "$INDEX_ONLY" == "false" ]]; then
# ─── 1. registry.json (skip if --index-only) ──────────────
echo "Building registry..."
cat > "$META_DIR/registry.json" << 'REOF'
{
  "pages": []
}
REOF

python3 -c "
import json, os, re

wiki_dir = '$WIKI_DIR'
meta_path = '$META_DIR/registry.json'

def parse_frontmatter(content):
    tags = []
    date = ''
    sources = []
    for line in content.split('\n')[:10]:
        if line.startswith('tags:'):
            tags = [t.strip() for t in re.findall(r'\[(.*?)\]', line) for t in t.split(',')]
        elif line.startswith('date:'):
            date = line.split(': ')[1].strip()
        elif line.startswith('sources:'):
            sources = [s.strip().strip('[]').split(',')[0] if ',' not in s else None for s in re.findall(r'\[(.*?)\]', line)]
    return tags, date, sources

def get_page_type(path):
    rel = os.path.relpath(path, wiki_dir)
    parts = rel.split('/')
    if len(parts) > 1:
        return parts[0].replace('-', '_') + 's'
    return 'root_file'

pages = []
for root, dirs, files in os.walk(wiki_dir):
    for fname in files:
        if not fname.endswith('.md'):
            continue
        fpath = os.path.join(root, fname)
        rel = os.path.relpath(fpath, wiki_dir).replace('/', '-').replace('.', '-')
        with open(fpath, 'r', encoding='utf-8') as f:
            content = f.read(2000)
        tags, date, sources = parse_frontmatter(content)
        
        # Read title from heading
        title_match = re.search(r'^# (.+)', content, re.MULTILINE)
        title = title_match.group(1).strip() if title_match else fname.replace('.md', '').replace('-', ' ').title()
        
        page_type = get_page_type(fpath)
        pages.append({
            'id': rel.replace('wiki/', '').replace('/', '-').replace('.', '-'),
            'title': title,
            'type': page_type,
            'path': os.path.relpath(fpath, '$PROJECT_ROOT'),
            'date_created': date or 'unknown',
            'tags': tags,
            'sources': sources
        })

with open(meta_path, 'w') as f:
    json.dump({'pages': pages}, f, indent=2, ensure_ascii=False)
print(f'Registry updated: {len(pages)} pages')
" 2>&1 || echo "Warning: registry generation had issues"

# ─── 2. backlinks.json (parse [text](path) markdown links from all wiki pages) ──────
python3 -c "
import os, re, json
from urllib.parse import unquote

wiki_dir = '$WIKI_DIR'
meta_path = '$META_DIR/backlinks.json'

backlinks = {}

def resolve_target(path):
    \"\"\"Resolve wiki-relative path to target page id.\"\"\"
    # Remove leading ./ or ../ and normalize
    cleaned = path.lstrip('/').lstrip('./') if not path.startswith('../') else path
    if '/' in cleaned:
        return cleaned.replace('/', '-').replace('.', '-')
    return cleaned.replace(' ', '').replace('-', '_').title()

for root, dirs, files in os.walk(wiki_dir):
    for fname in files:
        if not fname.endswith('.md'):
            continue
        fpath = os.path.join(root, fname)
        rel = os.path.relpath(fpath, wiki_dir).replace('/', '-').replace('.', '-')
        
        with open(fpath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Find [text](path) markdown links
        links = re.findall(r'\[([^\]]+)\]\(([^#)]+)(?:#[^)]+)?\)', content)
        if links:
            for text, path in links:
                target_id = resolve_target(path.rstrip('/'))
                backlinks.setdefault(target_id, []).append({
                    'from': rel,
                    'context': f'[text]({path}) from {fname}'
                })
        
        # Parse related: [paths] frontmatter arrays
        import re
        related_matches = re.findall(r'^related:\s*\[(.*)\]', content, re.MULTILINE)
        for related_str in related_matches:
            paths = [p.strip().strip('\"').strip(\"'\") for p in related_str.split(',')]
            for path in paths:
                if not path:
                    continue
                target_id = resolve_target(path.rstrip('/'))
                backlinks.setdefault(target_id, []).append({
                    'from': rel,
                    'context': f'related:[{path}] from {fname}'
                })

with open(meta_path, 'w') as f:
    json.dump({'backlinks': backlinks}, f, indent=2, ensure_ascii=False)
print(f'Backlinks updated: {len(backlinks)} pages with links')
" 2>&1 || echo "Warning: backlinks generation had issues"
fi

# ─── 3. index.md (auto-update from wiki pages by category) ──────
echo "Building index.md..."

python3 -c "
import os, re, datetime
from collections import OrderedDict

wiki_dir = '$WIKI_DIR'
index_path = os.path.join(wiki_dir, 'index.md')
project_root = '$PROJECT_ROOT'

# Category mapping: dir_name -> display name (Russian)
CATEGORIES = {
    'entities': 'Сущности',
    'concepts': 'Концепции',
    'comparisons': 'Сравнения',
    'syntheses': 'Синтезы',
    'overviews': 'Обзоры',
    'notes': 'Заметки',
    'meetings': 'Встречи',
    'projects': 'Проекты',
    'bibliography': 'Библиография',
    'resources': 'Ресурсы'
}

# Priority order for categories (syntheses/concepts/entities first)
CATEGORY_ORDER = ['entities', 'concepts', 'comparisons', 'syntheses', 'overviews', 
                 'notes', 'meetings', 'projects', 'bibliography', 'resources']

def extract_summary(content):
    '''Extract first 2-3 sentences after frontmatter (before any ## heading).'''
    lines = content.split('\n')
    
    # Find end of YAML frontmatter (second ---)
    fm_end = -1
    dashes_found = 0
    for i, line in enumerate(lines):
        if line.strip() == '---':
            dashes_found += 1
            if dashes_found == 2:
                fm_end = i + 1
                break
    
    # If no frontmatter found, start from beginning
    if fm_end < 0:
        fm_end = 0
    else:
        fm_end += 1  # Skip the closing --- line
    
    # Collect text until first ## heading (skip empty lines and H1)
    section_lines = []
    for i in range(fm_end, len(lines)):
        stripped = lines[i].strip()
        if not stripped or stripped.startswith('# '):
            continue
        if stripped.startswith('## '):
            break
        # Skip YAML frontmatter artifacts and blockquotes
        if stripped.startswith('- ') or stripped.startswith('* '):
            continue
        section_lines.append(stripped)
    
    # If no prose found, look for content after ## headings (description paragraphs)
    if not section_lines:
        skip_until_prose = False
        for i in range(fm_end, len(lines)):
            stripped = lines[i].strip()
            if not stripped or re.match(r'^## ', stripped):
                continue
            # Skip YAML-style metadata patterns
            if re.match(r'^(tags|date|sources|related)\s*:', stripped.lower()):
                continue
            # Skip blockquotes and list-style metadata
            if stripped.startswith('>') or stripped.startswith('- ') or stripped.startswith('* '):
                continue
            section_lines.append(stripped)
            if len(section_lines) >= 6:
                break
    
    # Join and extract first 2-3 sentences (up to 150 chars)
    full_text = ' '.join(section_lines[:6])
    summary = full_text[:150]
    if len(full_text) > 150:
        # Find last complete sentence
        last_dot = max(summary.rfind('.'), summary.rfind('!'), summary.rfind('?'))
        if last_dot > 20:
            summary = summary[:last_dot + 1]
    
    if not summary or len(summary) < 10:
        summary = 'Страница без описания.'
    return summary

# Collect pages by category
category_pages = {cat: [] for cat in CATEGORY_ORDER}

for root, dirs, files in os.walk(wiki_dir):
    # Skip meta/ and raw/
    if 'meta' in root or 'raw' in root:
        continue
    
    for fname in files:
        if not fname.endswith('.md'):
            continue
        fpath = os.path.join(root, fname)
        rel_path = os.path.relpath(fpath, wiki_dir).replace(chr(92), '/')
        
        with open(fpath, 'r', encoding='utf-8') as f:
            content = f.read(2000)
        
        # Extract title from H1
        title_match = re.search(r'^# (.+)', content, re.MULTILINE)
        title = title_match.group(1).strip() if title_match else fname.replace('.md', '').replace('-', ' ').title()
        
        # Determine category (first subdirectory level)
        parts = rel_path.split('/')
        cat_dir = None
        for part in parts:
            if part in CATEGORIES:
                cat_dir = part
                break
        
        if cat_dir is None and len(parts) <= 1:
            # Root wiki files (overview.md, timeline.md, etc.) - treat as 'overviews'
            if fname == 'timeline.md':
                continue  # Timeline has special section at bottom of index
            elif fname in ['overview.md', 'snapshot.md']:
                cat_dir = 'overviews'
            else:
                continue  # Skip non-categorized root files from auto-indexing
        
        summary = extract_summary(content)
        category_pages.setdefault(cat_dir, []).append({
            'title': title,
            'path': rel_path,
            'summary': summary
        })

# Generate index.md
now_str = datetime.datetime.now().strftime('%Y-%m-%d %H:%M')
lines = ['# Wiki Index', '', '']
for cat_key in CATEGORY_ORDER:
    display_name = CATEGORIES.get(cat_key, cat_key.title())
    pages = category_pages.get(cat_key, [])
    
    lines.append(f'## {display_name}')
    if not pages:
        lines.append('')  # Empty section
    else:
        for page in sorted(pages, key=lambda x: x['title']):
            lines.append('* [' + page['title'] + '](' + page['path'] + ') — ' + page['summary'])
    lines.append('')  # Blank line after each section

# Add timeline reference at bottom
lines.extend([
    '---',
    f'*Created: auto-generated | Last updated: {now_str}*',
    '',
    '## Хронология',
    '| Дата | Событие |',
    '|------|---------|',
    '| [Timeline](timeline.md) — полная хронологическая лента всех изменений.'
])

# Write index.md (preserve original if exists, otherwise create new)
with open(index_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines) + '\n')

print(f'Index updated: {sum(len(v) for v in category_pages.values())} entries across {len(category_pages)} categories')
" 2>&1 || echo "Warning: index generation had issues"

echo "✅ Meta rebuild complete."
