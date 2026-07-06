#!/usr/bin/env bash
set -euo pipefail

# Export skill from wiki/skills/ → .pi/skills/<skill-name>/SKILL.md
# Usage: ./scripts/export-skill.sh <skill-file-name-without-extension> [destination-dir]

SRC_DIR="wiki/skills"
DEST_DIR="${2:-.pi/skills}"
FILE_ARG="$1"

## Help
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  echo "Usage: $0 <skill-name> [destination-dir]"
  echo "Exports wiki skill to SKILL.md format (.pi compatible)"
  exit 0
fi

# Validate input
if [[ -z "${FILE_ARG:-}" ]]; then
  echo "Error: skill name required" >&2
  exit 1
fi

SRC_FILE="${SRC_DIR}/${FILE_ARG}.md"
DEST_SKILL_DIR="${DEST_DIR}/${FILE_ARG}"
DEST_FILE="${DEST_SKILL_DIR}/SKILL.md"

# Guardrails
if [[ ! -f "$SRC_FILE" ]]; then
  echo "Error: source file not found → $SRC_FILE" >&2
  exit 1
fi

# Create dest dir
mkdir -p "$(dirname "$DEST_FILE")"

## Export logic: strip frontmatter, add .pi headers
{
  echo "---"
  echo "name: ${FILE_ARG}"
  echo "description: $(grep '^# Skill:' "$SRC_FILE" | head -1 | sed 's/^# Skill: //')"
  echo "version: 1.0.0"
  echo "---"
  echo ""

  # Extract sections from wiki format → clean markdown for SKILL.md
  grep '^##' "$SRC_FILE" || true

} > "${DEST_FILE}.tmp"

mv "${DEST_FILE}.tmp" "$DEST_FILE"

echo "Exported: ${DEST_FILE}"
exit 0
