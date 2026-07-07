#!/usr/bin/env bash
# rebuild-meta.sh — Single-pass meta regeneration using wiki-walk.py
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
META_DIR="$PROJECT_ROOT/meta"
WIKI_DIR="$PROJECT_ROOT/wiki"
TIMESTAMP_FILE="$WIKI_DIR/.meta_update_timestamp"

# Load centralized cleanup utilities from lib.sh
source "$SCRIPT_DIR/lib.sh" 2>/dev/null || true

cleanup_add "${META_DIR}/registry.json.tmp"
cleanup_add "${META_DIR}/backlinks.json.tmp"
cleanup_add "${WIKI_DIR}/index.md.tmp"

mkdir -p "$META_DIR"

# ─── Incremental Update Detection ──────
ALL_FILES=$(find "$WIKI_DIR" -name "*.md" -type f ! -path "*/meta/*" 2>/dev/null | wc -l)

FULL_REBUILD=false
CHANGED_LIST=""
if [[ -f "$TIMESTAMP_FILE" ]]; then
    CHANGED_LIST=$(find "$WIKI_DIR" -name "*.md" -type f ! -path "*/meta/*" -newer "$TIMESTAMP_FILE" 2>/dev/null || true)
    if [[ -z "${CHANGED_LIST:-}" ]]; then
        echo "[*] No changes detected since last rebuild. Skipping." >&2
        exit 0
    fi
    CHANGED_COUNT=$(echo "$CHANGED_LIST" | wc -l)
    echo "[*] Incremental mode: ${CHANGED_COUNT} changed files (of ${ALL_FILES} total)" >&2
    
    # Normalize to relative paths for matching with JSON output
    REL_CHANGED=""
    while IFS= read -r fpath; do
        rel="${fpath#${WIKI_DIR}/}"
        if [[ -n "$REL_CHANGED" ]]; then
            REL_CHANGED="$REL_CHANGED
$fpath"
        else
            REL_CHANGED="$fpath"
        fi
    done <<< "$CHANGED_LIST"
    CHANGED_LIST="$REL_CHANGED"
else
    FULL_REBUILD=true
    echo "[*] Full rebuild (no timestamp found)" >&2
fi

INDEX_ONLY=false
if [[ "${1:-}" == "--index-only" ]]; then
  INDEX_ONLY=true; shift; echo "Skipping registry.json and backlinks.json (--index-only mode)" >&2
fi

# ─── Single-pass wiki walk → unified JSON output (in temp file) ──
echo "[*] Single-pass wiki walk (one os.walk for all meta data)..." >&2

WALK_JSON_FILE=$(mktemp --suffix=.json)
CHANGED_FILE=$(mktemp --suffix=.txt)

# Register for centralized cleanup (lib.sh)
cleanup_add "$WALK_JSON_FILE"
cleanup_add "$CHANGED_FILE"

# Register for centralized cleanup (lib.sh)
cleanup_add "$WALK_JSON_FILE"
cleanup_add "$CHANGED_FILE"

python3 "$SCRIPT_DIR/wiki-walk.py" --json >"$WALK_JSON_FILE" 2>/dev/null || {
    echo "[!] Wiki walk failed" >&2
    exit 1
}

# Write changed files list for incremental mode (one per line)
if [[ -n "${CHANGED_LIST:-}" ]]; then
    printf '%s\n' "$CHANGED_LIST" > "$CHANGED_FILE"
fi

export WALK_JSON="$WALK_JSON_FILE"
export CHANGED_FILE_PATH="$CHANGED_FILE"
export META_DIR="${META_DIR}"
export WIKI_DIR="${WIKI_DIR}"
export SCRIPT_DIR="${SCRIPT_DIR}"
export FULL_REBUILD=${FULL_REBUILD}

# ─── 1+2. Registry + Backlinks (single Python call, T4 optimization) ──
if [[ "$INDEX_ONLY" == "false" ]]; then
echo "Building registry + backlinks..."
python3 << 'PYEOF'
import json, os

walk_file = os.environ['WALK_JSON']
changed_file_path = os.environ.get('CHANGED_FILE_PATH', '')
full_rebuild = os.environ.get('FULL_REBUILD') == 'true'
meta_dir = os.environ['META_DIR']

# Single read — both registry and backlinks share the same source
data = json.load(open(walk_file))
pages = data['pages']
backlinks = data.get('backlinks', {})

# ── Registry (incremental merge or full rebuild) ───────────────
if not full_rebuild and changed_file_path:
    existing_pages = {}
    try:
        meta_path = os.path.join(meta_dir, 'registry.json')
        with open(meta_path) as f:
            data2 = json.load(f)
            for p in data2.get('pages', []):
                existing_pages[p['path']] = p
    except Exception:
        pass

    changed_set = set(open(changed_file_path).read().strip().split('\n')) - {''}
    merged = dict(existing_pages)
    updated_count = 0
    added_count = 0
    for p in pages:
        if p['path'] in changed_set:
            merged[p['path']] = p
            updated_count += 1
        elif p['path'] not in existing_pages:
            # New file that wasn't caught by incremental detection
            merged[p['path']] = p
            added_count += 1

    pages_to_write = list(merged.values())
    print(f'Registry updated: {len(pages_to_write)} pages (+{added_count} new, ~{updated_count} changed)', file=__import__('sys').stderr)
else:
    # Full rebuild
    pages_to_write = pages

with open(os.path.join(meta_dir, 'registry.json.tmp'), 'w') as f:
    json.dump({'pages': pages_to_write}, f, indent=2, ensure_ascii=False)
print(f'Registry written: {len(pages_to_write)} pages')

# ── Backlinks (deduplicate from same data source) ───────────────
final_backlinks = {}
for target, sources in backlinks.items():
    seen = set()
    deduped = []
    for s in sources:
        if not isinstance(s, dict):
            continue
        key = (s.get('from'), s.get('context', ''))
        if key not in seen:
            seen.add(key)
            deduped.append(s)
    final_backlinks[target] = deduped

with open(os.path.join(meta_dir, 'backlinks.json.tmp'), 'w') as f:
    json.dump({'backlinks': final_backlinks}, f, indent=2, ensure_ascii=False)
print(f'Backlinks updated: {len(final_backlinks)} targets with links')
PYEOF

mv "${META_DIR}/registry.json.tmp" "${META_DIR}/registry.json"
mv "${META_DIR}/backlinks.json.tmp" "${META_DIR}/backlinks.json"
fi

# ─── 3. index.md (from unified JSON, always rebuild) ──────────────
echo "Building index.md..."
python3 << 'PYEOF'
import json, os, sys, datetime

walk_data = json.load(open(os.environ['WALK_JSON']))
category_pages = walk_data.get('categories', {})
wiki_dir = os.environ['WIKI_DIR']
script_dir = os.environ['SCRIPT_DIR']

# Read categories from rules/categories.json
cat_file = os.path.join(script_dir, "..", "rules", "categories.json")
CATEGORY_ORDER = []
CATEGORIES_LABELS_RAW = {}
try:
    with open(cat_file) as f:
        cat_data = json.load(f)
    CATEGORY_ORDER = [c['key'] for c in cat_data.get('categories', [])]
    lang = os.environ.get('LOCALE', 'en')
    CATEGORIES_LABELS_RAW = {}
    for c in cat_data.get('categories', []):
        labels = c.get('label', {})
        CATEGORIES_LABELS_RAW[c['key']] = labels.get(lang, labels.get('en', c['key'].title()))
except Exception:
    CATEGORY_ORDER = ['entities', 'concepts', 'comparisons', 'syntheses', 'overviews', 'notes', 'meetings', 'projects', 'bibliography', 'resources']
    CATEGORIES_LABELS_RAW = {'entities': 'Entities', 'concepts': 'Concepts', 'comparisons': 'Comparisons', 'syntheses': 'Syntheses', 'overviews': 'Overviews', 'notes': 'Notes'}

def cat_label(k):
    raw = CATEGORIES_LABELS_RAW.get(k, k.title())
    return raw if isinstance(raw, str) else raw.get('en', k.title())

lines_out = ['# Wiki Index', '', '']
for cat_key in CATEGORY_ORDER:
    display_name = cat_label(cat_key)
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
    '*Created: auto-generated | Last updated: ' + datetime.datetime.now().strftime('%Y-%m-%d %H:%M') + '*',
    '',
    '## Timeline',
    '| Дата | Событие |',
    '|------|---------|',
    '| [Timeline](timeline.md) — полная хронологическая лента всех изменений.'
])

with open(os.path.join(wiki_dir, 'index.md.tmp'), 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines_out) + '\n')

print(f'Index updated: {sum(len(v) for v in category_pages.values())} entries across {len(category_pages)} categories')
PYEOF

mv "${WIKI_DIR}/index.md.tmp" "${WIKI_DIR}/index.md"

# ─── 4. IDF cache → invalidate on wiki changes (auto-rebuilt by prf_extract.py) ──
rm -f "${META_DIR}/idf_cache.json"
echo "IDF cache invalidated (will rebuild on next recall)"

# ─── Move timestamp ────
touch "$TIMESTAMP_FILE"
echo "✅ Meta rebuild complete."
