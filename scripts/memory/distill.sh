#!/usr/bin/env bash
# distill.sh — Convert trajectories into reusable wiki skills/cases
# Phase 16.1 Task #7: Distillation pipeline

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

SKILLS_DIR="wiki/skills"
CASES_DIR="wiki/cases"
TRAJ_DIR="raw/trajectories"

mkdir -p "$SKILLS_DIR" "$CASES_DIR" 2>/dev/null || true

# ─── Parse arguments ────────────────────────────────────────────────────────
TRAJECTORY_PATH=""
DISTILL_TYPE="skill"
AUTO_MODE=false
ACTION="distill"
DUP_NAME=""

POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --trajectory|-t) TRAJECTORY_PATH="${2:-}"; shift 2;;
        --type|-T) DISTILL_TYPE="${2:-skill}"; shift 2;;
        --auto|-a) AUTO_MODE=true; shift;;
        --check-undistilled) ACTION="check-undistilled"; shift;;
        --check-dup|-C) DUP_NAME="${2:-}"; shift 2;;
        *) POSITIONAL_ARGS+=("$1"); shift;;
    esac
done

if [[ ${#POSITIONAL_ARGS[@]} -gt 0 ]]; then
    TRAJECTORY_PATH="${POSITIONAL_ARGS[0]}"
fi

# ─── Helpers ────────────────────────────────────────────────────────────────

check_procedure_coverage() {
    local traj_path="$1"
    if [[ ! -f "$traj_path/packet.json" ]]; then return 1; fi
    
    local step_count
    step_count=$(python3 -c "import json,sys;d=json.load(open(sys.argv[1]));print(len(d.get('tool_calls',[])))" "$traj_path/packet.json" 2>/dev/null || echo "0")
    
    [[ $step_count -ge 2 ]] && return 0
    return 1
}

check_duplicate_skill() {
    local skill_name="$1"
    [[ ! -d "$SKILLS_DIR" ]] && return 1
    
    local matches
    matches=$(grep -rl "## ${skill_name}" "$SKILLS_DIR/" 2>/dev/null || true)
    
    if [[ -n "$matches" ]]; then echo "$matches"; return 0; fi
    
    local index_matches
    index_matches=$(grep "${skill_name}" "wiki/index.md" 2>/dev/null || true)
    
    if [[ -n "$index_matches" ]]; then echo "$index_matches"; return 0; fi
    
    return 1
}

# ─── Main actions ───────────────────────────────────────────────────────────

do_distill() {
    if [[ -z "$TRAJECTORY_PATH" ]]; then
        echo "[!] No trajectory specified. Use --trajectory or list undistilled." >&2
        exit 1
    fi
    
    # Check procedure coverage (≥2 steps)
    if ! check_procedure_coverage "$TRAJECTORY_PATH"; then
        echo "[⊘] SKIPPED: Trajectory has <2 meaningful steps" >&2
        exit 0
    fi
    
    # Generate skill/case via Python, passing paths as env vars to avoid bash expansion in heredocs
    local output_path=""
    if [[ "$DISTILL_TYPE" == "skill" ]]; then
        output_path="${SKILLS_DIR}/distill_skill.md"
    else
        output_path="${CASES_DIR}/distill_case.md"
    fi
    
    export _TRAJ_JSON="$TRAJECTORY_PATH/packet.json"
    export _EXTRACTED_MD="$TRAJECTORY_PATH/extracted.md"
    export _OUTPUT_PATH="$output_path"
    export _SKILL_NAME="${DISTILL_TYPE}_$(basename "$TRAJECTORY_PATH")"
    
    # Python generates the file AND echoes back the clean title for bash to use
    local generated_file
    generated_file=$(python3 <<'PYEOF'
import json, datetime, os

pkg = json.load(open(os.environ['_TRAJ_JSON']))
sn = os.environ['_SKILL_NAME']
outp = os.environ['_OUTPUT_PATH']

try:
    with open(os.environ['_EXTRACTED_MD']) as f: summary = f.read()
except: summary = ""

tid = pkg.get('id', 'unknown')
ts = pkg.get('timestamp', 'unknown')
outcome = pkg.get('outcome', '?')
complexity = pkg.get('complexity', '?')
prompt_text = pkg.get('prompt', '')[:200] if pkg.get('prompt') else ''

# Parse trajectory name from ID for the page title
traj_id_short = tid.split('-')[2] if '-' in tid else 'traj'
title_parts = [traj_id_short] + [p for p in prompt_text.replace(' ', '-').replace('_', '-')[:30].lower() if p.isalnum()]
clean_title = ''.join(title_parts[:4])

if os.environ['_SKILL_NAME'].startswith('skill'):
    lines = ["---", f"tags: [skill, {sn}]"]
    lines.append(f'date: "{datetime.date.today().isoformat()}"')
    lines.append("type: documentation")
    lines.append("category: note")
    lines.append(f'sources: ["raw/trajectories/{tid}"]')
    lines.append("related: []")
    lines.append("---")
    lines.append("")
    lines.append(f"# Skill: {clean_title}")
    lines.append("")
    lines.append("## Procedure")
    lines.append("")
    for call in pkg.get('tool_calls', []):
        nm = call.get('name', call.get('tool_name', '?'))
        st = 'ERROR' if call.get('is_error') else 'OK'
        lines.append(f"- {nm}: {st}")
    if summary:
        for line in summary.split('\n'):
            if line.startswith('- '):
                lines.append(line)
    lines.extend(["", "## Context", "", f'- Trigger: Original task that led to this pattern',
                  f"- Outcome: {outcome}", f"- Complexity: {complexity}", "",
                  "## Notes", "", f'- Distilled from trajectory "{tid}".',
                  f'- Timestamp: {ts}'])
    if prompt_text:
        lines.append(f'- Original task: {prompt_text}')

else:
    lines = ["---", f"tags: [case, {sn}]"]
    lines.append(f'date: "{datetime.date.today().isoformat()}"')
    lines.append("type: documentation")
    lines.append("category: note")
    lines.append(f'sources: ["raw/trajectories/{tid}"]')
    lines.append("related: []")
    lines.append("---")
    lines.append("")
    lines.append(f"# Case: {clean_title}")
    lines.append("")
    lines.append("## Problem")
    lines.append("")
    if prompt_text:
        lines.append(f"**Original task**: {prompt_text}")
    lines.append("")
    lines.append("## Steps Taken")
    lines.append("")
    for call in pkg.get('tool_calls', []):
        nm = call.get('name', call.get('tool_name', '?'))
        st = 'ERROR' if call.get('is_error') else 'OK'
        lines.append(f"- {nm}: {st}")
    lines.extend(["", "## Outcome", "", f"**Result**: {outcome}",
                  f"**Complexity**: {complexity}", "", "## Lessons Learned", ""])
    if summary:
        for line in summary.split('\n'):
            if line.startswith('- '):
                lines.append(line)

os.makedirs(os.path.dirname(outp), exist_ok=True)
with open(outp, 'w') as f:
    f.write('\n'.join(lines) + '\n')

print(f"{outp}_{clean_title}.md")
PYEOF
)
    
    # Add to wiki/index.md if it exists
    if [[ -f "wiki/index.md" ]]; then
        local already_indexed=false
        grep -q "$generated_file" "wiki/index.md" 2>/dev/null && already_indexed=true
        if [[ "$already_indexed" == false ]]; then
            echo "- [[$generated_file]] → $(basename "$generated_file" .md)" >> "wiki/index.md"
        fi
    fi
    
    # Rename temp file to final name (Python creates distill_skill/case.md, we rename)
    if [[ -f "${SKILLS_DIR}/distill_skill.md" ]]; then
        mv "${SKILLS_DIR}/distill_skill.md" "$generated_file" 2>/dev/null || true
    elif [[ -f "${CASES_DIR}/distill_case.md" ]]; then
        mv "${CASES_DIR}/distill_case.md" "$generated_file" 2>/dev/null || true
    fi
    
    echo "[✓] ${DISTILL_TYPE^^} created: $(basename "$generated_file" .md) → $generated_file" >&2
    echo "$generated_file"
}

do_check_undistilled() {
    local count
    count=$(find "$TRAJ_DIR" -name 'packet.json' -type f 2>/dev/null | wc -l)
    
    if [[ $count -eq 0 ]]; then
        echo "[✓] No trajectories to distill (all clean)" >&2
        exit 0
    fi
    
    local undistilled=0
    while IFS= read -r pkt; do
        local dir
        dir=$(dirname "$pkt")
        
        traj_id=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get('id',''))" "$pkt" 2>/dev/null || echo "")
        
        referenced=$(grep -r "$traj_id" "$SKILLS_DIR/" "$CASES_DIR/" 2>/dev/null | head -1 || true)
        
        if [[ -z "$referenced" ]]; then
            undistilled=$((undistilled + 1))
            echo "  $dir → not yet distilled" >&2
        fi
    done < <(find "$TRAJ_DIR" -name 'packet.json' -type f 2>/dev/null)
    
    if [[ $undistilled -eq 0 ]]; then
        echo "[✓] All trajectories distilled (0 pending)" >&2
    else
        echo "[$undistilled] Undistilled trajectories remain" >&2
    fi
    
    exit 0
}

do_check_dup() {
    local name="$DUP_NAME"
    
    if check_duplicate_skill "$name"; then
        echo "DUPLICATE FOUND: $(check_duplicate_skill "$name")" >&2
        exit 1
    else
        echo "CLEAN: no duplicate for '$name'" >&2
        exit 0
    fi
}

# ─── Dispatch ────────────────────────────────────────────────────────────────

case "$ACTION" in
    distill)           do_distill ;;
    check-undistilled) do_check_undistilled ;;
    check-dup)         do_check_dup ;;
    *)                 echo "[!] Unknown action: $ACTION"; exit 1 ;;
esac
