#!/usr/bin/env bash
# auto-crosslink.sh — Автоматически находит wiki-страницы, которые нужно обновить cross-links
# после создания новой страницы. Парсит H1 новой страницы, ищет упоминания в других файлах.
# 
# Usage: ./scripts/auto-crosslink.sh <new_page.md> [--include-root]
# Output: JSON array [{"path": "...", "match_type": "title_mention|keyword_mention"}]
# Exit codes: 0 = found matches, 1 = no mentions found

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
WIKI_DIR="${PROJECT_ROOT}/wiki"

# Parse arguments
NEW_PAGE=""
INCLUDE_ROOT=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --include-root) INCLUDE_ROOT=true; shift;;
        *) NEW_PAGE="$1"; shift;;
    esac
done

if [[ -z "${NEW_PAGE:-}" ]]; then
    echo "[]"
    exit 1
fi

# Normalize path: strip ./ prefix, strip wiki/ prefix if present, remove trailing .md
NEW_REL="${NEW_PAGE#./}"
[[ "$NEW_REL" == wiki/* ]] && NEW_REL="${NEW_REL#wiki/}"
NEW_REL="${NEW_REL%.md}"
NEW_FILE="${WIKI_DIR}/${NEW_REL}.md"

if [[ ! -f "$NEW_FILE" ]]; then
    echo "[]"
    exit 1
fi

# Phase 7: Extract H1 title and keywords from new page
TITLE=$(grep "^# " "$NEW_FILE" | head -1 | sed 's/^# //') || true
if [[ -z "$TITLE" ]]; then
    echo "[]"
    exit 1
fi

# Extract keywords: individual words from title (for multi-word matching)
KEYWORDS=$(echo "$TITLE" | awk '{for(i=1;i<=NF;i++) print $i}' | tr '\n' ' ') || true

# Phase 7: Search all wiki pages for mentions of new page title/keywords
# Skip meta/, raw/ directories and the new page itself
MATCHES_JSON="["
FIRST=true

while IFS= read -r filepath; do
    # Skip if this is the same file we're comparing against
    [[ "$filepath" == "$NEW_FILE" ]] && continue

    # Check for title mention (case-insensitive fixed string)
    if grep -qiF "$TITLE" "$filepath" 2>/dev/null; then
        MATCH_TYPE="title_mention"

        if [[ "$FIRST" == "true" ]]; then
            FIRST=false
        else
            MATCHES_JSON+=","
        fi

        REL_PATH="${filepath#${WIKI_DIR}/}"
        MATCHES_JSON+="{\"path\":\"${REL_PATH}\",\"match_type\":\"${MATCH_TYPE}\"}"
    # Check for keyword mention (2+ word phrases) - only if no title match yet
    elif [[ "$FIRST" == "true" ]]; then
        KEY_PATTERN=$(echo "$KEYWORDS" | awk 'NF>=2{print}' | head -3 | tr '\n' '|')
        if grep -qiF "$KEY_PATTERN" "$filepath" 2>/dev/null; then
            MATCH_TYPE="keyword_mention"
            FIRST=false
            REL_PATH="${filepath#${WIKI_DIR}/}"
            MATCHES_JSON+="{\"path\":\"${REL_PATH}\",\"match_type\":\"${MATCH_TYPE}\"}"
        fi
    fi
done < <(find "$WIKI_DIR" -name "*.md" ! -path "*/meta/*" 2>/dev/null || true)

# If --include-root is set, also search root wiki files (like overview.md)
if [[ "$INCLUDE_ROOT" == "true" ]]; then
    while IFS= read -r filepath; do
        # Skip meta, wiki dirs; also skip our new file
        [[ "$filepath" == *"meta"* ]] && continue
        [[ "$filepath" == *"/wiki/"* ]] && continue
        [[ "$filepath" == "$NEW_FILE" ]] && continue

        if grep -qiF "$TITLE" "$filepath" 2>/dev/null; then
            MATCH_TYPE="title_mention"

            if [[ "$FIRST" == "true" ]]; then
                FIRST=false
            else
                MATCHES_JSON+=","
            fi

            REL_PATH="./$(basename "$filepath")"
            MATCHES_JSON+="{\"path\":\"${REL_PATH}\",\"match_type\":\"${MATCH_TYPE}\"}"
        fi
    done < <(find "${PROJECT_ROOT}" -maxdepth 1 -name "*.md" ! -path "*/meta/*" ! -path "$WIKI_DIR*" 2>/dev/null || true)
fi

MATCHES_JSON+="]"

# Output JSON to stdout
echo "$MATCHES_JSON"

if [[ "$FIRST" == "true" ]]; then
    echo "[]"
    exit 1
else
    exit 0
fi
