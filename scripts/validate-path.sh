#!/etc/profiles/per-user/andrew/bin/bash
# validate-path.sh — Guardrails: блокировка прямых изменений к protected zones
# Вызывается перед любым edit/write на файлах wiki.
# Usage: ./scripts/validate-path.sh <path/to/file.md>

PATH_TO_CHECK="$1"

if [ -z "$PATH_TO_CHECK" ]; then
  echo "Usage: validate-path.sh <path>" >&2
  exit 1
fi

# Protected zones — meta/ is read-only, raw/ must be write via capture only
PROTECTED_PATTERNS=("meta/")
ALLOWED_WRITE_ZONES=("raw/sources/" "wiki/")

for PATTERN in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$PATH_TO_CHECK" == *"$PATTERN"* ]]; then
    echo "⛔ BLOCKED: '$PATH_TO_CHECK' falls within protected zone (matches '$PATTERN')" >&2
    exit 1
  fi
done

# Path is safe to edit
exit 0
