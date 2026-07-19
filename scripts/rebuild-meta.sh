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

# ─── Parse arguments ──────────────────────────────────────────────────────
FULL_REBUILD=false
INDEX_ONLY=false

if [[ "${1:-}" == "--full" ]]; then
  FULL_REBUILD=true; shift || true
fi

if [[ "${1:-}" == "--index-only" ]]; then
  INDEX_ONLY=true; shift || true
fi

# ─── Incremental Update Detection ──────
ALL_FILES=$(find "$WIKI_DIR" -name "*.md" -type f ! -path "*/meta/*" 2>/dev/null | wc -l)

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

# ─── Single-pass wiki walk → unified JSON output (in temp file) ──
echo "[*] Single-pass wiki walk (one os.walk for all meta data)..." >&2

WALK_JSON_FILE=$(mktemp --suffix=.json)
CHANGED_FILE=$(mktemp --suffix=.txt)

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

# ── Write backlinks.json.tmp ───────────────────────────────────────
with open(os.path.join(meta_dir, 'backlinks.json.tmp'), 'w') as f:
    json.dump(final_backlinks, f, indent=2, ensure_ascii=False)
print(f'Backlinks written: {len(final_backlinks)} targets', file=__import__('sys').stderr)

PYEOF
else
  echo "Building index only..."
  python3 << 'PYEOF'
import json, os

walk_file = os.environ['WALK_JSON']
meta_dir = os.environ['META_DIR']

data = json.load(open(walk_file))
pages = data['pages']

with open(os.path.join(meta_dir, 'registry.json.tmp'), 'w') as f:
    json.dump({'pages': pages}, f, indent=2, ensure_ascii=False)
print(f'Registry written: {len(pages)} pages')
PYEOF
fi

# ─── 3. Update index.md (if not --index-only) ──────────────────────────
if [[ "$INDEX_ONLY" == "false" ]]; then
    echo "[*] Updating wiki/index.md..." >&2
    
    INDEX_PATH="$WIKI_DIR/index.md"
    
    # Build the index from scratch using the unified data source
    python3 << PYEOF
import json, os

walk_file = os.environ['WALK_JSON']
meta_dir = os.environ['META_DIR']
wiki_dir = os.environ['WIKI_DIR']

# Load registry and backlinks
with open(os.path.join(meta_dir, 'registry.json')) as f:
    registry_data = json.load(f)
    pages = registry_data.get('pages', [])

with open(os.path.join(meta_dir, 'backlinks.json')) as f:
    backlinks = json.load(f)

# Build index.md from registry data
index_path = os.path.join(wiki_dir, 'index.md')
with open(index_path, 'w') as f:
    f.write('# Loomana Wiki\n\n')
    for page in pages:
        path = page.get('path', '')
        title = page.get('title', path)
        f.write(f'## [{title}]({path})\n\n')

print(f'Index written: {len(pages)} pages')
PYEOF
else
  echo "[*] Index only mode - skipping registry/backlinks update" >&2
fi

# ─── Cleanup temporary files ─────────────────────────────────────────────
rm -f "$WALK_JSON_FILE" "$CHANGED_FILE" 2>/dev/null || true

# ─── Update timestamp file ──────────────────────────────────────────────
echo "$(date +%Y-%m-%dT%H:%M:%SZ)" > "$TIMESTAMP_FILE"
