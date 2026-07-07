#!/usr/bin/env bash
# check-new-sources.sh — Checks raw/sources for new packages not yet in tracking/raw_registry.json
# Usage: ./scripts/check-new-sources.sh [--quick] [raw_dir] [registry_file]
# Exit code: 0 = no new sources, 1 = new sources found (printed to stdout), 2 = cached_skip (--quick only)
#
# Modes:
#   default — полный режим: выводит NEW: <package_id> для каждого нового пакета (max: 10)
#   --quick — fast mode: only exit_code, no package output. Caches timestamp (~1h).
#   --max N — search depth limit (default: 10). Warning when exceeded.

source "$(dirname "$0")/lib.sh" || true
_set_cleanup_trap  # enable cleanup_temp_files for atomic_write_content internal cleanup_add calls
MAX_SOURCES=10

QUICK=false
MAX_COUNT=""
while [[ "${1:-}" == --* ]]; do
    case "$1" in
        --quick) QUICK=true; shift;;
        --max) MAX_COUNT="$2"; shift 2;;
        *) shift;;
    esac
done
if [ -n "$MAX_COUNT" ]; then
    MAX_SOURCES=$MAX_COUNT
fi
RAW_DIR="${1:-raw/sources/}"
REGISTRY_FILE="${2:-tracking/raw_registry.json}"
CACHE_FILE="tracking/last_check.json"

# Temp files cleaned via cleanup_temp_files (EXIT trap set by _set_cleanup_trap)

# Create registry if it doesn't exist
mkdir -p "$(dirname "$REGISTRY_FILE")"
if [ ! -f "$REGISTRY_FILE" ]; then
    atomic_write_content "$REGISTRY_FILE" '{"ingested_sources": []}'
fi

# --- Quick mode: cache check (skip if checked <1h ago) ---
if [ "$QUICK" = true ] && [ -f "$CACHE_FILE" ]; then
    last_check=$(python3 -c "import json; print(json.load(open('$CACHE_FILE')).get('last_check', 0))")
    now=$(date +%s)
    if [ $((now - last_check)) -lt 3600 ]; then
        exit 2
    fi
fi

# --- Scan for new sources ---
packages=$(ls -1d "$RAW_DIR"/SRC-* 2>/dev/null || true)

if [ -z "$packages" ]; then
    if [ "$QUICK" = true ]; then
        # Update cache to avoid repeated calls
        atomic_write_content "$CACHE_FILE" "{\"last_check\": $(date +%s)}"
    fi
    exit 0
fi

# Count already-processed IDs from registry
ingested_ids=$(python3 -c "
import json, sys
with open('$REGISTRY_FILE') as f:
    data = json.load(f)
sources = set(data.get('ingested_sources', []))
for s in sources:
    print(s)
")

# Compare
found_new=false
NEW_COUNT=0
while IFS= read -r pkg; do
    pkg_id=$(basename "$pkg")
    
    if ! echo "$ingested_ids" | grep -q "^${pkg_id}$"; then
        NEW_COUNT=$((NEW_COUNT + 1))
        if [ "$QUICK" != true ] && [ "$NEW_COUNT" -le "$MAX_SOURCES" ]; then
            echo "NEW: $pkg_id"
        elif [ "$NEW_COUNT" -gt "$MAX_SOURCES" ] && [ "$QUICK" = false ]; then
            # Warn about exceeding limit
            REMAINING=$((NEW_COUNT - MAX_SOURCES))
            echo "WARNING: ${REMAINING} more sources available (limit: $MAX_SOURCES)"
        fi
        found_new=true
    fi
done <<< "$packages"

if [ "$found_new" = true ]; then
    if [ "$QUICK" = true ]; then
        # Update cache to avoid repeated calls
        atomic_write_content "$CACHE_FILE" "{\"last_check\": $(date +%s)}"
    fi
    exit 1
else
    if [ "$QUICK" = true ]; then
        # Update cache — no new sources, skip re-check
        atomic_write_content "$CACHE_FILE" "{\"last_check\": $(date +%s)}"
    fi
    exit 0
fi
