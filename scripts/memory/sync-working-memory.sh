#!/usr/bin/env bash
# sync-working-memory.sh — Atomic update of working_memory.json after task completion
# Usage: ./sync-working-memory.sh [--focus-node "text"] [--task-status "completed|failed"] [--next-steps "step1, step2"] [--quiet]
# Returns: exit 0 on success, 1 if file corrupted or write failed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
WM_FILE="$PROJECT_ROOT/working_memory.json"

FOCUS_NODE=""
TASK_STATUS="completed"
NEXT_STEPS=""
QUIET=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --focus-node) FOCUS_NODE="$2"; shift 2;;
        --task-status) TASK_STATUS="$2"; shift 2;;
        --next-steps) NEXT_STEPS="$2"; shift 2;;
        --quiet) QUIET=true; shift;;
        *) echo "[!] Unknown flag: $1" >&2; exit 1;;
    esac
done

# Pass args as environment variables to Python
export FOCUS_NODE TASK_STATUS NEXT_STEPS WM_FILE QUIET
python3 "$SCRIPT_DIR/_sync_wm_impl.py"

exit 0
