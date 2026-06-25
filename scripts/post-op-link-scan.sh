#!/usr/bin/env bash
# post-op-link-scan.sh — сканирует wiki на сломанные ссылки после rename/move/new page
# Usage: ./scripts/post-op-link-scan.sh <old_path_or_name> [max_matches]
# Exit code: 0 = no broken links, 1 = broken links found

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
WIKI_DIR="$PROJECT_ROOT/wiki"

TARGET_PATTERN="${1:?Usage: post-op-link-scan.sh <pattern> [max_matches]}"
MAX_MATCHES="${2:-50}"

# Сканируем все wiki-файлы на упоминания старого пути / имени
echo "[*] Scanning wiki for references to: $TARGET_PATTERN" >&2

BROKEN_LINKS=()
while IFS= read -r line; do
  BROKEN_LINKS+=("$line")
done < <(grep -rn "$TARGET_PATTERN" "$WIKI_DIR/" --include="*.md" -m "$MAX_MATCHES" 2>/dev/null || true)

if [ ${#BROKEN_LINKS[@]} -eq 0 ]; then
  echo "[✓] No broken links found for: $TARGET_PATTERN" >&2
  exit 0
fi

echo "[!] Broken links found:" >&2
for link in "${BROKEN_LINKS[@]}"; do
  echo "    $link" >&2
done >&2

# Auto-fixable флаг (agent применяет edit вручную или через скрипт)
AUTO_FIXABLE=0
while IFS= read -r line; do
  FILE_PATH=$(echo "$line" | cut -d':' -f1)

  # Проверяем, есть ли markdown-ссылка с old_path в этой строке
  if echo "$line" | grep -qE "\(\[.*\]($TARGET_PATTERN)\)" || echo "$line" | grep -qF "[$TARGET_PATTERN]"; then
    AUTO_FIXABLE=$((AUTO_FIXABLE + 1))
    # Agent должен применить sed edit: sed -i 's|old_path|new_path|g' $FILE_PATH
    echo "[✓] Auto-fixable: $FILE_PATH" >&2
  fi
done < "${BROKEN_LINKS[@]}"

echo "[*] Auto-fixable links: $AUTO_FIXABLE" >&2

if [ ${#BROKEN_LINKS[@]} -gt 0 ]; then
  exit 1
fi
