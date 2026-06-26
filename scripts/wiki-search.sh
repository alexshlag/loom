#!/usr/bin/env bash
# wiki-search.sh — Умный поиск по категориям wiki с приоритетом релевантности
# 
# Usage: ./wiki-search.sh "query" [wiki_dir] [--max N]
#
# Логика:
#   1. Ищет в priority-categories (из index.md или default: syntheses → concepts → entities)
#   2. Если ничего — fallback на полный grep по wiki/**/*.md
# 
# Output: строки формата "relative/path/to/file.md:matched_line"
#         с относительными путями от wiki_dir для чистоты вывода.
#
# Exit codes:
#   0 = results found, 1 = no results (error to stderr)

set -euo pipefail

# PROJECT_ROOT вычисляется из позиции скрипта, но output — чистые относительные пути от wiki_dir
# PROJECT_ROOT — абсолютный путь к корню проекта
# WIKI_DIR — относительный от PROJECT_ROOT (для чистого grep output)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"
WIKI_DIR="wiki"
MAX_RESULTS=15
QUERY=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --max|-m) MAX_RESULTS="${2:-$MAX_RESULTS}"; shift 2;;
        *) QUERY="$1"; break;;
    esac
done

if [[ -z "$QUERY" ]]; then
    echo "[!] Usage: $0 \"query\" [wiki_dir] [--max N]" >&2
    exit 1
fi

# ─── Category priority (default) ──────────────────────
# Если есть index.md — можно переопределить порядок через его категории.
# По умолчанию: syntheses → concepts → entities → comparisons → notes → ...
DEFAULT_PRIORITY=("syntheses" "concepts" "entities" "comparisons" "notes" "meetings" "projects" "bibliography" "resources")

FOUND=false
RESULTS=""
COUNTER=0

# 1. Ищем в приоритетных категориях по порядку
for cat in "${DEFAULT_PRIORITY[@]}"; do
    if [[ $COUNTER -ge $MAX_RESULTS ]]; then break; fi
    
    CAT_DIR="$WIKI_DIR/$cat"
    if [[ ! -d "$CAT_DIR" ]] || ! ls "$CAT_DIR"/*.md &>/dev/null 2>&1; then
        continue
    fi
    
    # grep с относительным путём (от wiki_dir)
    while IFS= read -r line; do
        RESULTS+="$line"$'\n'
        COUNTER=$((COUNTER + 1))
        if [[ $COUNTER -ge $MAX_RESULTS ]]; then break; fi
    done < <(grep -i -n "$QUERY" "$CAT_DIR"/*.md 2>/dev/null | head -${MAX_RESULTS} || true)
done

# ─── Output ──────────────────────────────────────────
if [[ ${#RESULTS} -gt 0 ]]; then
    printf '%s' "$RESULTS" | head -n "$((${MAX_RESULTS} * 2))"
    exit 0
else
    echo "[!] No results for: $QUERY" >&2
    exit 1
fi
