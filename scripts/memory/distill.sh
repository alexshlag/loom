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
        --check-dup|-C) ACTION="check-dup"; DUP_NAME="${2:-}"; shift 2;;
        *) POSITIONAL_ARGS+=("$1"); shift;;
    esac
done

do_pattern_scan() {
    # Run skill-pattern-match.sh to find reusable patterns before distilling
    if [[ -x "scripts/memory/skill-pattern-match.sh" ]]; then
        local scan_output
        scan_output=$(bash "$SCRIPT_DIR/../memory/skill-pattern-match.sh" --mode report 2>&1 || true)
        echo "[~] Pattern scan results:" >&2
        echo "$scan_output" | grep -E '\[\~\]|\!|→' >&2 || true
    fi
}

distill_trajectory() {
    # Helper: distill a single trajectory, skip if already done
    local traj_path="$1"
    [[ ! -f "$traj_path/packet.json" ]] && return 0

    local traj_id
    traj_id=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get('id',''))" "$traj_path/packet.json" 2>/dev/null || echo "")

    # Check if already distilled (referenced in skills/cases)
    local referenced
    referenced=$(grep -r "$traj_id" "$SKILLS_DIR/" "$CASES_DIR/" 2>/dev/null | head -1 || true)

    [[ -n "$referenced" ]] && return 0

    export TRAJECTORY_PATH="$traj_path"
    do_distill 2>/dev/null || true
}

do_distill_auto() {
    # Phase 20 S5: Run pattern scan before distilling to prioritize clustered trajectories
    echo "[~] Phase 20 — Pattern scan before auto-distillation" >&2
    do_pattern_scan

    local count=0
    while IFS= read -r pkt; do
        dir=$(dirname "$pkt")
        traj_id=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1])).get('id',''))" "$pkt" 2>/dev/null || echo "")

        # Check if already distilled (referenced in skills/cases)
        referenced=$(grep -r "$traj_id" "$SKILLS_DIR/" "$CASES_DIR/" 2>/dev/null | head -1 || true)

        if [[ -z "$referenced" ]]; then
            count=$((count + 1))
            echo "[~] Distilling trajectory: $dir (id=$traj_id)" >&2
            export TRAJECTORY_PATH="$dir"
            do_distill 2>/dev/null || true
        fi
    done < <(find "$TRAJ_DIR" -name 'packet.json' -type f 2>/dev/null)

    [[ $count -eq 0 ]] && echo "[✓] All trajectories already distilled (auto mode, no new skills)" >&2
}

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
    local slug="$1"
    [[ ! -d "$SKILLS_DIR" ]] && return 1

    # Check by frontmatter tags — pattern: [skill, skill-{slug}] (D3: updated for -skill.md naming)
    local matches
    matches=$(grep -rl "tags:.*skill.*${slug}" "$SKILLS_DIR/" 2>/dev/null || true)

    if [[ -z "$matches" ]]; then
        # Fallback: check index.md or direct file existence for {slug}-skill pattern
        matches=$(grep "wiki/skills/${slug}-skill" "wiki/index.md" 2>/dev/null || true)
        [[ -z "$matches" ]] && [ -f "${SKILLS_DIR}/${slug}-skill_*.md" ] && matches="${SKILLS_DIR}/${slug}-skill_*.md"
    fi
    
    if [[ -n "$matches" ]]; then echo "$matches"; return 0; fi
    
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
    
    # Generate skill/case via Python — direct write to final path (no temp files)
    local output_dir=""
    if [[ "$DISTILL_TYPE" == "skill" ]]; then
        output_dir="${SKILLS_DIR}"
    else
        output_dir="${CASES_DIR}"
    fi
    
    export _TRAJ_JSON="$TRAJECTORY_PATH/packet.json"
    export _EXTRACTED_MD="$TRAJECTORY_PATH/extracted.md"
    export _OUTPUT_DIR="$output_dir"
    
    # Python generates the file AND echoes back the final path for bash to use
    local generated_file
    generated_file=$(python3 <<'PYEOF'
import json, datetime, os, re

pkg = json.load(open(os.environ['_TRAJ_JSON']))
outd = os.environ['_OUTPUT_DIR']
tid = pkg.get('id', 'unknown')
ts = pkg.get('timestamp', 'unknown')
outcome = pkg.get('outcome', '?')
complexity = pkg.get('complexity', '?')
prompt_text = pkg.get('prompt', '')[:200] if pkg.get('prompt') else ''
tool_calls = pkg.get('tool_calls', [])

try:
    with open(os.environ['_EXTRACTED_MD']) as f: summary = f.read()
except: summary = ""

# Determine type and generate human-readable name from prompt
if len(tool_calls) > 1:
    type_label = 'skill'
else:
    type_label = 'case'

# Generate slug from prompt (clean words, lowercase, hyphenated)
slug = ''
if prompt_text and len(prompt_text.strip()) > 0:
    clean_name = re.sub(r'[^a-z0-9\s]', '', prompt_text.lower()).strip()
    words = [w for w in clean_name.split() if len(w) > 2][:5]
    slug = '-'.join(words)
else:
    parts = tid.split('-')
    slug = f"traj-{parts[1]}" if len(parts) >= 3 else 'unknown'

# Ensure uniqueness with date suffix
if type_label == 'skill':
    # Naming convention: {slug}-skill_{tid[:8]}.md per rules/skill_format.json#naming_convention
    final_path = os.path.join(outd, f"{slug}-skill_{tid[:8]}.md")
else:
    final_path = os.path.join(outd, f"{slug}_{tid[:8]}-case.md")

# Check for duplicate by file existence — append counter if needed
if os.path.exists(final_path):
    counter = 1
    while True:
        if type_label == 'skill':
            final_path = os.path.join(outd, f"{slug}-skill_{tid[:8]}-{counter}.md")
        else:
            final_path = os.path.join(outd, f"{slug}_{tid[:8]}-case-{counter}.md")
        if not os.path.exists(final_path): break
        counter += 1

os.makedirs(os.path.dirname(final_path), exist_ok=True)

# Generate frontmatter + content (direct write to final path)
lines = ["---"]
tags_comma = ', '.join([f'{type_label}-' + w for w in slug.split('-')])
lines.append(f'tags: [{type_label}, {tags_comma}]')
lines.append(f'date: "{datetime.date.today().isoformat()}"')
lines.append("type: documentation")
if type_label == 'skill':
    lines.append("category: note")
else:
    lines.append("category: case")
lines.append('aliases: []')
lines.append(f'sources: ["raw/trajectories/{tid}"]')
lines.append("related: []")
lines.append("---")
lines.append("")

if type_label == 'skill':
    lines.append(f"# Skill: {slug.replace('-', ' ').title()}")
    lines.append("")
    lines.append("## Procedure")
    lines.append("")
    for call in tool_calls:
        nm = call.get('name', call.get('tool_name', '?'))
        st = 'ERROR' if call.get('is_error') else 'OK'
        lines.append(f"- {nm}: {st}")
    lines.extend(["", "## Context", "", f'- Trigger: Original task that led to this pattern',
                  f"- Outcome: {outcome}", f"- Complexity: {complexity}", "",
                  "## Notes", "", f'- Distilled from trajectory "{tid}".',
                  f'- Timestamp: {ts}'])
else:
    lines.append(f"# Case: {slug.replace('-', ' ').title()}")
    lines.append("")
    lines.append("## Problem")
    lines.append("")
    if prompt_text:
        lines.append(f"**Original task**: {prompt_text}")
    lines.append("")
    lines.append("## Steps Taken")
    lines.append("")
    for call in tool_calls:
        nm = call.get('name', call.get('tool_name', '?'))
        st = 'ERROR' if call.get('is_error') else 'OK'
        lines.append(f"- {nm}: {st}")
    lines.extend(["", "## Outcome", "", f"**Result**: {outcome}",
                  f"**Complexity**: {complexity}", "", "## Lessons Learned", ""])

with open(final_path, 'w') as f:
    f.write('\n'.join(lines) + '\n')

print(final_path)
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
    
    # Final output
    local skill_type="SKILL"
    [[ "$DISTILL_TYPE" != "skill" ]] && skill_type="CASE"
    echo "[✓] ${skill_type} created: $(basename "$generated_file" .md) → $generated_file" >&2
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

# ─── Auto mode: find undistilled trajectories and distill them all ──────

if [[ "$AUTO_MODE" == true ]]; then
    ACTION="distill-auto"
fi

# ─── Dispatch ──────────────────────────────────────────────────────

case "$ACTION" in
    distill)           do_distill ;;
    check-undistilled) do_check_undistilled ;;
    check-dup)         do_check_dup ;;
    distill-auto)         do_distill_auto ;;
    *)                 echo "[!] Unknown action: $ACTION"; exit 1 ;;
esac
