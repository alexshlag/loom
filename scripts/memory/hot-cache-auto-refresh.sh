#!/usr/bin/env bash
# hot-cache-auto-refresh.sh — Auto-regenerates wiki/hot.md content from log + working_memory
# Usage: ./hot-cache-auto-refresh.sh [--quiet]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

HOT_FILE="wiki/hot.md"
LOG_FILE="wiki/log.md"
WM_FILE="working_memory.json"
QUIET=false
[[ $# -gt 0 && "$1" == "--quiet" ]] && QUIET=true

# ─── Generate new hot.md content ──────────────────────────────

generate_hot_content() {
    local timestamp=$(date '+%Y-%m-%d')
    
    cat << EOF
---
tags: [cache, system]
date: $timestamp
category: note
sources: []
related: []
---
# Wiki Hot Cache — Last Updated: $timestamp

## Active Project (WORK_MODE: $(python3 -c "import json; print(json.load(open('$WM_FILE')).get('current_mode', 'discussion'))" 2>/dev/null || echo "discussion"))
- **Project**: Loomana wiki architecture optimization + knowledge management
- **Status**: 🟢 ACTIVE SESSION — Wiki maintenance and expansion

## Active Session Context
$(python3 -c "
import json, sys

try:
    wm = json.load(open('$WM_FILE'))
    focus = wm.get('focus_node', 'General wiki maintenance')
    
    # Extract recent key findings or next_steps
    ns_todo = wm.get('next_steps_todo', [])
    if ns_todo:
        todo_items = '\n'.join([f'- **{t}**' for t in ns_todo[:5]])
    else:
        todo_items = '  No pending tasks'
    
    print(f'- **Focus node**: {focus}')
    print(f'\n### Pending Tasks')
    print(todo_items)
except Exception as e:
    print('  WM read failed — using defaults')
    sys.exit(0)
" 2>/dev/null || echo "  Session context unavailable")

## Recent Changes
$(tail -15 "$LOG_FILE" 2>/dev/null | grep "^#" | sed 's/^## \[/' | sed 's/.*\] //' | head -8 | while IFS= read -r line; do
    if [[ -n "$line" ]]; then
        echo "- **${line:0:10}**: ${line}"
    fi
done || echo "  No recent log entries")

## System State
### Active Threads
- Wiki maintenance and expansion (auto-fixes running on lint errors)
- Knowledge base growth via query responses and source ingestion

$(tail -20 "$LOG_FILE" 2>/dev/null | grep "^#" | sed 's/.*\] //' | head -6 | while IFS= read -r line; do
    if [[ -n "$line" && ! "$line" =~ "completed" ]]; then
        echo "- **Recent activity**: $line"
    fi
done || true)

EOF
}

# Generate new content
NEW_CONTENT=$(generate_hot_content 2>/dev/null) || {
    echo "[!] hot-cache-auto-refresh: failed to generate content" >&2
    exit 1
}

# Write to file atomically (first write to temp, then rename)
TEMP_FILE=$(mktemp "${HOT_FILE}.XXXXXX")
echo "$NEW_CONTENT" > "$TEMP_FILE"
mv "$TEMP_FILE" "$HOT_FILE"

$QUIET || echo "[✓] hot-cache-auto-refresh: wiki/hot.md regenerated from log + working_memory.json" >&2
exit 0
