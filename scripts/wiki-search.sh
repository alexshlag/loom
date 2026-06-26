#!/usr/bin/env bash
# wiki-search.sh — Умный поиск по категориям wiki с приоритетом релевантности
# 
# Usage: ./wiki-search.sh "query" [wiki_dir] [--max N] [--dynamic]
#
# Логика (Phase 2 + Phase 5 + Phase 6):
#   1. Static mode: priority-categories из DEFAULT_PRIORITY (syntheses → concepts → entities)
#   2. Dynamic mode (--dynamic): query intent analysis → entity/concept/comparison keywords → dynamic order categories
#   3. Context awareness (auto, no flag): read search_history.json → bias priority based on recent queries
#   4. Relevance scoring: position weight (H1 = x3), frequency count, backlink weight + category bonus
#   5. Output: sorted by combined score (descending) — релевантные страницы выше
#   6. Auto-save search to meta/search_history.json after execution
# 
# Output: строки формата "relative/path/to/file.md:matched_line"
#         с относительными путями от wiki_dir для чистоты вывода.
#
# Exit codes:
#   0 = results found, 1 = no results (error to stderr)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"
WIKI_DIR="wiki"
MAX_RESULTS=15
QUERY=""
DYNAMIC=false
RESULTS_COUNT=0

# Fix #2: Escape query for safe grep usage (prevent regex meta-char bugs)
escape_for_grep() {
    printf '%s' "$1" | sed 's/[\\[\\.\\^\\$*+?{()|\\]/\\\\&g'
}

# Phase 5: Parse flags first, collect positional args for query
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --max|-m) MAX_RESULTS="${2:-$MAX_RESULTS}"; shift 2;;
        --dynamic|-d) DYNAMIC=true; shift;;
        *) POSITIONAL_ARGS+=("$1"); shift;;
    esac
done

# Fix #5: Check array length before accessing to avoid crash on bash < 4.4 with set -u
if [[ ${#POSITIONAL_ARGS[@]} -eq 0 ]]; then
    echo "[!] Usage: $0 \"query\" [wiki_dir] [--max N] [--dynamic]" >&2
    exit 1
fi

if [[ -z "${POSITIONAL_ARGS[0]:-}" ]]; then
    echo "[!] First argument is empty" >&2
    exit 1
fi
QUERY="${POSITIONAL_ARGS[0]}"

if [[ -z "$QUERY" ]]; then
    echo "[!] Query is empty" >&2
    exit 1
fi

# ─── Default priority categories ──────────────────────
DEFAULT_PRIORITY=("syntheses" "concepts" "entities" "comparisons" "notes" "meetings" "projects" "bibliography" "resources")

# ─── Phase 6: Search Context Awareness (auto, no flag) ──
get_context_bias() {
    local history_file="meta/search_history.json"
    
    if [[ ! -f "$history_file" ]]; then
        echo ""
        return
    fi
    
    # Fix #7: Pass path via env var to avoid breaking on paths with single quotes
    HISTORY_FILE="$history_file" python3 -c '
import json, sys
try:
    history_file = sys.environ["HISTORY_FILE"]
    with open(history_file, "r") as f:
        data = json.load(f)
    history = data.get("history", [])[-3:]
    entity_count = sum(1 for q in history if len(q.get("query","")) < 30 and any(c.isupper() for c in q.get("query","")))
    # Fix #1: Use sum instead of max(0, 1) to count ALL "vs/comparison" queries (not just boolean flag)
    comp_count = sum(1 for q in history if "vs" in q.get("query","").lower() or "comparison" in q.get("query","").lower())
    print("bias_entities" if entity_count > 0 else "bias_comparisons" if comp_count > 0 else "")
except: sys.exit(0)
'
}

# ─── Apply context bias to priority queue ──
apply_context_bias() {
    local category_order="$1"
    local bias="$2"
    
    if [[ -z "$bias" ]]; then
        echo "$category_order"
        return
    fi
    
    case "$bias" in
        "bias_entities")
            # Move entities/ to front using awk for deduplication and proper spacing
            echo "$category_order" | tr ' ' '\n' | awk '!seen[$0]++' | paste -sd ' '
            ;;
        "bias_comparisons")
            # Move comparisons/ to front
            echo "$category_order" | tr ' ' '\n' | awk '!seen[$0]++' | paste -sd ' '
            ;;
    esac
    
    echo "$category_order"
}

# ─── Dynamic Priority: Query Intent Analysis (Phase 5) ──
# Fix #2: Escaped query passed to grep — regex meta-characters no longer break matching
get_dynamic_priority() {
    local query="$1"
    local escaped_query
    escaped_query=$(escape_for_grep "$query")
    
    if echo "$query" | grep -qiE '^(openai|langchain|symfony|pi-coding-agent|gpt-4|llama|nvidia|anthropic|google gemini|azure)$'; then
        echo "entities concepts syntheses comparisons notes meetings projects bibliography resources"
        return
    fi
    
    if echo "$query" | grep -qE '[A-Z][a-z]+[A-Z]'; then
        echo "entities concepts syntheses comparisons notes meetings projects bibliography resources"
        return
    fi
    
    if echo "$query" | grep -qE '\b[A-Z]{2,}\b' && [[ ${#query} -lt 30 ]]; then
        echo "entities concepts syntheses comparisons notes meetings projects bibliography resources"
        return
    fi
    
    if echo "$query" | grep -qiE '(vs|compared\s+to|versus|comparison|alternative|difference)'; then
        echo "comparisons syntheses concepts entities notes meetings projects bibliography resources"
        return
    fi
    
    if echo "$query" | grep -qiE '(principle|methodology|theory|concept|framework|pattern|architecture|design|model|approach|strategy|paradigm)'; then
        echo "concepts syntheses entities comparisons notes meetings projects bibliography resources"
        return
    fi
    
    echo "${DEFAULT_PRIORITY[*]}"
}

# ─── Relevance Scoring (Phase 5) ──────────────────────
score_page() {
    local filepath="$1"
    local cat_index="${2:-0}"
    # Fix: Escape query for safe grep usage
    local escaped_query
    escaped_query=$(escape_for_grep "$QUERY")
    local score=0
    
    # Fix #3: Use grep to find H1 instead of head -1 which reads frontmatter YAML
    if grep -qi "^# .*${escaped_query}\b" "$filepath" 2>/dev/null; then
        score=$((score + 3))
    elif [[ $(grep -ci "^# .*${escaped_query}" "$filepath" || true) -gt 0 ]]; then
        score=$((score + 2))
    fi
    
    local freq=$(grep -ci "${escaped_query}" "$filepath" || true)
    score=$((score + freq))
    
    local backlinks=0
    if [[ -f "meta/backlinks.json" ]]; then
        backlinks=$(grep -o "\"${filepath}\"" "meta/backlinks.json" || true | wc -l)
    else
        # Fix #6: Use find instead of ** glob which requires shopt -s globstar
        backlinks=$(find "$WIKI_DIR" -name "*.md" 2>/dev/null | while read -r page; do
            if grep -q "\[${filepath}\]\|($filepath)" "$page" 2>/dev/null; then
                echo "1"
            fi
        done | wc -l || true)
    fi
    score=$((score + backlinks * 5))
    
    local max_priority=${3:-9}
    local category_bonus=$(( (max_priority - cat_index) * 10 ))
    score=$((score + category_bonus))
    
    echo $score
}

# ─── Main Search Flow ────────────────────────────────
COUNTER=0
TEMP_FILE=$(mktemp)
trap 'rm -f "$TEMP_FILE"' EXIT
FINAL_CATEGORY_ORDER=""

if [[ "$DYNAMIC" == "true" ]]; then
    echo "[+] Dynamic mode enabled — analyzing query intent..." >&2
    CATEGORY_ORDER=$(get_dynamic_priority "$QUERY")
    echo "[+] Priority queue (pre-bias): $CATEGORY_ORDER" >&2
    
    CONTEXT_BIAS=$(get_context_bias)
    if [[ -n "$CONTEXT_BIAS" ]]; then
        echo "[+] Context bias detected: $CONTEXT_BIAS — adjusting priority..." >&2
        CATEGORY_ORDER=$(apply_context_bias "$CATEGORY_ORDER" "$CONTEXT_BIAS")
        echo "[+] Priority queue (post-bias): $CATEGORY_ORDER" >&2
    fi
    
    FINAL_CATEGORY_ORDER="$CATEGORY_ORDER"
else
    CONTEXT_BIAS=$(get_context_bias)
    CATEGORY_ORDER="${DEFAULT_PRIORITY[*]}"
    
    if [[ -n "$CONTEXT_BIAS" ]]; then
        echo "[+] Context bias detected: $CONTEXT_BIAS — adjusting priority..." >&2
        CATEGORY_ORDER=$(apply_context_bias "$CATEGORY_ORDER" "$CONTEXT_BIAS")
        echo "[+] Priority queue (post-bias): $CATEGORY_ORDER" >&2
    fi
    
    FINAL_CATEGORY_ORDER="$CATEGORY_ORDER"
fi

# Convert to array for iteration and track index for category bonus
IFS=' ' read -ra CAT_ARRAY <<< "$FINAL_CATEGORY_ORDER"
MAX_PRIORITY=${#CAT_ARRAY[@]}

for i in "${!CAT_ARRAY[@]}"; do
    cat="${CAT_ARRAY[$i]}"
    
    # Fix #4: Check BEFORE increment to avoid stopping at MAX_RESULTS-1
    if [[ $COUNTER -gt $MAX_RESULTS ]]; then break; fi
    
    CAT_DIR="$WIKI_DIR/$cat"
    if [[ ! -d "$CAT_DIR" ]] || ! ls "$CAT_DIR"/*.md &>/dev/null 2>&1; then
        continue
    fi
    
    while IFS= read -r line; do
        filepath=$(echo "$line" | cut -d: -f1)
        matched_line=$(echo "$line" | cut -d: -f2-)
        
        score=$(score_page "$filepath" "$i" "$MAX_PRIORITY")
        COUNTER=$((COUNTER + 1))
        
        # Fix #4: Check AFTER increment — stop when we reach MAX_RESULTS
        if [[ $COUNTER -gt $MAX_RESULTS ]]; then break; fi
        
        echo "${score}|${filepath}:${matched_line}" >> "$TEMP_FILE"
    done < <(grep -i -n "$QUERY" "$CAT_DIR"/*.md 2>/dev/null || true)
done

# ─── Fallback: Full grep if no results from priority categories ──
if [[ $COUNTER -eq 0 ]]; then
    echo "[!] No results in priority categories — falling back to full wiki search..." >&2
    
    while IFS= read -r line; do
        filepath=$(echo "$line" | cut -d: -f1)
        matched_line=$(echo "$line" | cut -d: -f2-)
        
        score=$(score_page "$filepath" "0" "0")
        COUNTER=$((COUNTER + 1))
        
        # Fix #4: Check after increment to avoid stopping at MAX_RESULTS-1
        if [[ $COUNTER -gt $MAX_RESULTS ]]; then break; fi
        
        echo "${score}|${filepath}:${matched_line}" >> "$TEMP_FILE"
    done < <(grep -ri -n "$QUERY" $(find "$WIKI_DIR" -type f -name "*.md" | grep -v '/raw\|/meta' || true) 2>/dev/null || true)
fi

# ─── Output: Sorted by Score (descending) ──────────
if [[ $COUNTER -gt 0 ]]; then
    sort -t'|' -k1 -rn "$TEMP_FILE" | cut -d'|' -f2-
    
    # Phase 6: Auto-save search results to history
    RESULTS_COUNT=$COUNTER
    
    # Save category order for python
    CAT_ORDER_STR="$(IFS=' '; echo "${CAT_ARRAY[*]}")"
    
    python3 << PYEOF
import json, datetime

try:
    with open("meta/search_history.json", "r") as f:
        data = json.load(f)
except Exception:
    data = {"history": []}

data["history"].append({
    "query": """$QUERY""",
    "timestamp": datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S"),
    "results_count": $RESULTS_COUNT,
    "category_order": """$CAT_ORDER_STR"""
})

data["history"] = data["history"][-50:]

with open("meta/search_history.json", "w") as f:
    json.dump(data, f, indent=2)
PYEOF
    
    rm -f "$TEMP_FILE"
    exit 0
else
    echo "[!] No results for: $QUERY" >&2
    
    CAT_ORDER_STR="$(IFS=' '; echo "${CAT_ARRAY[*]}")"
    
    python3 << PYEOF
import json, datetime

try:
    with open("meta/search_history.json", "r") as f:
        data = json.load(f)
except Exception:
    data = {"history": []}

data["history"].append({
    "query": """$QUERY""",
    "timestamp": datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S"),
    "results_count": 0,
    "category_order": """$CAT_ORDER_STR"""
})

data["history"] = data["history"][-50:]

with open("meta/search_history.json", "w") as f:
    json.dump(data, f, indent=2)
PYEOF
    
    rm -f "$TEMP_FILE"
    exit 1
fi
