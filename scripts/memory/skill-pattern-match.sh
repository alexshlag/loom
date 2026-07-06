#!/usr/bin/env bash
# skill-pattern-match.sh — Scan trajectories & distilled skills for reusable patterns
# Phase 20 refinement: actual pattern matching logic for auto-generation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

SKILLS_DIR="wiki/skills"
TRAJ_DIR="raw/trajectories"

# ─── Mode flags ─────────────────────────────────────────────────────────────
MODE="scan"  # scan | report | find-orphans | match-skills
MIN_PATTERN=2  # minimum overlap count to qualify as "reusable pattern"
OUTPUT_MODE="compact"  # compact | verbose

while [[ $# -gt 0 ]]; do
    case "$1" in
        --mode|-m) MODE="${2:-scan}"; shift 2;;
        --min|-M) MIN_PATTERN="${2:-2}"; shift 2;;
        --verbose|-v) OUTPUT_MODE="verbose"; shift;;
        --compact|-c) OUTPUT_MODE="compact"; shift;;
        *) shift;;
    esac
done

# ─── Data extraction helpers ────────────────────────────────────────────────

extract_skill_tags() {
    local file="$1"
    grep -oP 'tags:\s*\[(.*?)\]' "$file" 2>/dev/null | head -1 || echo "[]"
}

extract_tool_sequence() {
    # Reads packet.json from trajectory dir, extracts tool call names in order
    local traj_dir="$1"
    if [[ -f "$traj_dir/packet.json" ]]; then
        python3 -c "import json; d=json.load(open('$traj_dir/packet.json')); calls=[c.get('name',c.get('tool_name','?')) for c in d.get('tool_calls',[])]; print('|'.join(calls))" 2>/dev/null || echo ""
    fi
}

extract_procedure_ops() {
    # Extracts read/edit/write operations from Procedure section of skill file
    local file="$1"
    grep -A5 '## Procedure' "$file" 2>/dev/null | grep -oP '(read|edit|write):\s*\w+' || echo ""
}

# ─── Core matching logic ────────────────────────────────────────────────────

find_pattern_clusters() {
    # Scan all skills and trajectories, group by overlapping attributes
    local clusters=()
    
    # 1. Build tag frequency map from skills
    declare -A tag_freq
    for skill_file in "$SKILLS_DIR"/*.md; do
        [[ -f "$skill_file" ]] || continue
        local tags_line
        tags_line=$(grep 'tags:' "$skill_file" | head -1)  # first tags line only
        [[ -z "$tags_line" ]] && continue
        # Extract individual tags between brackets, skip empty/commas
        while IFS= read -r tag; do
            tag=$(echo "$tag" | tr -d ' ,[]')
            [[ -n "$tag" && "$tag" != "tags" ]] && tag_freq["$tag"]=$(( ${tag_freq["$tag"]:-0} + 1 ))
        done < <(echo "$tags_line" | sed 's/.*\[//;s/\].*//' | tr ',' '\n')
    done
    
    # 2. Find tags appearing in ≥MIN_PATTERN skills
    local common_tags=()
    for tag in "${!tag_freq[@]}"; do
        if [[ ${tag_freq["$tag"]} -ge $MIN_PATTERN ]]; then
            common_tags+=("$tag")
        fi
    done
    
    # 3. Find overlapping tool sequences across trajectories
    declare -A seq_freq
    local traj_dirs=()
    while IFS= read -r -d '' pkt; do
        local dir="${pkt%/*}"
        traj_dirs+=("$dir")
        
        local seq
        seq=$(extract_tool_sequence "$dir")
        [[ -n "$seq" ]] && seq_freq["$seq"]=$(( ${seq_freq["$seq"]:-0} + 1 ))
    done < <(find "$TRAJ_DIR" -name 'packet.json' -print0 2>/dev/null)
    
    # 4. Report findings
    if [[ "${#common_tags[@]}" -gt 0 ]]; then
        echo "[~] Common tags across ≥$MIN_PATTERN skills:" >&2
        for tag in "${common_tags[@]}"; do
            local count="${tag_freq[$tag]}"
            # List which files share this tag (just filenames)
            local file_count=0
            while IFS= read -r f; do
                [[ -f "$f" ]] && file_count=$((file_count + 1))
            done < <(grep -rl "tags:.*${tag}" "$SKILLS_DIR/" 2>/dev/null)
            
            if [[ $OUTPUT_MODE == "verbose" ]]; then
                echo "    → $tag (${count}x, in ${file_count} files)" >&2
            else
                echo "    → $tag (${count}x)" >&2
            fi
        done
    fi
    
    # 5. Report duplicate/overlapping tool sequences
    local common_seqs=()
    for seq in "${!seq_freq[@]}"; do
        if [[ ${seq_freq["$seq"]} -ge $MIN_PATTERN ]]; then
            common_seqs+=("$seq")
        fi
    done
    
    if [[ "${#common_seqs[@]}" -gt 0 ]]; then
        echo "[~] Repeated tool sequences (≥$MIN_PATTERN occurrences):" >&2
        for seq in "${common_seqs[@]}"; do
            local count="${seq_freq[$seq]}"
            # Find which trajectories use this sequence
            local trajs=()
            while IFS= read -r pkt; do
                [[ "$pkt" == *"$seq"* ]] && true  # crude match
            done < <(find "$TRAJ_DIR" -name 'packet.json' 2>/dev/null)
            
            echo "    → $seq ($countx)" >&2
        done
    fi
    
    if [[ "${#common_tags[@]}" -eq 0 && "${#common_seqs[@]}" -eq 0 ]]; then
        echo "[✓] No reusable patterns found (no ≥$MIN_PATTERN overlaps)" >&2
    fi
    
    # 6. Identify orphan trajectories (not distilled, but share pattern with skills)
    if [[ "$MODE" == "scan" || "$OUTPUT_MODE" == "verbose" ]]; then
        local undistilled_count=0
        while IFS= read -r pkt; do
            local dir="${pkt%/*}"
            traj_id=$(python3 -c "import json,sys;d=json.load(open(sys.argv[1]));print(d.get('id',''))" "$pkt" 2>/dev/null || true)
            
            # Check if referenced in any skill/case
            local referenced=false
            grep -rq "$traj_id" "$SKILLS_DIR/" 2>/dev/null && referenced=true
            
            if [[ "$referenced" == false ]]; then
                undistilled_count=$((undistilled_count + 1))
                
                # Check if it shares tags/sequence with existing skills
                local seq
                seq=$(extract_tool_sequence "$dir")
                
                # Compare against each skill's procedure ops
                for skill_file in "$SKILLS_DIR"/*.md; do
                    [[ -f "$skill_file" ]] || continue
                    
                    local proc_ops
                    proc_ops=$(extract_procedure_ops "$skill_file")
                    
                    # Simple overlap check: any tool name matching procedure op?
                    if echo "$seq" | grep -q "$(echo $proc_ops | cut -d: -f1 2>/dev/null)"; then
                        local skill_name="${skill_file##*/}"
                        echo "[!] Orphan trajectory ($traj_id) shares pattern with skill: $skill_name" >&2
                    fi
                done
            fi
        done < <(find "$TRAJ_DIR" -name 'packet.json' 2>/dev/null)
        
        if [[ $undistilled_count -gt 0 ]]; then
            echo "[$undistilled_count] Undistilled trajectories remain (not yet processed)" >&2
        fi
    fi
    
    return 0
}

# ─── Main ───────────────────────────────────────────────────────────────────

mkdir -p "$SKILLS_DIR" 2>/dev/null || true

case "$MODE" in
    scan)       find_pattern_clusters ;;
    report)     echo "=== Skill Pattern Analysis ===" >&2; find_pattern_clusters ;;
    find-orphans) 
        echo "[~] Scanning for undistilled trajectories..." >&2
        while IFS= read -r pkt; do
            [[ ! -f "$pkt" ]] && continue
            local dir="${pkt%/*}"
            traj_id=$(python3 -c "import json,sys;d=json.load(open(sys.argv[1]));print(d.get('id',''))" "$pkt" 2>/dev/null || true)
            referenced=false
            grep -r "$traj_id" "$SKILLS_DIR/" "$PROJECT_ROOT/wiki/cases/" 2>/dev/null && referenced=true
            [[ "$referenced" == false ]] && echo "  $dir ($traj_id) → undistilled" >&2
        done < <(find "$TRAJ_DIR" -name 'packet.json' 2>/dev/null)
        ;;
    match-skills) find_pattern_clusters ;;
    *) echo "[!] Unknown mode: $MODE"; exit 1 ;;
esac
