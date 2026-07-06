#!/usr/bin/env bash
# recall.sh — PRF-enhanced two-stage recall engine
# 
# Usage: ./recall.sh "<query>" [--top N] [--stage=links|content] [--max-candidates M] [--prf=auto|off]
#
# Phase 16.1 Task #3: PRF-enhanced two-stage recall (PRF extraction via prf_extract.py)

set -euo pipefail
export LC_NUMERIC=C

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"
WIKI_DIR="wiki"
MAX_RESULTS=5
BOOST_FACTOR=1.5
PRF_MODE="auto"

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
        --prf) PRF_MODE="${2:-auto}"; shift 2;;
        --prf=*) PRF_MODE="${1#*=}"; shift;;
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
    local prf_terms_file=$(mktemp)
    
    trap "rm -f '$tmp_paths' '$prf_terms_file'" EXIT 2>/dev/null || true
    
    # wiki-search.sh returns lines like: path/to/page.md:matched_line
    local search_output=""
    search_output=$("$PROJECT_ROOT/scripts/wiki-search.sh" "$QUERY" --max "$MAX_CANDIDATES" 2>/dev/null || true)
    
    if [[ -n "$search_output" ]]; then
        # Extract unique paths from wiki-search output (format: path:line)
        echo "$search_output" | awk -F: '{print $1}' | sort -u | head -n "$MAX_CANDIDATES" > "$tmp_paths"
    fi
    
    if [[ ! -s "$tmp_paths" ]]; then
        echo '[]'
        return 0
    fi
    
    # ── PRF extraction phase ──────────────────────────────────────────────
    local candidate_count
    candidate_count=$(wc -l < "$tmp_paths" | tr -d ' ')
    if [[ "$PRF_MODE" != "off" && "$candidate_count" -ge 3 ]]; then
        local top3_full
        top3_full=$(head -3 "$tmp_paths" | sed "s|^|$WIKI_DIR/|" | paste -sd ',')
        "$SCRIPT_DIR/prf_extract.py" \
            --wiki-dir "$PROJECT_ROOT/wiki" \
            --candidates "$top3_full" \
            --stopwords "$SCRIPT_DIR/stopwords.txt" \
            > "$prf_terms_file" 2>/dev/null || true
    fi
    
    # ── Scoring + boost phase ─────────────────────────────────────────────
    local rank=0
    echo "["
    while IFS= read -r path; do
        rank=$((rank + 1))
        local score=1.0
        
        # Apply PRF boost if terms available
        if [[ -s "$prf_terms_file" ]]; then
            local page_head
            page_head=$(head -20 "$WIKI_DIR/$path" 2>/dev/null || true)
            if [[ -n "$page_head" ]]; then
                while IFS=: read -r term _; do
                    [[ -z "$term" ]] && continue
                    if echo "$page_head" | grep -iq "\b${term}\b" 2>/dev/null; then
                        score=$(python3 -c "print(round($score + $BOOST_FACTOR, 2))" 2>/dev/null || echo "$score")
                    fi
                done < "$prf_terms_file"
            fi
        fi
        
        [[ $rank -gt 1 ]] && echo ","
        printf '  {"path": "%s", "score": %.2f, "rank": %d}' "$path" "$score" "$rank"
    done < "$tmp_paths"
    echo ""
    echo "]"
}

# ─── Stage 2: Content Expansion (Optional) ──────────────────────────────────────

stage_2_expand() {
    local tmp_json=$(mktemp)
    trap "rm -f '$tmp_json'" EXIT 2>/dev/null || true
    cat > "$tmp_json"
    python3 -c '
import json, sys, os
with open(sys.argv[1]) as f:
    data = json.load(f)
wiki_dir = os.environ.get("WIKI_DIR", "wiki")
for entry in data:
    path = entry.get("path", "")
    score = entry.get("score", 0)
    full_path = os.path.join(wiki_dir, path) if not path.startswith(wiki_dir) else path
    if not os.path.isfile(full_path):
        continue
    print(f"## [score={score}] {path}")
    with open(full_path, "r", errors="replace") as fh:
        in_fm = False
        for i, line in enumerate(fh):
            if i == 0 and line.strip() == "---":
                in_fm = True
                continue
            if in_fm:
                if line.strip() == "---":
                    in_fm = False
                continue
            if i >= 60:
                break
            print(line, end="")
    print("---")
' "$tmp_json" 2>/dev/null || true
}

# ─── Main Execution ──────────────────────────────────────────────────────────────

echo "[*] Recall: searching for \"$QUERY\"" >&2

if [[ "$STAGE" == "links" ]]; then
    stage_1_rank
elif [[ "$STAGE" == "content" ]]; then
    ranked_paths=$(stage_1_rank) || true
    
    if [[ -z "$ranked_paths" ]]; then exit 0; fi
    
    echo "$ranked_paths" | stage_2_expand | head -n $((TOP_K * 60))
else
    echo "[!] Unknown stage: $STAGE. Use 'links' or 'content'" >&2
    exit 1
fi
