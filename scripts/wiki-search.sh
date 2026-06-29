#!/usr/bin/env bash
# wiki-search.sh — Умный поиск по категориям wiki с приоритетом релевантности
# 
# Usage: ./wiki-search.sh "query" [wiki_dir] [--max N] [--dynamic]
#
# Логика (Phase 2 + Phase 5)
#   1. Static mode: priority-categories из DEFAULT_PRIORITY (syntheses → concepts → entities)
#   2. Dynamic mode (--dynamic): query intent analysis → entity/concept/comparison keywords → dynamic order categories
#   4. Relevance scoring: position weight (H1 = x3), frequency count, backlink weight + category bonus
#   5. Output: sorted by combined score (descending) — релевантные страницы выше
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

# ─── Relevance Scoring (Phase 5 + S5 integration) ──────────────────────
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
    
    # S5: Popularity boost from search_analytics.json (soft signal, never filters)
    # Reads topics{} → uses persistent rating DB. Falls back to entries list.
    local popularity_boost=0
    if [[ -f "meta/search_analytics.json" ]]; then
        popularity_boost=$(POPULARITY_FILEPATH="$filepath" ANALYTICS_PATH="meta/search_analytics.json" \
            python3 -c '
import json, os, datetime
fp = os.environ.get("POPULARITY_FILEPATH", "")
af = os.environ.get("ANALYTICS_PATH", "meta/search_analytics.json")
tpb = 5
mb = 30
decay_days = 30
decay_factor = 0.5
try:
    with open(af) as f: data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError): print(0); exit()
topics = data.get("topics", {})
count = topics.get(fp, {}).get("popularity_score", 0)
if count == 0:
    count = sum(1 for e in data.get("entries", []) if e.get("top_path") and fp.replace("wiki/", "") in e["top_path"])
# Time decay: apply -50% boost if last_seen > decay_days
last_seen_str = topics.get(fp, {}).get("last_seen", "")
if last_seen_str:
    try:
        ls_date = datetime.datetime.strptime(last_seen_str.split(",")[0], "%Y-%m-%dT%H:%M:%S")
        now = datetime.datetime.now()
        days_diff = (now - ls_date).days
        if days_diff > decay_days:
            count *= decay_factor
    except ValueError:
        pass  # invalid timestamp — skip decay, use raw count
print(min(int(count * tpb), mb))
' 2>/dev/null) || popularity_boost=0
    fi
    score=$((score + popularity_boost))
    
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
    
    
    FINAL_CATEGORY_ORDER="$CATEGORY_ORDER"
else
    CATEGORY_ORDER="${DEFAULT_PRIORITY[*]}"
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

# Capture top result path for analytics (if any)
TOP_PATH=""
if [[ $COUNTER -gt 0 ]]; then
    # Format: score|filepath:matched_line → extract just filepath (before first ':')
    TOP_PATH=$(sort -t'|' -k1 -rn "$TEMP_FILE" | head -1 | cut -d'|' -f2 | cut -d':' -f1) || true
fi

save_search_analytics() {
    local query="$1"
    local results_count="$2"  # 0 = no results, >0 = actual count
    local top_path="${3:-}"   # first result filepath (may be empty)
    local analytics_file="meta/search_analytics.json"
    
    python3 << PYEOF &
import json, os, datetime

query = os.environ.get("ANALYTICS_QUERY", "")
results_count = int(os.environ.get("ANALYTICS_RESULTS_COUNT", "0"))
top_path = os.environ.get("ANALYTICS_TOP_PATH", "")
analytics_file = os.environ.get("ANALYTICS_FILE", "meta/search_analytics.json")
max_entries = 100

# Read existing data or create new structure
try:
    with open(analytics_file, "r") as f:
        data = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    data = {"schema_version": 2, "max_entries": max_entries, "entries": [], "topics": {}}

# Ensure structure exists
if "schema_version" not in data:
    data["schema_version"] = 2
if "max_entries" not in data:
    data["max_entries"] = max_entries
if "entries" not in data:
        data["entries"] = []
if "topics" not in data:
    data["topics"] = {}

# Generate next sequential ID from current entries count
next_id_num = len(data.get("entries", [])) + 1
query_id = f"q_{next_id_num:04d}"

# Create new entry
timestamp_str = datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
new_entry = {
    "id": query_id,
    "timestamp": timestamp_str,
    "query": query,
    "results_count": results_count,
}
if top_path:
    new_entry["top_path"] = top_path
else:
    new_entry["top_path"] = None

# Append entry
data["entries"].append(new_entry)

# Trim oldest entries by timestamp (FIFO) if at capacity
if len(data["entries"]) > data.get("max_entries", max_entries):
    # Sort by timestamp ascending, keep only newest N
    data["entries"].sort(key=lambda e: e.get("timestamp", ""))
    trimmed_count = len(data["entries"]) - data.get("max_entries", max_entries)
    trimmed_ids = [e["id"] for e in data["entries"][:trimmed_count]]
    del data["entries"][:trimmed_count]
    # Clean up topics — remove IDs that no longer exist
    for topic_id, td in list(data.get("topics", {}).items()):
        td["first_queries"] = [q for q in td.get("first_queries", []) if q not in trimmed_ids]
else:
    trimmed_ids = []  # nothing removed

# Update topics{} by top_path (persistent rating DB)
if top_path and results_count > 0:
    topics = data.setdefault("topics", {})
    td = topics.get(top_path)
    if td:
        # Increment counters, update last_seen
        td["popularity_score"] = td.get("popularity_score", 1) + 1
        td["last_seen"] = timestamp_str
        # Add query_id to first_queries (deduplicate)
        fq = set(td.get("first_queries", []))
        fq.add(query_id)
        td["first_queries"] = list(fq)
    else:
        # Create new topic entry
        topics[top_path] = {
            "popularity_score": 1,
            "last_seen": timestamp_str,
            "first_queries": [query_id],
        }

# Write back atomically via temp-file + rename
with open(analytics_file + ".tmp", "w") as f:
    json.dump(data, f, indent=2)
os.rename(analytics_file + ".tmp", analytics_file)  # atomic rename
PYEOF
}

if [[ $COUNTER -gt 0 ]]; then
    sort -t'|' -k1 -rn "$TEMP_FILE" | cut -d'|' -f2-
    ANALYTICS_QUERY="$QUERY" ANALYTICS_RESULTS_COUNT="$COUNTER" \
        ANALYTICS_TOP_PATH="$TOP_PATH" \
        save_search_analytics "$QUERY" "$COUNTER"
    rm -f "$TEMP_FILE"
    exit 0
else
    echo "[!] No results for: $QUERY" >&2
    ANALYTICS_QUERY="$QUERY" ANALYTICS_RESULTS_COUNT="0" \
        ANALYTICS_TOP_PATH="" \
        save_search_analytics "$QUERY" "0"
    rm -f "$TEMP_FILE"
    exit 1
fi
