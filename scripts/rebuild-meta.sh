#!/usr/bin/env bash
# rebuild-meta.sh — пересобирает meta-файлы из wiki/ (инкрементальный режим)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
META_DIR="$PROJECT_ROOT/meta"
WIKI_DIR="$PROJECT_ROOT/wiki"
TIMESTAMP_FILE="$WIKI_DIR/.meta_update_timestamp"

# Trap cleanup for .tmp files on crash/abort
trap 'rm -f "${META_DIR}/registry.json.tmp" "${META_DIR}/backlinks.json.tmp" "${WIKI_DIR}/index.md.tmp" 2>/dev/null' EXIT

mkdir -p "$META_DIR"

# ─── Incremental Update Detection (MEDIUM-4 optimization) ──────
ALL_FILES=$(find "$WIKI_DIR" -name "*.md" -type f ! -path "*/meta/*" 2>/dev/null | wc -l)

FULL_REBUILD=false
CHANGED_FILES=""
if [[ -f "$TIMESTAMP_FILE" ]]; then
    CHANGED_FILES=$(find "$WIKI_DIR" -name "*.md" -type f ! -path "*/meta/*" -newer "$TIMESTAMP_FILE" 2>/dev/null || true)
    if [[ -z "$CHANGED_FILES" ]]; then
        echo "[*] No changes detected since last rebuild. Skipping." >&2
        exit 0
    fi
    CHANGED_COUNT=$(echo "$CHANGED_FILES" | wc -l)
    echo "[*] Incremental mode: ${CHANGED_COUNT} changed files (of ${ALL_FILES} total)" >&2
else
    FULL_REBUILD=true
    echo "[*] Full rebuild (no timestamp found)" >&2
fi

INDEX_ONLY=false
if [[ "${1:-}" == "--index-only" ]]; then
  INDEX_ONLY=true; shift; echo "Skipping registry.json and backlinks.json (--index-only mode)" >&2
fi

if [[ "$FULL_REBUILD" == "true" ]]; then
    CHANGED_LIST="/all"
else
    CHANGED_LIST=$(echo "$CHANGED_FILES" | tr '\n' ',' || true)
fi

# ─── 1. registry.json (skip if --index-only) ──────────────
if [[ "$INDEX_ONLY" == "false" ]]; then
echo "Building registry..."
python3 << PYEOF
import json, os, re, sys
sys.path.insert(0, "${SCRIPT_DIR}")

wiki_dir = "${WIKI_DIR}"
meta_path = "${META_DIR}/registry.json"
changed_str = "${CHANGED_LIST}"

def parse_frontmatter(content):
    tags, date, sources = [], '', []
    aliases = []
    for line in content.split('\n')[:10]:
        if line.startswith('tags:'):
            tags = [t.strip() for t in re.findall(r'\[(.*?)\]', line) for t in t.split(',')]
        elif line.startswith('date:'):
            date = line.split(': ')[1].strip()
        elif line.startswith('sources:'):
            sources = [s.strip().strip('[]').split(',')[0] if ',' not in s else None for s in re.findall(r'\[(.*?)\]', line)]
        elif line.startswith('aliases:'):
            aliases = [t.strip() for t in re.findall(r'\[(.*?)\]', line) for t in t.split(',')]
    return tags, date, sources, aliases

def get_page_type(path):
    rel = os.path.relpath(path, wiki_dir)
    parts = rel.split('/')
    if len(parts) > 1:
        return parts[0].replace('-', '_') + 's'
    return 'root_file'

existing_registry = {}
try:
    with open(meta_path) as f:
        data = json.load(f)
        existing_registry = {p['path']: p for p in data.get('pages', [])}
except Exception:
    pass

full_rebuild = (changed_str == '/all')

def should_process(filepath):
    if full_rebuild:
        return True
    return filepath in [f.strip() for f in changed_str.split(',')]

pages = [] if full_rebuild else list(existing_registry.values())
for root, dirs, files in os.walk(wiki_dir):
    if 'meta' in root or 'raw' in root:
        continue
    for fname in sorted(files):
        if not fname.endswith('.md'):
            continue
        fpath = os.path.join(root, fname)
        if not should_process(fpath):
            continue
        rel = os.path.relpath(fpath, wiki_dir).replace('/', '-').replace('.', '-')
        with open(fpath, 'r', encoding='utf-8') as f:
            content = f.read(2000)
        tags, date, sources, aliases = parse_frontmatter(content)
        title_match = re.search(r'^# (.+)', content, re.MULTILINE)
        title = title_match.group(1).strip() if title_match else fname.replace('.md', '').replace('-', ' ').title()
        page_type = get_page_type(fpath)
        new_entry = {
            'id': rel.replace('wiki/', '').replace('/', '-').replace('.', '-'),
            'title': title,
            'type': page_type,
            'path': os.path.relpath(fpath, "${PROJECT_ROOT}"),
            'date_created': date or 'unknown',
            'tags': tags,
            'sources': sources,
            'aliases': aliases
        }
        found = False
        for i, p in enumerate(pages):
            if p['path'] == new_entry['path']:
                pages[i] = new_entry
                found = True
                break
        if not found:
            pages.append(new_entry)

with open(meta_path + '.tmp', 'w') as f:
    json.dump({'pages': pages}, f, indent=2, ensure_ascii=False)
print(f'Registry updated: {len(pages)} pages' + (' (incremental)' if changed_str != '/all' else ''))
PYEOF
BL_PATH="${META_DIR}/backlinks.json"
if [ $? -ne 0 ]; then
    rm -f "${META_DIR}/registry.json.tmp"
    echo "Warning: registry generation had issues" >&2
else
    mv "${META_DIR}/registry.json.tmp" "${META_DIR}/registry.json"
fi

# ─── 2. backlinks.json (skip if --index-only)
echo "Building backlinks..."
python3 << PYEOF2
import os, re, json, sys
sys.path.insert(0, "${SCRIPT_DIR}")

wiki_dir = "${WIKI_DIR}"
meta_path = "${META_DIR}/backlinks.json"
changed_str = "${CHANGED_LIST}"
full_rebuild = (changed_str == '/all')

def resolve_target(path):
    cleaned = path.lstrip('/').lstrip('./') if not path.startswith('../') else path
    return cleaned.replace('/', '-').replace('.', '-')

existing_backlinks = {}
if not full_rebuild:
    try:
        with open(meta_path) as f:
            data = json.load(f)
            existing_backlinks = dict(data.get('backlinks', {}))
    except Exception:
        pass

def should_process(filepath):
    if full_rebuild:
        return True
    return filepath in [f.strip() for f in changed_str.split(',')]

def clean_duplicates(backlink_list):
    seen_from = set()
    result = []
    for b in backlink_list:
        key = (b.get('from'), b.get('context', ''))
        if not any(k == key for k in seen_from):
            seen_from.add(key)
            result.append(b)
    return result

for root, dirs, files in os.walk(wiki_dir):
    if 'meta' in root or 'raw' in root:
        continue
    for fname in sorted(files):
        if not fname.endswith('.md'):
            continue
        fpath = os.path.join(root, fname)
        if not should_process(fpath):
            continue
        rel = os.path.relpath(fpath, wiki_dir).replace('/', '-').replace('.', '-')
        with open(fpath, 'r', encoding='utf-8') as f:
            content = f.read()
        links = re.findall(r'\[([^\]]+)\]\(([^#)]+)(?:#[^)]+)?\)', content)
        if links:
            for text, path in links:
                target_id = resolve_target(path.rstrip('/'))
                existing_backlinks.setdefault(target_id, []).append({
                    'from': rel,
                    'context': '[text](' + path + ') from ' + fname
                })
        related_matches = re.findall(r'^related:\s*\[(.*)\]', content, re.MULTILINE)
        for related_str in related_matches:
            paths = [p.strip().strip('"').strip("'") for p in related_str.split(',')]
            for path in paths:
                if not path:
                    continue
                target_id = resolve_target(path.rstrip('/'))
                existing_backlinks.setdefault(target_id, []).append({
                    'from': rel,
                    'context': 'related:[' + path + '] from ' + fname
                })

final_backlinks = {}
for target, sources in existing_backlinks.items():
    final_backlinks[target] = clean_duplicates(sources)

with open(meta_path + '.tmp', 'w') as f:
    json.dump({'backlinks': final_backlinks}, f, indent=2, ensure_ascii=False)
print(f'Backlinks updated: {len(final_backlinks)} pages with links' + (' (incremental)' if changed_str != '/all' else ''))
PYEOF2
if [ $? -ne 0 ]; then
    rm -f "${BL_PATH}.tmp"
    echo "Warning: backlinks generation had issues" >&2
else
    mv "${BL_PATH}.tmp" "$BL_PATH"
fi
fi

# ─── 3. index.md (always rebuild) ──────
echo "Building index.md..."
python3 << PYEOF3
import os, re, datetime, sys
sys.path.insert(0, "${SCRIPT_DIR}")

wiki_dir = "${WIKI_DIR}"
index_path = os.path.join(wiki_dir, 'index.md')

# Read categories from canonical source (rules/categories.json)
cat_file = os.path.join(os.environ.get("SCRIPT_DIR", "scripts"), "..", "rules", "categories.json")
try:
    with open(cat_file) as f:
        cat_data = json.load(f)
    CATEGORY_ORDER = [c["key"] for c in cat_data.get("categories", [])]
    # Build label lookup: key -> {lang: display_name}
    CATEGORIES_LABELS_RAW = {}
    for c in cat_data.get("categories", []):
        labels = c.get("label", {})
        lang = os.environ.get("LOCALE", "en")
        CATEGORIES_LABELS_RAW[c["key"]] = labels.get(lang, labels.get("en", c["key"].title()))
except Exception:
    # Fallback to hardcoded if JSON unavailable
    CATEGORY_ORDER = ['entities', 'concepts', 'comparisons', 'syntheses', 'overviews', 'notes', 'meetings', 'projects', 'bibliography', 'resources']
    CATEGORIES_LABELS_RAW = {'entities': 'Сущности', 'concepts': 'Концепции', 'comparisons': 'Сравнения', 'syntheses': 'Синтезы', 'overviews': 'Обзоры', 'notes': 'Заметки', 'meetings': 'Встречи', 'projects': 'Проекты', 'bibliography': 'Библиография', 'resources': 'Ресурсы'}

# CATEGORIES dict for backward compat with existing code patterns
def _cat_label(k):
    raw = CATEGORIES_LABELS_RAW.get(k, k.title())
    return raw if isinstance(raw, str) else raw.get(lang, raw.get('en', k.title()))

CATEGORIES = {k: _cat_label(k) for k in CATEGORY_ORDER}

def extract_summary(content):
    import re as _re
    # Parse tags from frontmatter
    tags = []
    aliases = []
    for line in content.split('\n')[:10]:
        if line.startswith('tags:'):
            raw_tags = [t.strip() for t in _re.findall(r'\\[(.*?)\\]', line)]
            tags = [t for t in raw_tags if t and len(t) > 2]
        elif line.startswith('aliases:'):
            raw_aliases = [a.strip().strip('\"') for a in _re.findall(r'\\[(.*?)\\]', line)]
            aliases = [a for a in raw_aliases if a]
    
    lines = content.split('\n')
    fm_end = -1
    dashes_found = 0
    for i, line in enumerate(lines):
        if line.strip() == '---':
            dashes_found += 1
            if dashes_found == 2:
                fm_end = i + 1
                break
    if fm_end < 0:
        fm_end = 0
    else:
        fm_end += 1
    
    section_lines = []
    for i in range(fm_end, len(lines)):
        stripped = lines[i].strip()
        if not stripped or stripped.startswith('# '):
            continue
        if stripped.startswith('## '):
            break
        if stripped.startswith('- ') or stripped.startswith('* '):
            continue
        section_lines.append(stripped)
    
    if not section_lines:
        for i in range(fm_end, len(lines)):
            stripped = lines[i].strip()
            if not stripped or re.match(r'^## ', stripped):
                continue
            if re.match(r'^(tags|date|sources|related)\s*:', stripped.lower()):
                continue
            if stripped.startswith('>') or stripped.startswith('- ') or stripped.startswith('* '):
                continue
            section_lines.append(stripped)
            if len(section_lines) >= 6:
                break
    
    full_text = ' '.join(section_lines[:6])
    summary = full_text[:150]
    if len(full_text) > 150:
        last_dot = max(summary.rfind('.'), summary.rfind('!'), summary.rfind('?'))
        if last_dot > 20:
            summary = summary[:last_dot + 1]
    
    return summary, tags, [], aliases

category_pages = {cat: [] for cat in CATEGORY_ORDER}
for root, dirs, files in os.walk(wiki_dir):
    if 'meta' in root or 'raw' in root:
        continue
    for fname in sorted(files):
        if not fname.endswith('.md'):
            continue
        fpath = os.path.join(root, fname)
        rel_path = os.path.relpath(fpath, wiki_dir).replace(chr(92), '/')
        with open(fpath, 'r', encoding='utf-8') as f:
            content = f.read(2000)
        
        title_match = re.search(r'^# (.+)', content, re.MULTILINE)
        title = title_match.group(1).strip() if title_match else fname.replace('.md', '').replace('-', ' ').title()
        
        parts = rel_path.split('/')
        cat_dir = None
        for part in parts:
            if part in CATEGORIES:
                cat_dir = part
                break
        
        if cat_dir is None and len(parts) <= 1:
            if fname == 'timeline.md':
                continue
            elif fname in ['overview.md', 'snapshot.md']:
                cat_dir = 'overviews'
            else:
                continue
        
        summary, page_tags, _sources, page_aliases = extract_summary(content)
        category_pages.setdefault(cat_dir, []).append({
            'title': title,
            'path': rel_path,
            'summary': summary,
            'tags': page_tags,
            'aliases': page_aliases
        })

now_str = datetime.datetime.now().strftime('%Y-%m-%d %H:%M')
lines_out = ['# Wiki Index', '', '']
for cat_key in CATEGORY_ORDER:
    display_name = CATEGORIES.get(cat_key, cat_key.title())
    pages_list = category_pages.get(cat_key, [])
    
    lines_out.append('## ' + display_name)
    if not pages_list:
        lines_out.append('')
    else:
        for page in sorted(pages_list, key=lambda x: x['title']):
            tag_str = ' '.join(f'[{t}]' for t in page.get('tags', [])[:3]) if page.get('tags') else ''
            alias_str = ' '.join(f'[{a}]' for a in page.get('aliases', [])[:2]) if page.get('aliases') else ''
            extra = f' — {tag_str}' + (f' ({alias_str})' if alias_str else '') if tag_str else ''
            lines_out.append('* [' + page['title'] + '](' + page['path'] + ') — ' + page['summary'] + extra)
    lines_out.append('')

lines_out.extend([
    '---',
    '*Created: auto-generated | Last updated: ' + now_str + '*',
    '',
    '## Хронология',
    '| Дата | Событие |',
    '|------|---------|',
    '| [Timeline](timeline.md) — полная хронологическая лента всех изменений.'
])

with open(index_path + '.tmp', 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines_out) + '\n')

print('Index updated: ' + str(sum(len(v) for v in category_pages.values())) + ' entries across ' + str(len(category_pages)) + ' categories')
PYEOF3
IDX_PATH="${WIKI_DIR}/index.md"
if [ $? -ne 0 ]; then
    rm -f "${WIKI_DIR}/index.md.tmp"
    echo "Warning: index generation had issues" >&2
else
    mv "${WIKI_DIR}/index.md.tmp" "$IDX_PATH"
fi

# ─── Update timestamp for next incremental detection ──────
touch "$TIMESTAMP_FILE"

echo "✅ Meta rebuild complete."
