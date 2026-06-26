#!/usr/bin/env bash
# wiki-search.sh — Умный поиск по категориям wiki с приоритетом релевантности
# 
# Usage: ./wiki-search.sh "query" [wiki_dir] [--max N] [--dynamic]
#
# Логика (Phase 2 + Phase 5):
#   1. Static mode: priority-categories из DEFAULT_PRIORITY (syntheses → concepts → entities)
#   2. Dynamic mode (--dynamic): query intent analysis → entity/concept/comparison keywords → dynamic order categories
#   3. Relevance scoring: position weight (H1 = x3), frequency count, backlink weight + category bonus
#   4. Output: sorted by combined score (descending) — релевантные страницы выше
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

# Phase 5: Parse flags first, collect positional args for query
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --max|-m) MAX_RESULTS="${2:-$MAX_RESULTS}"; shift 2;;
        --dynamic|-d) DYNAMIC=true; shift;;
        *) POSITIONAL_ARGS+=("$1"); shift;;
    esac
done

# First positional arg is the query
if [[ ${#POSITIONAL_ARGS[@]} -eq 0 ]] || [[ -z "${POSITIONAL_ARGS[0]:-}" ]]; then
    echo "[!] Usage: $0 \"query\" [wiki_dir] [--max N] [--dynamic]" >&2
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
    
    # Entity keywords (конкретные имена, продукты, компании) — расширяемый список
    if echo "$query" | grep -qiE '^(openai|langchain|symfony|pi-coding-agent|gpt-4|llama|nvidia|anthropic|google gemini|azure)$'; then
        echo "entities concepts syntheses comparisons notes meetings projects bibliography resources"
        return
    fi
    
    # Detect camelCase entity names (e.g. PiCodingAgent, SymfonyUX)
    if echo "$query" | grep -qE '[A-Z][a-z]+[A-Z]'; then
        echo "entities concepts syntheses comparisons notes meetings projects bibliography resources"
        return
    fi
    
    # Detect uppercase entity names (e.g. GPT, LLM) — short queries only to avoid false positives
    if echo "$query" | grep -qE '\b[A-Z]{2,}\b' && [[ ${#query} -lt 30 ]]; then
        echo "entities concepts syntheses comparisons notes meetings projects bibliography resources"
        return
    fi
    
    # Comparison keywords (vs, compared to, comparison)
    if echo "$query" | grep -qiE '(vs|compared\s+to|versus|comparison|alternative|difference)'; then
        echo "comparisons syntheses concepts entities notes meetings projects bibliography resources"
        return
    fi
    
    # Concept keywords (принципы, методологии, теория)
    if echo "$query" | grep -qiE '(principle|methodology|theory|concept|framework|pattern|architecture|design|model|approach|strategy|paradigm)'; then
        echo "concepts syntheses entities comparisons notes meetings projects bibliography resources"
        return
    fi
    
    # Default: no dynamic intent detected — static priority
    echo "${DEFAULT_PRIORITY[*]}"
}

# ─── Relevance Scoring (Phase 5) ──────────────────────
# Score a page based on: position_weight, frequency_weight, backlink_weight + category_bonus
score_page() {
    local filepath="$1"
    local cat_index="${2:-0}"
    local score=0
    
    # Position weight: if query appears in H1 → x3 multiplier
    if head -1 "$filepath" | grep -qi "^.#.*$QUERY"; then
        score=$((score + 3))
    elif [[ $(grep -c "^#. .*${QUERY}" "$filepath") -gt 0 ]]; then
        score=$((score + 2))
    fi
    
    # Frequency weight: count query occurrences in file
    local freq=$(grep -ci "${QUERY}" "$filepath" || true)
    score=$((score + freq))
    
    # Backlink weight: check if page is mentioned in other wiki pages (from meta/backlinks.json or direct grep)
    local backlinks=0
    if [[ -f "meta/backlinks.json" ]]; then
        # Parse JSON for mentions of this file
        backlinks=$(grep -o "\"${filepath}\"" "meta/backlinks.json" || true | wc -l)
    else
        # Fallback: count how many other wiki pages mention this file path
        backlinks=$(find "$WIKI_DIR"/*.md "$WIKI_DIR"/**/*.md 2>/dev/null | while read -r page; do
            if grep -q "\[${filepath}\]\|($filepath)" "$page" 2>/dev/null; then
                echo "1"
            fi
        done | wc -l || true)
    fi
    score=$((score + backlinks * 5))  # Each backlink = 5 points
    
    # Category bonus: higher priority categories get more points
    # cat_index=0 (first in priority queue) → max bonus, lower index = less bonus
    local max_priority=${3:-9}
    local category_bonus=$(( (max_priority - cat_index) * 10 ))
    score=$((score + category_bonus))
    
    echo $score
}

# ─── Main Search Flow ────────────────────────────────
COUNTER=0
TEMP_FILE=$(mktemp)

if [[ "$DYNAMIC" == "true" ]]; then
    # Phase 5: Dynamic priority categories based on query intent
    echo "[+] Dynamic mode enabled — analyzing query intent..." >&2
    CATEGORY_ORDER=$(get_dynamic_priority "$QUERY")
    echo "[+] Priority queue: $CATEGORY_ORDER" >&2
else
    CATEGORY_ORDER="${DEFAULT_PRIORITY[*]}"
fi

# Convert to array for iteration and track index for category bonus
IFS=' ' read -ra CAT_ARRAY <<< "$CATEGORY_ORDER"
MAX_PRIORITY=${#CAT_ARRAY[@]}

for i in "${!CAT_ARRAY[@]}"; do
    cat="${CAT_ARRAY[$i]}"
    
    if [[ $COUNTER -ge $MAX_RESULTS ]]; then break; fi
    
    # Phase 5: Add category bonus for priority position (earlier = higher bonus)
    local_category_bonus=$(( (MAX_PRIORITY - i - 1) * 10 ))
    
    CAT_DIR="$WIKI_DIR/$cat"
    if [[ ! -d "$CAT_DIR" ]] || ! ls "$CAT_DIR"/*.md &>/dev/null 2>&1; then
        continue
    fi
    
    # Search with scoring — append to temp file instead of string
    while IFS= read -r line; do
        filepath=$(echo "$line" | cut -d: -f1)
        matched_line=$(echo "$line" | cut -d: -f2-)
        
        score=$(score_page "$filepath" "$i" "$MAX_PRIORITY")
        COUNTER=$((COUNTER + 1))
        
        if [[ $COUNTER -ge $MAX_RESULTS ]]; then break; fi
        
        # Append to temp file with score for sorting
        echo "${score}|${filepath}:${matched_line}" >> "$TEMP_FILE"
    done < <(grep -i -n "$QUERY" "$CAT_DIR"/*.md 2>/dev/null || true)
done

# ─── Fallback: Full grep if no results from priority categories ──
if [[ $COUNTER -eq 0 ]]; then
    echo "[!] No results in priority categories — falling back to full wiki search..." >&2
    
    while IFS= read -r line; do
        filepath=$(echo "$line" | cut -d: -f1)
        matched_line=$(echo "$line" | cut -d: -f2-)
        
        score=$(score_page "$filepath" "0" "0")  # No category bonus for fallback
        COUNTER=$((COUNTER + 1))
        
        if [[ $COUNTER -ge $MAX_RESULTS ]]; then break; fi
        
        echo "${score}|${filepath}:${matched_line}" >> "$TEMP_FILE"
    done < <(grep -ri -n "$QUERY" "$WIKI_DIR"/*.md "$WIKI_DIR"/**/*.md 2>/dev/null || true)
fi

# ─── Output: Sorted by Score (descending) ──────────
if [[ $COUNTER -gt 0 ]]; then
    # Sort by score descending, remove score prefix
    sort -t'|' -k1 -rn "$TEMP_FILE" | cut -d'|' -f2-
    rm -f "$TEMP_FILE"
    exit 0
else
    echo "[!] No results for: $QUERY" >&2
    rm -f "$TEMP_FILE"
    exit 1
fi
