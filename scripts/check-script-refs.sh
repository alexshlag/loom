#!/usr/bin/env bash
# check-script-refs.sh — Validate all script paths referenced in rules/*.json and process-*.json
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/.."

TMPDIR_WORK=$(mktemp -d)
trap 'rm -rf "$TMPDIR_WORK"' EXIT

REFS_FILE="$TMPDIR_WORK/refs.txt"
> "$REFS_FILE"

# Collect all script refs from rules/*.json and process-*.json
find "$PROJECT_DIR/rules" "$PROJECT_DIR" -maxdepth 1 -name '*.json' -type f | while read -r f; do
  grep -oP 'scripts/[a-zA-Z0-9_./-]+' "$f" 2>/dev/null || true
done > "$REFS_FILE"

UNIQUE_REFS=$(sort -u "$REFS_FILE" | sed 's/\.$//')
REF_COUNT=$(echo "$UNIQUE_REFS" | grep -c . || echo 0)

echo "=== Script Reference Checker ==="
echo "Scanned: rules/*.json, process-*.json"
echo "Found $REF_COUNT unique script references"
echo ""

MISSING=0
FOUND=0

while IFS= read -r ref; do
  [[ -z "$ref" ]] && continue
  filepath="$PROJECT_DIR/$ref"
  if [[ -f "$filepath" ]]; then
    echo "✓ $ref"
    FOUND=$((FOUND + 1))
  else
    echo "✗ $ref (MISSING)"
    MISSING=$((MISSING + 1))
  fi
done <<< "$UNIQUE_REFS"

echo ""
echo "=== Summary ==="
echo "Found: $FOUND"
echo "Missing: $MISSING"

if [[ $MISSING -gt 0 ]]; then
  echo ""
  echo "ERROR: $MISSING missing script reference(s)."
  echo ""
  echo "Fix options:"
  echo "  1. Create missing script(s) in scripts/ directory"
  echo "  2. Update rules/*.json or process-*.json with correct path"
  echo "  3. Remove unused references"
  exit 1
else
  echo "All script references are valid."
  exit 0
fi
