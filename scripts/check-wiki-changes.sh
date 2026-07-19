#!/usr/bin/env bash
set -euo pipefail
# check-wiki-changes.sh — Detect wiki changes, return JSON
# Exit 0 with JSON if changes, 1 otherwise

[ -d .git ] || exit 1
[ -d wiki ] || exit 1

CHANGED=$(git diff --name-only HEAD 2>/dev/null | grep '^wiki/' || true)
if [ -z "$CHANGED" ]; then
    echo '{"needs_update":false}'
    exit 1
fi

CHANGED_JSON=$(printf '%s\n' "$CHANGED" | while IFS= read -r f; do printf '"%s",' "$f"; done | sed 's/,$/]/; s/^/[/')

# Build a concise summary string (for potential future use)
SUMMARY=$(echo "$CHANGED" | tr '\n' ', ' | sed 's/, $//')

cat << EOF
{
  "needs_update": true,
  "modified": $CHANGED_JSON,
  "summary": "$SUMMARY"
}
EOF
exit 0
