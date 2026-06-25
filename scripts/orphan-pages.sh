#!/usr/bin/env bash
# orphan-pages.sh — находит страницы wiki без входящих ссылок (orphan pages)
# Usage: ./scripts/orphan-pages.sh [wiki_dir] [backlinks_json]
# Exit code: 0 = no orphans, 1 = orphans found

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
WIKI_DIR="${1:-$PROJECT_ROOT/wiki}"
BACKLINKS_JSON="${2:-$PROJECT_ROOT/meta/backlinks.json}"

echo "[*] Checking for orphan pages..." >&2

# Считаем входящие бэклинки для каждого файла
ORPHANS=()
while IFS= read -r file; do
  REL_PATH="${file#$WIKI_DIR/}"

  # Ищем все страницы, которые ссылаются на эту
  BACKLINK_COUNT=$(grep -rl "(\[$REL_PATH\)" "$WIKI_DIR/" --include="*.md" 2>/dev/null | wc -l || true)

  if [ "$BACKLINK_COUNT" -eq 0 ]; then
    ORPHANS+=("$file")
  fi
done < <(find "$WIKI_DIR" -name "*.md" -type f 2>/dev/null || true)

if [ ${#ORPHANS[@]} -gt 0 ]; then
  echo "[!] Orphan pages found (${#ORPHANS[@]}):" >&2
  for orphan in "${ORPHANS[@]}"; do
    REL_PATH="${orphan#$WIKI_DIR/}"
    echo "    $REL_PATH (0 backlinks)" >&2
  done >&2

  echo "[*] Suggestion: add backlink from related entity/concept page" >&2
  exit 1
fi

echo "[✓] No orphan pages found" >&2
exit 0
