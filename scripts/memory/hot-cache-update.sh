#!/usr/bin/env bash
# hot-cache-update.sh — Check-only mode for hot cache optimization
# Phase 16.1 Task #4: Skip rebuild if wiki unchanged since last session
# 
# Usage: ./hot-cache-update.sh [--check-only] [--rebuild]
# Returns: exit code 0 = "no changes" (skip), exit code 1 = "changes detected" (rebuild needed)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# memory/ is nested two levels deep → go up two directories
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"
WIKI_DIR="wiki"
HOT_FILE="$WIKI_DIR/hot.md"
CHECK_ONLY=true
FORCE_REBUILD=false

# ─── Parse arguments ──────────────────────────────────────────────────────────
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --rebuild) FORCE_REBUILD=true; shift;;
        --check-only) shift;;  # default mode, explicit flag accepted
        *) POSITIONAL_ARGS+=("$1"); shift;;
    esac
done

# ─── Check-only mode logic ──────────────────────────────────────────────────

check_hot_cache() {
    # If hot.md doesn't exist → needs first-time generation (exit 1)
    if [[ ! -f "$HOT_FILE" ]]; then
        echo "[*] HOT CACHE STALE: no existing hot.md — full rebuild needed" >&2
        return 1
    fi
    
    # Get timestamp of last modification for hot.md (in seconds since epoch)
    local hot_mtime=0
    if [[ -f "$HOT_FILE" ]]; then
        hot_mtime=$(stat -c %Y "$HOT_FILE" 2>/dev/null || echo "0")
    fi
    
    # Find all .md files in wiki/ EXCEPT hot.md itself, check timestamps against hot.md mtime
    local latest_wiki_mtime=0
    
    while IFS= read -r -d '' file; do
        [[ "$file" == "$HOT_FILE" ]] && continue  # Skip hot.md — we compare OTHER files to it
        local file_mtime=0
        file_mtime=$(stat -c %Y "$file" 2>/dev/null || echo "0")
        
        # Track the most recent wiki modification
        if [[ "$file_mtime" -gt "$latest_wiki_mtime" ]]; then
            latest_wiki_mtime=$file_mtime
        fi
    done < <(find "$WIKI_DIR" -name "*.md" -type f -print0 2>/dev/null || true)
    
    # Compare timestamps: if any wiki file newer than hot.md → changes detected
    if [[ "$latest_wiki_mtime" -gt "$hot_mtime" ]]; then
        echo "[*] HOT CACHE STALE: wiki files modified since last session ($(date -d @$hot_mtime '+%Y-%m-%d %H:%M' 2>/dev/null || date))" >&2
        return 1
    fi
    
    # No changes detected — skip rebuild
    echo "[✓] HOT CACHE FRESH: no wiki changes since $(date -d @$hot_mtime '+%Y-%m-%d %H:%M' 2>/dev/null || date)" >&2
    return 0
}

# ─── Main execution ──────────────────────────────────────────────────────────────

if [[ "$FORCE_REBUILD" == "true" ]]; then
    echo "[*] HOT CACHE FORCED: rebuilding regardless of timestamp" >&2
    exit 1
fi

check_hot_cache || {
    # Changes detected → signal rebuild needed (caller handles trigger)
    exit 1
}

# No changes — skip rebuild
exit 0
