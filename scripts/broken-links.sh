#!/usr/bin/env bash
# broken-links.sh — сканирует все wiki-файлы на сломанные внутренние ссылки
# Usage: ./scripts/broken-links.sh [wiki_dir]
# Exit code: 0 = no broken links, 1 = broken links found

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
WIKI_DIR="${1:-$PROJECT_ROOT/wiki}"

echo "[*] Scanning all wiki files for broken internal links..." >&2

BROKEN_LINKS=()
TOTAL_LINKS=0
VALID_LINKS=0

while IFS= read -r file; do
  # Извлекаем все markdown ссылки: [text](path) и [[wikilink]]
  while IFS= read -r link_match; do
    TOTAL_LINKS=$((TOTAL_LINKS + 1))

    # Извлекаем путь из ссылки [text](path)
    TARGET_PATH=$(echo "$link_match" | awk -F'][(]' '{print $2}' | awk -F'[)]' '{print $1}')

    # Пропускаем внешние URL — они не должны проверяться как wiki-ссылки
    if echo "$TARGET_PATH" | grep -qE '^https?://|^mailto:'; then
      VALID_LINKS=$((VALID_LINKS + 1))
      continue
    fi
    if [ -z "$TARGET_PATH" ]; then
      continue
    fi

    # Проверяем существование целевого файла относительно wiki_root
    TARGET_FULL="$WIKI_DIR/$TARGET_PATH"
    if [ ! -f "$TARGET_FULL" ]; then
      BROKEN_LINKS+=("$file:$link_match -> $TARGET_PATH (not found)")
    else
      VALID_LINKS=$((VALID_LINKS + 1))
    fi
  done < <(grep -oE '\[[^]]+\]\([^)]+\)|\[\[[^]]+\]\]' "$file" 2>/dev/null || true)

done < <(find "$WIKI_DIR" -name "*.md" -type f 2>/dev/null || true)

echo "[*] Total links scanned: $TOTAL_LINKS, Valid: $VALID_LINKS" >&2

if [ ${#BROKEN_LINKS[@]} -gt 0 ]; then
  echo "[!] Broken links found (${#BROKEN_LINKS[@]}):" >&2
  for bl in "${BROKEN_LINKS[@]}"; do
    echo "    $bl" >&2
  done >&2
  exit 1
fi

echo "[✓] All internal links are valid" >&2
exit 0
