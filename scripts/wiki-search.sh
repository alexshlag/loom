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
    printf '%s' "$1" | sed 's/[\[\.\\^\$*+?{}()|]/\\\&/g'
}

# Phase 5: Parse flags first, collect positional args for query
POSITIONAL_ARGS=()
BUILD_INDEX=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --max|-m) MAX_RESULTS="${2:-$MAX_RESULTS}"; shift 2;;
        --dynamic|-d) DYNAMIC=true; shift;;
        --build-index|--bi) BUILD_INDEX=true; shift;;
        *) POSITIONAL_ARGS+=("$1"); shift;;
    esac
done

# If build index flag is set, run H1 index builder and exit
if [[ "$BUILD_INDEX" == "true" ]]; then
    echo "[*] Building H1 header index..." >&2
    python3 "$SCRIPT_DIR/h1-index.py" --build 2>&1
    exit $?
fi

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
# Reads meta/search_history.json → detects intent + topic continuity → returns bias
get_context_bias() {
    local history_file="meta/search_history.json"
    
    if [[ ! -f "$history_file" ]]; then
        echo ""
        return
    fi
    
    # Pass path via env var to avoid bash escaping issues
    HISTORY_FILE="$history_file" CURRENT_QUERY="$QUERY" python3 << 'PYSCRIPT'
import json, sys, re

def get_topic_tags(query):
    """Extract topic keywords from query (exclude stop-words)."""
    words = set(re.findall(r'\b[a-z]{3,}\b', query.lower()))
    stop = {"what", "how", "when", "why", "which", "compare", "difference",
            "vs", "versus", "between", "tell", "explain", "describe"}
    return words - stop

def detect_intent(query):
    """Simple intent detection from query keywords."""
    ql = query.lower()
    if re.search(r'\b(vs|compared\s+to|versus|alternative\s+to)\b', ql):
        return "comparison"
    if re.search(r'\b(principles?|methodolog|framework|architecture|pattern|design\s+system)\b', ql):
        return "concept"
    if len(query.split()) <= 3 and any(c.isupper() for c in query):
        return "entity_lookup"
    return "general_search"

try:
    import os
    history_file = os.environ["HISTORY_FILE"]
    current_query = os.environ.get("CURRENT_QUERY", "")
    
    with open(history_file, "r") as f:
        data = json.load(f)
    
    # Only consider last 3 queries (compact window)
    recent = [q for q in data.get("queries", [])[-3:] if q.get("status") == "active"]
    current_intent = detect_intent(current_query) if current_query else None
    current_topics = get_topic_tags(current_query) if current_query else set()
    
    # Check topic continuity: does current query share topics with recent queries?
    topic_overlap = False
    focus_topic = data.get("current_focus_topic", "")
    for q in recent:
        q_topics = set(q.get("topic_tags", []))
        if not current_topics or not q_topics:
            continue
        overlap = len(current_topics & q_topics) > 0
        if overlap:
            topic_overlap = True
        # If focus changed significantly, flag reset needed (stderr for logging only)
        if focus_topic and q_topics and not (current_topics & q_topics):
            print("topic_reset_needed", file=sys.stderr)
    
    # Build bias based on intent + continuity
    if current_intent == "comparison" or any(q.get("intent") == "comparison" for q in recent):
        print("bias_comparisons_concepts")
    elif current_intent == "entity_lookup" or any(q.get("intent") == "entity_lookup" for q in recent):
        print("bias_entities")
    elif topic_overlap:
        # Continue same topic → boost concepts + syntheses (deeper analysis)
        print("bias_topic_continuity")
    else:
        print("")  # No bias
except Exception as e:
    print(f"[!] Context bias error: {e}", file=sys.stderr)
    sys.exit(0)
PYSCRIPT
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
            # Move entities/ to front
            echo "$category_order" | tr ' ' '\n' | awk '!seen[$0]++' | paste -sd ' '
            ;;
        "bias_comparisons_concepts")
            # Move comparisons + concepts to front
            local new_order=""
            for cat in comparisons syntheses concepts entities; do
                if echo "$category_order" | grep -qw "$cat"; then
                    new_order+="$cat "
                fi
            done
            # Add remaining categories
            for cat in $category_order; do
                case "$cat" in
                    comparisons|syntheses|concepts) ;; # already added
                    *) new_order+="$cat " ;;
                esac
            done
            echo "${new_order% }"
            ;;
        "bias_topic_continuity")
            # Boost concepts → syntheses → entities (deeper analysis path)
            local new_order=""
            for cat in concepts syntheses entities; do
                if echo "$category_order" | grep -qw "$cat"; then
                    new_order+="$cat "
                fi
            done
            for cat in $category_order; do
                case "$cat" in
                    concepts|syntheses|entities) ;; # already added
                    *) new_order+="$cat " ;;
                esac
            done
            echo "${new_order% }"
            ;;
    esac
    
    echo "$category_order"
}

# ─── Dynamic Priority: Query Intent Analysis (Phase 5) ──
get_dynamic_priority() {
    local query="$1"
    
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

# ─── Main Search Flow (Phase 5: H1 Index + Priority) ──────────────────────
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

# ─── Phase 1: H1 Index Fast Lookup (O(k log n)) ──────────────
# Fix #21: Pass query via env var to prevent heredoc injection
export SEARCH_QUERY="$QUERY" MAX_RESULTS="$MAX_RESULTS"
H1_RESULTS=$(
    python3 << 'PYEOF'
import json, os, sys, re

wiki_dir = os.environ.get("WIKI_DIR", "wiki")
h1_index_file = "meta/h1-index.json"
query = os.environ.get("SEARCH_QUERY", "").lower()
max_results = int(os.environ.get("MAX_RESULTS", "15"))

# Load H1 index
try:
    with open(h1_index_file) as f:
        h1_index = json.load(f)
except Exception:
    sys.exit(0)

if not isinstance(h1_index, dict):
    sys.exit(0)

query_words = query.split()
results = []

# Find matching files via H1 index (fast O(log n) lookup)
for key, value in h1_index.items():
    if isinstance(value, list):
        # Category -> paths mapping — skip
        continue
    
    if not isinstance(value, dict):
        continue
    
    rel_path = value.get('path', '')
    h1_text = value.get('h1', '').lower()
    
    if not h1_text or not rel_path:
        continue
    
    # Check H1 match with query words
    score = 0
    for qword in query_words:
        # Direct keyword match in H1 → +3 per occurrence
        exact_match = sum(1 for w in h1_text.split() if w == qword)
        score += exact_match * 3
        
        # Prefix/substring match → +1
        prefix_match = sum(1 for w in h1_text.split() if w.startswith(qword))
        score += prefix_match
    
    if score > 0:
        results.append((score, rel_path))

# Sort by score descending, take top N
results.sort(key=lambda x: x[0], reverse=True)
top_results = results[:max_results * 2]

for score, path in top_results:
    print(f"{path}:{score}")
PYEOF
) || true

if [[ -n "$H1_RESULTS" ]]; then
    # Score H1 results and add to temp file
    while IFS= read -r line; do
        filepath=$(echo "$line" | cut -d: -f1)
        h1_score=$(echo "$line" | cut -d: -f2-)
        
        # Get category index for bonus
        cat_index=0
        for i in "${!CAT_ARRAY[@]}"; do
            if echo "$filepath" | grep -q "${CAT_ARRAY[$i]/}.*\.md$"; then
                cat_index=$i
                break
            fi
        done
        
        # Get matched line content from file
        matched_line=$(grep -i -m 1 "$QUERY" "$WIKI_DIR/$filepath" 2>/dev/null | head -1 || true)
        
        COUNTER=$((COUNTER + 1))
        echo "${h1_score}|${filepath}:${matched_line}" >> "$TEMP_FILE"
    done <<< "$H1_RESULTS"
fi

# ─── Phase 2: Priority Category Grep (O(m×n) but only for priority categories) ──
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
save_query_to_history() {
    local query="$1"
    local results_count="$2"
    local cat_order_str="$3"
    
    # Fix: pass query via env vars, not inline expansion (prevents heredoc injection)
    export HISTORY_QUERY="$QUERY" HISTORY_RESULTS_COUNT="$results_count" CAT_ORDER_STR="$cat_order_str"
    python3 << 'PYEOF'
import json, os, datetime, re

def get_topic_tags(q):
    """Extract topic keywords."""
    words = set(re.findall(r'\b[a-z]{3,}\b', q.lower()))
    stop = {"what", "how", "when", "why", "which", "compare", "difference",
            "vs", "versus", "between", "tell", "explain", "describe"}
    return list(words - stop)

def detect_intent(q):
    ql = q.lower()
    if re.search(r'\b(vs|compared\s+to|versus|alternative)\b', ql):
        return "comparison"
    if re.search(r'\b(principles?|methodolog|framework|architecture|pattern)\b', ql):
        return "concept"
    if len(q.split()) <= 3 and any(c.isupper() for c in q):
        return "entity_lookup"
    return "general_search"

try:
    with open("meta/search_history.json", "r") as f:
        data = json.load(f)
except Exception:
    data = {"queries": [], "max_entries": 5}

entry = {
    "query": os.environ.get("HISTORY_QUERY", ""),
    "timestamp": datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S"),
    "results_count": int(os.environ.get("HISTORY_RESULTS_COUNT", "0")),
    "intent": detect_intent(os.environ.get("HISTORY_QUERY", "")),
    "topic_tags": get_topic_tags(os.environ.get("HISTORY_QUERY", "")),
    "status": "active"
}

# Append and keep only last max_entries
data["queries"].append(entry)
data["queries"] = data["queries"][-(data.get("max_entries", 5)):]

# Update focus topic if continuity detected
if len(data["queries"]) >= 2:
    latest = data["queries"][-1]
    prev = data["queries"][-2]
    current_tags = set(latest.get("topic_tags", []))
    prev_tags = set(prev.get("topic_tags", []))
    if current_tags and prev_tags and (current_tags & prev_tags):
        # Continue same topic — keep focus
        pass
    elif latest.get("intent") in ("entity_lookup", "comparison"):
        data["current_focus_topic"] = f"{latest['intent']}_query"

with open("meta/search_history.json", "w") as f:
    json.dump(data, f, indent=2)
PYEOF
}

if [[ $COUNTER -gt 0 ]]; then
    sort -t'|' -k1 -rn "$TEMP_FILE" | cut -d'|' -f2-
    
    RESULTS_COUNT=$COUNTER
    
    # Phase 6: Auto-save search to history (compact, last N entries)
    cat_order_str="$(IFS=' '; echo "${CAT_ARRAY[*]}")"
    export HISTORY_QUERY="$QUERY" HISTORY_RESULTS_COUNT="$RESULTS_COUNT" CAT_ORDER_STR
    save_query_to_history "$QUERY" "$RESULTS_COUNT" "$cat_order_str"
    
    rm -f "$TEMP_FILE"
    exit 0
else
    echo "[!] No results for: $QUERY" >&2
    
    # Also save empty queries to track what user looked for
    cat_order_str="$(IFS=' '; echo "${CAT_ARRAY[*]}")"
    export HISTORY_QUERY="$QUERY" HISTORY_RESULTS_COUNT="0" CAT_ORDER_STR
    save_query_to_history "$QUERY" "0" "$cat_order_str"
    
    rm -f "$TEMP_FILE"
    exit 1
fi
