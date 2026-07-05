#!/usr/bin/env bash
# recall.sh — PRF-enhanced two-stage recall engine
# 
# Usage: ./recall.sh "<query>" [--top N] [--stage=links|content] [--max-candidates M]
#
# Phase 16.1 Task #3: Replace wiki-search.sh calls with semantic-aware recall

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"
WIKI_DIR="wiki"
MAX_RESULTS=5
PRF_THRESHOLD=1.5

# ─── Parse arguments ──────────────────────────────────────────────────────────
QUERY=""
TOP_K=$MAX_RESULTS
STAGE="links"  # links | content — default: Stage 1 only (ranking)
MAX_CANDIDATES=10

POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --top|-t) TOP_K="${2:-$TOP_RESULTS}"; shift 2;;
        --stage) STAGE="${2:-links}"; shift 2;;
        --max-candidates|-m) MAX_CANDIDATES="${2:-$MAX_CANDIDATES}"; shift 2;;
        *) POSITIONAL_ARGS+=("$1"); shift;;
    esac
done

if [[ ${#POSITIONAL_ARGS[@]} -gt 0 ]]; then
    QUERY="${POSITIONAL_ARGS[0]}"
fi

if [[ -z "$QUERY" ]]; then
    echo "[!] Usage: $0 \"query\" [--top N] [--stage=links|content]" >&2
    exit 1
fi

# ─── Stage 1: Links-First Ranking ─────────────────────────────────────────────

stage_1_rank() {
    local tmp_paths=$(mktemp)
    
    trap "rm -f '$tmp_paths'" EXIT 2>/dev/null || true
    
    # wiki-search.sh returns lines like: path/to/page.md:matched_line
    local search_output=""
    search_output=$("$PROJECT_ROOT/scripts/wiki-search.sh" "$QUERY" --max "$MAX_CANDIDATES" 2>/dev/null || true)
    
    if [[ -n "$search_output" ]]; then
        # Extract paths from wiki-search output (format: path:line)
        echo "$search_output" | awk -F: '{print $1}' | sort -u | head -n "$MAX_CANDIDATES" > "$tmp_paths"
    fi
    
    if [[ ! -s "$tmp_paths" ]]; then return 0; fi
    
    cat "$tmp_paths"
}

# ─── Stage 2: Content Expansion (Optional) ──────────────────────────────────────

stage_2_expand() {
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        
        # Parse path from wiki-search format: "path/to/page.md:matched_line"
        local path="${line%%:*}"
        
        [[ ! -f "$path" ]] && continue
        
        echo "## $path"
        
        # Extract frontmatter + H1/H2 headers + first 40 lines of content
        awk 'BEGIN{in_fm=0} /^---$/{if(in_fm){print;in_fm=0}else{in_fm=1;next}} in_fm{print;next} /^#/{header++;print;next}{print}' "$path" | head -n 60
        
        echo "---"
    done
}

# ─── Main Execution ──────────────────────────────────────────────────────────────

echo "[*] Recall: searching for \"$QUERY\"" >&2

if [[ "$STAGE" == "links" ]]; then
    stage_1_rank
elif [[ "$STAGE" == "content" ]]; then
    ranked_paths=$(stage_1_rank) || true
    
    if [[ -z "$ranked_paths" ]]; then exit 0; fi
    
    # TODO: PRF extraction from top-3 candidates for semantic boosting (Phase 1b)
    
    echo "$ranked_paths" | stage_2_expand | head -n $((TOP_K * 60))
else
    echo "[!] Unknown stage: $STAGE. Use 'links' or 'content'" >&2
    exit 1
fi
