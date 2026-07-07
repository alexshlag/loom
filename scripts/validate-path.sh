#!/usr/bin/env bash
set -euo pipefail
# validate-path.sh — Guardrails: blocks direct edits to protected zones
# Called before any edit/write on wiki files.
# Usage: ./scripts/validate-path.sh <path/to/file.md>

PATH_TO_CHECK="$1"

if [ -z "$PATH_TO_CHECK" ]; then
  echo "Usage: validate-path.sh <path>" >&2
  exit 1
fi

# Protected zones — meta/ is read-only, raw/ must be write via capture only
PROTECTED_PATTERNS=("meta/")
ALLOWED_WRITE_ZONES=("raw/corrected/" "wiki/" "tracking/")

for PATTERN in "${PROTECTED_PATTERNS[@]}"; do
  # Prefix-only match — prevents bypass via e.g. 'some-meta/file.md'
  if [[ "$PATH_TO_CHECK" == "$PATTERN"* ]]; then
    echo "⛔ BLOCKED: '$PATH_TO_CHECK' falls within protected zone (matches '$PATTERN')" >&2
    exit 1
  fi
done

# Write validation — check path is in allowed zones
for ZONE in "${ALLOWED_WRITE_ZONES[@]}"; do
  if [[ "$PATH_TO_CHECK" == "$ZONE"* ]]; then
    # Path starts with allowed zone prefix — safe to edit
    exit 0
  fi
done

# If path doesn't match any allowed zone, block it (except read operations)
echo "⛔ BLOCKED: '$PATH_TO_CHECK' is not in an allowed write zone" >&2
exit 1
exit 0
