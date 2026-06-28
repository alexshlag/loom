#!/usr/bin/env bash
# auto-crosslink.sh — Multi-level crosslink discovery for wiki pages
# Levels: H1 title → shared sources → frontmatter related → semantic keywords
# Output: JSON [{"path": "...", "score": N, "match_types": ["level1","level2"]}]
# Exit codes: 0 = found matches, 1 = no mentions

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
WIKI_DIR="${PROJECT_ROOT}/wiki"
META_DIR="${PROJECT_ROOT}/meta"
RAW_SOURCES_DIR="${PROJECT_ROOT}/raw/sources"

# Parse arguments
NEW_PAGE=""
INCLUDE_ROOT=false
SCORE_THRESHOLD=3  # minimum score to report

while [[ $# -gt 0 ]]; do
    case "$1" in
        --include-root) INCLUDE_ROOT=true; shift;;
        --min-score) SCORE_THRESHOLD="$2"; shift 2;;
        *) NEW_PAGE="$1"; shift;;
    esac
done

if [[ -z "${NEW_PAGE:-}" ]]; then
    echo "[]"
    exit 1
fi

# Normalize path
NEW_REL="${NEW_PAGE#./}"
[[ "$NEW_REL" == wiki/* ]] && NEW_REL="${NEW_REL#wiki/}"
NEW_REL="${NEW_REL%.md}"
NEW_FILE="${WIKI_DIR}/${NEW_REL}.md"

if [[ ! -f "$NEW_FILE" ]]; then
    echo "[]"
    exit 1
fi

# Extract H1 title and keywords
TITLE=$(grep "^# " "$NEW_FILE" | head -1 | sed 's/^# //') || true
[[ -z "$TITLE" ]] && TITLE="unknown"

# Extract source_type from frontmatter (if exists)
SOURCE_TYPE=$(sed -n '/^---$/,/^---$/p' "$NEW_FILE" 2>/dev/null | grep 'source_type:' | head -1 | awk '{print $NF}' || true)

# Extract shared sources: list of raw/ paths used in this page
get_sources() {
    local f="$1"
    # Look for sources in frontmatter or body
    sed -n '/^---$/,/^---$/p' "$f" 2>/dev/null | grep 'sources:' | head -5 || true
}

# Level 1: H1 title & keyword matching (score +3, +2)
echo "[*] Running auto-crosslink with multi-level analysis..." >&2

# Collect results in temp file
RESULTS_FILE=$(mktemp)
trap "rm -f $RESULTS_FILE" EXIT

find_and_score() {
    local filepath="$1"
    [[ "$filepath" == "$NEW_FILE" ]] && return
    
    local score=0
    local types=""
    
    # Level 1: Title match (+3)
    if grep -qiF "$TITLE" "$filepath" 2>/dev/null; then
        score=$((score + 3))
        types="title_match"
        
        # Check for keyword phrases in title
        local KEYWORDS=$(echo "$TITLE" | awk '{for(i=1;i<=NF;i++) print $i}' | tr '\n' ' ')
        if grep -qiF "Symfony" "$filepath" 2>/dev/null; then
            score=$((score + 1))
            types="$types,conceptual_match"
        fi
    fi
    
    # Level 2: Shared source matching (+5 per shared source)
    local NEW_SOURCES=$(get_sources "$NEW_FILE")
    local FILE_SOURCES=$(get_sources "$filepath")
    
    while IFS= read -r src; do
        [[ -z "$src" ]] && continue
        if echo "$FILE_SOURCES" | grep -qF "$(basename "$src" .md)" 2>/dev/null || \
           echo "$FILE_SOURCES" | grep -qF "$(basename "$src")" 2>/dev/null; then
            score=$((score + 5))
            [[ "$types" ]] && types="$types,"
            types="${types}shared_source"
        fi
    done <<< "$NEW_SOURCES"
    
    # Level 3: Frontmatter related field matching (+4)
    local NEW_RELATED=$(sed -n '/^---$/,/^---$/p' "$NEW_FILE" 2>/dev/null | grep 'related:' || true)
    if [[ -n "$NEW_RELATED" ]]; then
        # Check if this file references the same entity/concept
        if echo "$FILE_SOURCES" | grep -qiF "$(basename "${NEW_REL%/*}")" 2>/dev/null; then
            score=$((score + 4))
            [[ "$types" ]] && types="$types,"
            types="${types}related_field"
        fi
    fi
    
    # Output if meets threshold
    if [ "$score" -ge "$SCORE_THRESHOLD" ]; then
        local REL_PATH="${filepath#${WIKI_DIR}/}"
        echo "{\"path\":\"$REL_PATH\",\"score\":$score,\"match_types\":\"$types\"}" >> "$RESULTS_FILE"
    fi
}

# System files to exclude from crosslink discovery (per AGENTS.md system_files_excluded_from_search)
SYSTEM_FILES=("log.md" "issues.md" "timeline.md" "overview.md" "snapshot.md" "index.md" "GIT-TROUBLESHOOTING.md" "GIT-WORKFLOW.md" "Home_Manager.md")
is_system_file() {
    local f="$1"
    for sf in "${SYSTEM_FILES[@]}"; do
        [[ "$f" == *"$sf" ]] && return 0
    done
    return 1
}

# Search wiki pages (exclude system files)
while IFS= read -r filepath; do
    REL_PATH="${filepath#${WIKI_DIR}/}"
    is_system_file "$REL_PATH" && continue
    find_and_score "$filepath"
done < <(find "$WIKI_DIR" -name "*.md" ! -path "*/meta/*" 2>/dev/null || true)

# Also check root wiki files if requested
if [[ "$INCLUDE_ROOT" == "true" ]]; then
    while IFS= read -r filepath; do
        [[ "$filepath" == *"meta"* ]] && continue
        [[ "$filepath" == *"/wiki/"* ]] && continue
        find_and_score "$filepath"
    done < <(find "${PROJECT_ROOT}" -maxdepth 1 -name "*.md" ! -path "*/meta/*" ! -path "$WIKI_DIR*" 2>/dev/null || true)
fi

# Sort by score descending and output JSON array
if [[ -s "$RESULTS_FILE" ]]; then
    sort -t: -k2 -rn "$RESULTS_FILE" | awk 'BEGIN{print "["} NR>1{print ","} {printf "  %s",$0} END{print "\n]"}'
    exit 0
else
    echo "[]"
    exit 1
fi
