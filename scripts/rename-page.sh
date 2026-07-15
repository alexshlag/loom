#!/usr/bin/env bash
# rename-page.sh <old_path> <new_path>
# Renames a wiki page and updates all internal references

set -euo pipefail

OLD_PATH=$1
NEW_PATH=$2

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
WIKI_ROOT=$(dirname "$OLD_PATH_ABS")

echo "Renaming: $OLD_PATH -> $NEW_PATH"
echo "Wiki root: $WIKI_ROOT"

# 1. Check if old path exists
if [ ! -f "$OLD_PATH_ABS" ]; then
    echo "Error: Source path does not exist: $OLD_PATH_ABS"
    exit 1
fi

# 2. Physical rename
mv "$OLD_PATH_ABS" "$NEW_PATH_ABS"
echo "Renamed file successfully"

# 3. Global replacement of wiki-relative paths in the entire wiki directory
if [ -d "$WIKI_ROOT" ]; then
    echo "Updating references in $WIKI_ROOT..."
    find "$WIKI_ROOT" -type f -name "*.md" -exec sed -i "s|${OLD_PATH}|${NEW_PATH}|g" {} \; 2>/dev/null || true
fi

echo "Done. New path: $NEW_PATH_ABS"
