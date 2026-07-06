#!/usr/bin/env bash
# scripts/filename-audit.sh — Scan wiki for filename naming violations
# Usage: ./filename-audit.sh [--help] [--fix-suggestions] [wiki_dir]
# Exit code: 0 = no violations found, 1 = violations detected

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/.."
WIKI_DIR="${2:-$PROJECT_ROOT/wiki}"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h) echo "Usage: $0 [--fix-suggestions] [wiki_dir]" && exit 0;;
    *) WIKI_DIR="$1"; shift;;
  esac
done

# --- Helper functions ---

# Extract project prefix from tags or related files
detect_project_from_file() {
  local file="$1"
  
  # Try to find project from tags first (e.g., symfony-messenger, doctrine-orm)
  local detected=$(grep "^tags:" "$file" 2>/dev/null | grep -oE 'symfony|doctrine|easyadmin' | head -1) || true
  
  if [[ -n "$detected" ]]; then
    echo "$detected"
    return
  fi
  
  # Try to find project from related files (e.g., entities/symfony.md)
  detected=$(grep "^related:" "$file" 2>/dev/null | grep -oE 'symfony' | head -1) || true
  
  if [[ -n "$detected" ]]; then
    echo "$detected"
    return
  fi
  
  # Cannot determine prefix — skip (false positive prevention)
  echo ""
}

# --- Main audit logic ---

VIOLATIONS_JSON="[]"
TOTAL_VIOLATIONS=0

echo "[*] Filename naming audit — ${WIKI_DIR#/}" >&2

# --- Scan wiki/concepts/ ---
if [[ -d "${WIKI_DIR}/concepts" ]]; then
  for file in "${WIKI_DIR}/concepts/"*.md; do
    [ -f "$file" ] || continue
    
    filename=$(basename "$file")
    
    # Skip exception files (truly abstract concepts)
    if [[ "$filename" == cache-system.md ]] || [[ "$filename" == hexagonal-architecture.md ]] || [[ "$filename" == doctrine-orm.md ]]; then
      continue
    fi
    
    # Skip files that already have a known project prefix
    if [[ "$filename" == symfony-* ]] || [[ "$filename" == doctrine-* ]] || [[ "$filename" == easyadmin-* ]]; then
      continue
    fi
    
    # Detect what project this file belongs to
    detected_project=$(detect_project_from_file "$file")
    
    if [[ -n "$detected_project" ]]; then
      echo "VIOLATION: ${filename} (tags/related contain '${detected_project}' but no prefix)" >&2
      
        VIOLATIONS_JSON=$(echo "${VIOLATIONS_JSON}" | python3 -c "
import sys,json
arr = json.loads(sys.stdin.read())
obj = {\"file\": \"concepts/${filename}\", \"severity\": \"HIGH\", \"reason\": \"tags/related contain '${detected_project}' but filename lacks prefix\", \"suggested_path\": \"${detected_project}-${filename}\"}
arr.append(obj)
print(json.dumps(arr))" 2>/dev/null) || VIOLATIONS_JSON="[]"
      TOTAL_VIOLATIONS=$((TOTAL_VIOLATIONS + 1))
    fi
    
  done
fi

# --- Output JSON results ---
echo "---"
echo "${VIOLATIONS_JSON}" | python3 -c "import sys,json; d=json.loads(sys.stdin.read()); print(f'VIOLATIONS: {len(d)}'); [print(json.dumps(x)) for x in d]" 2>/dev/null || echo "{}"

# Return exit code: 0 = no violations, 1 = violations found (always max 1)
if [[ $TOTAL_VIOLATIONS -gt 0 ]]; then
  exit 1
fi
exit 0
