#!/usr/bin/env bash
# date-consistency.sh — checks date consistency between frontmatter and "## Updated" sections
# Usage: ./scripts/date-consistency.sh [wiki_dir]
# Exit code: 0 = consistent, 1 = inconsistencies found

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
WIKI_DIR="${1:-$PROJECT_ROOT/wiki}"

echo "[*] Checking date consistency across wiki..." >&2

INCONSISTENCIES=()
CURRENT_YEAR=$(date +%Y)
MAX_AGE_YEARS=1

while IFS= read -r file; do
  # Read frontmatter and "## Updated" section
  FRONTMATTER_DATE=""
  UPDATE_DATES=""

  # Extract date: from first 20 lines
  FRONTMATTER_DATE=$(head -n 20 "$file" | grep "^date:" | head -1 | sed 's/date: *//') || true

  if [ -z "$FRONTMATTER_DATE" ]; then
    INCONSISTENCIES+=("$file: missing date in frontmatter")
    continue
  fi

  # Check that the year in date matches current (not older than MAX_AGE_YEARS)
  YEAR=$(echo "$FRONTMATTER_DATE" | grep -oE '[0-9]{4}') || true

  if [ -n "$YEAR" ] && [ "$CURRENT_YEAR" -gt $((YEAR + MAX_AGE_YEARS)) ]; then
    INCONSISTENCIES+=("$file: date year $YEAR is older than $MAX_AGE_YEARS years (current: $CURRENT_YEAR)")
  fi

  # Extract dates from "## Updated" section
  UPDATE_DATES=$(grep -A10 "^## Updated\|^## Updated" "$file" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' || true)

  for update_date in $UPDATE_DATES; do
    UPDATE_YEAR=$(echo "$update_date" | grep -oE '^[0-9]{4}') || true
    if [ -n "$FRONTMATTER_DATE" ] && [ -n "$UPDATE_YEAR" ]; then
      # Frontmatter year and update year should match or be older
      FM_YEAR=$(echo "$FRONTMATTER_DATE" | grep -oE '^[0-9]{4}') || true
      if [ -n "$FM_YEAR" ] && [ "$UPDATE_YEAR" -lt "$FM_YEAR" ]; then
        INCONSISTENCIES+=("$file: update date $update_date is older than frontmatter date $FRONTMATTER_DATE")
      fi
    fi
  done

done < <(find "$WIKI_DIR" -name "*.md" -type f 2>/dev/null || true)

if [ ${#INCONSISTENCIES[@]} -gt 0 ]; then
  echo "[!] Date inconsistencies found (${#INCONSISTENCIES[@]}):" >&2
  for issue in "${INCONSISTENCIES[@]}"; do
    echo "    $issue" >&2
  done >&2

  # Suggest fix for inconsistencies
  echo "[*] Suggestion: review and correct dates using current system date" >&2
  exit 1
fi

echo "[✓] All dates are consistent" >&2
exit 0
