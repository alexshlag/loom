#!/usr/bin/env bash
# rebuild-meta.sh — пересобирает все meta-файлы из wiki/
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
META_DIR="$PROJECT_ROOT/meta"
WIKI_DIR="$PROJECT_ROOT/wiki"

mkdir -p "$META_DIR"

# ─── 1. registry.json ──────────────────────────────────────
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

with open(meta_path, 'w') as f:
    json.dump({'backlinks': backlinks}, f, indent=2, ensure_ascii=False)
print(f'Backlinks updated: {len(backlinks)} pages with links')
" 2>&1 || echo "Warning: backlinks generation had issues"

echo "✅ Meta rebuild complete."
