#!/usr/bin/env bash
# duplicate-titles.sh — проверяет дубли заголовков в пределах одной категории wiki
# Usage: ./scripts/duplicate-titles.sh [wiki_dir]
# Exit code: 0 = no duplicates, 1 = duplicates found

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
WIKI_DIR="${1:-$PROJECT_ROOT/wiki}"

echo "[*] Checking for duplicate titles across wiki categories..." >&2

DUPLICATES=()

# Собираем заголовки по категориям (папкам)
for category_dir in "$WIKI_DIR/entities" "$WIKI_DIR/concepts" "$WIKI_DIR/comparisons" "$WIKI_DIR/syntheses" "$WIKI_DIR/notes" "$WIKI_DIR/meetings" "$WIKI_DIR/projects" "$WIKI_DIR/bibliography" "$WIKI_DIR/resources"; do
  if [ ! -d "$category_dir" ]; then
    continue
  fi

  declare -A title_map=()

  while IFS= read -r file; do
    # Извлекаем h1 заголовок (первая строка, начинающаяся с "# ")
    TITLE=$(head -n 5 "$file" | grep "^# " | head -1 | sed 's/^# //' || true)

    if [ -z "$TITLE" ]; then
      continue
    fi

    # Проверяем дубли в пределах категории
    if [[ "${title_map[$TITLE]+isset}" ]]; then
      DUPLICATES+=("$category_dir: '$TITLE' exists in ${title_map[$TITLE]} and $file")
    else
      title_map["$TITLE"]="$file"
    fi

  done < <(find "$category_dir" -name "*.md" -type f 2>/dev/null || true)

done

# Проверяем root файлы wiki/ (index.md, log.md, timeline.md, snapshot.md) — они не дублируются между папками
ROOT_FILES=("$WIKI_DIR/index.md" "$WIKI_DIR/log.md" "$WIKI_DIR/timeline.md" "$WIKI_DIR/snapshot.md")
declare -A root_title_map=()

for file in "${ROOT_FILES[@]}"; do
  if [ ! -f "$file" ]; then
    continue
  fi

  TITLE=$(head -n 5 "$file" | grep "^# " | head -1 | sed 's/^# //' || true)

  if [ -z "$TITLE" ]; then
    continue
  fi

  if [[ "${root_title_map[$TITLE]+isset}" ]]; then
    DUPLICATES+=("wiki/: '$TITLE' exists in ${root_title_map[$TITLE]} and $file")
  else
    root_title_map["$TITLE"]="$file"
  fi

done

if [ ${#DUPLICATES[@]} -gt 0 ]; then
  echo "[!] Duplicate titles found (${#DUPLICATES[@]}):" >&2
  for dup in "${DUPLICATES[@]}"; do
    echo "    $dup" >&2
  done >&2
  exit 1
fi

echo "[✓] No duplicate titles found" >&2
exit 0
