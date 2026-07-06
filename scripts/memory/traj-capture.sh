#!/usr/bin/env bash
# traj-capture.sh — Record agent sessions as trajectories → distillable artifacts
# Phase 16.1 Task #6: Trajectory capture system
#
# Usage: ./traj-capture.sh [--prompt "query"] [--steps "tool_calls_json"] [--outcome success|partial|failure] [--complexity low|medium|high]
#        ./traj-capture.sh --check-complexity --min medium
#        ./traj-capture.sh --list [raw/trajectories/]
#
# Output: raw/trajectories/TRJ-{timestamp}-{id}/ with packet.json + extracted.md

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

TRAJ_DIR="raw/trajectories"
mkdir -p "$TRAJ_DIR"

# ─── Parse arguments ────────────────────────────────────────────────────────
PROMPT=""
STEPS_JSON=""
OUTCOME="success"  # success | partial | failure
COMPLEXITY="low"   # low | medium | high
ACTION="capture"   # capture | check-complexity | list

POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --prompt|-p) PROMPT="${2:-}"; shift 2;;
        --steps|-s) STEPS_JSON="${2:-}"; shift 2;;
        --outcome|-o) OUTCOME="${2:-success}"; shift 2;;
        --complexity|-c) COMPLEXITY="${2:-low}"; shift 2;;
        --check-complexity) ACTION="check-complexity"; shift;;
        --min) MIN_COMPLEXITY="${2:-medium}"; shift 2;;
        --list|-l) ACTION="list"; shift;;
        *) POSITIONAL_ARGS+=("$1"); shift;;
    esac
done

if [[ ${#POSITIONAL_ARGS[@]} -gt 0 ]]; then
    PROMPT="${POSITIONAL_ARGS[0]}"
fi

# ─── Helpers ────────────────────────────────────────────────────────────────

generate_id() {
    # Generate unique trajectory ID: TRJ-{timestamp}-{random}
    local ts=$(date +%Y%m%d-%H%M)
    local rand=$(head -c 4 /dev/urandom | od -A n -t x1 | head -n1 | tr -d ' ')
    echo "TRJ-${ts}-${rand}"
}

extract_summary() {
    # Extract human-readable summary from tool_calls JSON
    local json="$1"
    if [[ -z "$json" ]]; then
        echo "No step details provided."
        return
    fi
    
    local steps_count=$(echo "$json" | grep -o '"name"' | wc -l || true)
    local errors=$(echo "$json" | grep -o '"is_error":true' | wc -l || true)
    
    cat <<EOF
- **Steps executed**: ${steps_count:-0}
- **Errors encountered**: ${errors:-0}
- **Outcome**: ${OUTCOME}
- **Complexity**: ${COMPLEXITY}

$(echo "$json" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for step in data if isinstance(data, list) else []:
        name = step.get('name', step.get('tool_name', 'unknown'))
        is_err = step.get('is_error', False)
        status = 'ERROR' if is_err else 'OK'
        print(f'- {name}: {status}')
except: pass
" 2>/dev/null || echo "JSON parsing failed — raw data preserved in packet.json")
EOF
}

# ─── Main actions ───────────────────────────────────────────────────────────

do_capture() {
    local traj_id=$(generate_id)
    local traj_path="$TRAJ_DIR/$traj_id"
    mkdir -p "$traj_path"
    
    local ts=$(date +%Y-%m-%dT%H:%M:%S%z)
    
    # Build packet.json
    cat > "$traj_path/packet.json" <<EOF
{
  "id": "${traj_id}",
  "timestamp": "${ts}",
  "prompt": $(echo "$PROMPT" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().strip()))"),
  "tool_calls": $(echo "$STEPS_JSON" | python3 -c "import sys,json; d=sys.stdin.read(); print(json.dumps(json.loads(d)) if d.strip() else '[]')" 2>/dev/null || echo '[]'),
  "outcome": "${OUTCOME}",
  "complexity": "${COMPLEXITY}",
  "agent_version": "$(git -C "$PROJECT_ROOT" rev-parse --short HEAD 2>/dev/null || echo 'unknown')"
}
EOF
    
    # Generate extracted.md summary
    extract_summary "$STEPS_JSON" > "$traj_path/extracted.md"
    
    echo "[✓] TRAJECTORY captured: $traj_id → $traj_path/"
    echo "[$traj_id]" >> "$TRAJ_DIR/index.log" 2>/dev/null || true
    
    # Output trajectory path for caller to consume
    echo "$traj_path"
}

do_check_complexity() {
    local min="${MIN_COMPLEXITY:-medium}"
    
    # Map complexity strings to numeric thresholds
    case "$COMPLEXITY" in
        low)       COMPLEXITY_NUM=1 ;;
        medium)    COMPLEXITY_NUM=2 ;;
        high)      COMPLEXITY_NUM=3 ;;
        *)         COMPLEXITY_NUM=0 ;;
    esac
    
    case "$min" in
        low)       MIN_NUM=1 ;;
        medium)    MIN_NUM=2 ;;
        high)      MIN_NUM=3 ;;
        *)         MIN_NUM=2 ;;
    esac
    
    if [[ $COMPLEXITY_NUM -ge $MIN_NUM ]]; then
        echo "YES"  # Should be captured
        exit 0
    else
        echo "NO"   # Skip capture
        exit 1
    fi
}

do_list() {
    local count=$(find "$TRAJ_DIR" -name 'packet.json' -type f 2>/dev/null | wc -l)
    echo "[*] Trajectories: $count recorded in $TRAJ_DIR/"
    
    if [[ $count -gt 0 ]]; then
        echo ""
        echo "Recent trajectories:"
        ls -td "$TRAJ_DIR"/TRJ-* 2>/dev/null | head -10 | while read -r dir; do
            local id=$(basename "$dir")
            local outcome="unknown"
            if [[ -f "$dir/packet.json" ]]; then
                outcome=$(python3 -c "import json; print(json.load(open('$dir/packet.json')).get('outcome','?'))" 2>/dev/null || echo "?")
            fi
            echo "  $id → outcome: $outcome"
        done
    fi
}

# ─── Dispatch ────────────────────────────────────────────────────────────────

case "$ACTION" in
    capture)      do_capture ;;
    check-complexity) do_check_complexity ;;
    list)         do_list ;;
    *)            echo "[!] Unknown action: $ACTION"; exit 1 ;;
esac
