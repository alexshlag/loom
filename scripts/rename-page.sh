#!/usr/bin/env bash
# rename-page.sh [<--log> <tie_breaking_level> <reason>] <old_path> <new_path>
# Renames a wiki page and updates all internal references
#
# Options:
#   --log <level> <reason>  Append # Renamed section with collision resolution metadata
#   --help                  Show help and exit
#
# Usage:
#   ./scripts/rename-page.sh <old_path> <new_path>                        # basic rename
#   ./scripts/rename-page.sh --log level_1_primary_entity "symfony wins" <old> <new>
#
# When --log is used, appends after frontmatter ---:
#   ## Renamed [YYYY-MM-DD]
#   Renamed from `<old>.md` to `<new>.md` — collision resolution: <reason> (tie-breaking: <level>)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/.."

LOG_MODE=false
TIE_BREAKING_LEVEL=""
REASON=""

# Parse arguments
POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --log)
            LOG_MODE=true
            TIE_BREAKING_LEVEL="${2:-unknown}"
            REASON="${3:-unknown}"
            shift 3
            ;;
        --help)
            head -15 "$0" | grep '^#' | sed 's/^# //'
            exit 0
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

if [[ ${#POSITIONAL[@]} -lt 2 ]]; then
    echo "Error: rename-page.sh requires <old_path> <new_path>"
    echo "Usage: $0 [--log <level> <reason>] <old_path> <new_path>"
    exit 1
fi

OLD_PATH="${POSITIONAL[0]}"
NEW_PATH="${POSITIONAL[1]}"

# Resolve to absolute paths
if [[ "$OLD_PATH" == /* ]]; then
    OLD_PATH_ABS="$OLD_PATH"
else
    OLD_PATH_ABS="$(cd "$(dirname "$OLD_PATH")" && pwd)/$(basename "$OLD_PATH")"
fi

if [[ "$NEW_PATH" == /* ]]; then
    NEW_PATH_ABS="$NEW_PATH"
else
    NEW_PATH_ABS="$(cd "$(dirname "$NEW_PATH")" && pwd)/$(basename "$NEW_PATH")"
fi

# Get the wiki root directory
WIKI_ROOT="$(dirname "$OLD_PATH_ABS")"

echo "Renaming: $OLD_PATH -> $NEW_PATH"
echo "Wiki root: $WIKI_ROOT"

# 0. Check if old path exists
if [ ! -f "$OLD_PATH_ABS" ]; then
    echo "Error: Source path does not exist: $OLD_PATH_ABS"
    exit 1
fi

# 1. Physical rename
mv "$OLD_PATH_ABS" "$NEW_PATH_ABS"
echo "Renamed file successfully"

# 2. Update all internal wiki-relative references
echo "Updating references across wiki..."
OLD_BASENAME="$(basename "$OLD_PATH")"
NEW_BASENAME="$(basename "$NEW_PATH")"

# Find and replace wiki-relative paths in all markdown files
find "$WIKI_ROOT/.." -type f -name "*.md" -not -path "$NEW_PATH_ABS" -exec sed -i "s|\[wiki/${OLD_BASENAME}\]|\[wiki/${NEW_BASENAME}\]|g" {} + 2>/dev/null || true
find "$WIKI_ROOT/.." -type f -name "*.md" -not -path "$NEW_PATH_ABS" -exec sed -i "s|${OLD_BASENAME}\.md|${NEW_BASENAME}.md|g" {} + 2>/dev/null || true

echo "References updated"

# 3. Append # Renamed section (if --log mode)
if [[ "$LOG_MODE" == true ]]; then
    CURRENT_DATE="$(date +%Y-%m-%d)"
    RENAMED_SECTION="## Renamed [${CURRENT_DATE}]
Renamed from \`${OLD_BASENAME}\` to \`${NEW_BASENAME}\` — collision resolution: ${REASON} (tie-breaking: ${TIE_BREAKING_LEVEL})"

    # Insert after frontmatter closing --- (before first # heading or content)
    # Use python for reliable YAML frontmatter detection
    python3 -c "
import re, sys

filepath = sys.argv[1]
section = sys.argv[2]

with open(filepath, 'r') as f:
    content = f.read()

# Find frontmatter end (--- on its own line after YAML)
fm_end = re.search(r'\n---\s*\n', content)
if not fm_end:
    # No frontmatter found, append at end
    content = content.rstrip() + '\n\n' + section + '\n'
else:
    # Insert after frontmatter closing
    pos = fm_end.end()
    content = content[:pos] + section + '\n' + content[pos:]

with open(filepath, 'w') as f:
    f.write(content)
" "$NEW_PATH_ABS" "$RENAMED_SECTION"
    echo "Appended # Renamed section: $TIE_BREAKING_LEVEL — $REASON"
fi

echo "Done. New path: $NEW_PATH_ABS"
