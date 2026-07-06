#!/usr/bin/env bash
# raw-correct.sh — Safe write wrapper for agent to create corrected copies in raw/corrected/
# Purpose: Agent writes processed/corrected markdown files via this script (never direct to protected zones)
# Usage: ./scripts/raw-correct.sh --add "path" content...

set -euo pipefail

WIKI_DIR="${WIKI_DIR:-wiki/}"
CORRECTED_BASE="raw/corrected/"

log_info() { echo "[INFO] $(date '+%Y-%m-%d %H:%M') $1"; }
log_error() { echo "[ERROR] $(date '+%Y-%m-%d %H:%M') $1" >&2; }

# Parse arguments
ACTION=""
TARGET_PATH=""
CONTENT_INPUT=""
IS_JSON=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --add)
            ACTION="write"
            shift
            # Next arg is the target path
            if [[ $# -gt 0 && ! "$1" =~ ^-- ]]; then
                TARGET_PATH="$1"
                shift
            else
                log_error "Missing file path after --add"
                exit 1
            fi
            ;;
        --json)
            IS_JSON=true
            ;;
        --help|-h)
            echo "Usage: $0 --add <path> [content...]"
            echo "Writes corrected/processed files to raw/corrected/"
            echo "Options:"
            echo "  --json   Validate JSON format before writing"
            exit 0
            ;;
        *)
            if [[ -z "$CONTENT_INPUT" ]]; then
                CONTENT_INPUT="$1"
            else
                CONTENT_INPUT="$CONTENT_INPUT $1"
            fi
            shift
            ;;
    esac
done

if [[ -z "$ACTION" || -z "$TARGET_PATH" ]]; then
    log_error "Usage: $0 --add <path> [content...]"
    exit 1
fi

# Validate path starts with raw/corrected/ prefix
if [[ ! "$TARGET_PATH" =~ ^raw/corrected/.*\.((md|json|txt))$ ]]; then
    log_error "Invalid path: '$TARGET_PATH' — must start with $CORRECTED_BASE and end with .md/.json/.txt"
    exit 1
fi

# Ensure directory exists
mkdir -p "$(dirname "$TARGET_PATH")"

# Validate JSON format if --json flag is set
if [[ "$IS_JSON" == true ]]; then
    # Read content from stdin or argument
    if [[ -n "$CONTENT_INPUT" ]]; then
        echo "$CONTENT_INPUT" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null || {
            log_error "Invalid JSON format in content"
            exit 1
        }
    else
        cat | python3 -m json.tool > /dev/null 2>&1 || {
            log_error "Invalid JSON format (from stdin)"
            exit 1
        }
    fi
fi

# Atomic write to temp file, then move into place
TMP_FILE=$(mktemp "${TARGET_PATH}.tmp.XXXXXX")
trap 'rm -f "$TMP_FILE"' EXIT

if [[ -n "$CONTENT_INPUT" ]]; then
    printf '%s' "$CONTENT_INPUT" > "$TMP_FILE"
else
    cat > "$TMP_FILE"  # Read from stdin if no content argument provided
fi

# Validate written successfully
if [[ ! -s "$TMP_FILE" ]]; then
    log_error "Write failed — temp file is empty"
    exit 1
fi

# Move into place (atomic operation)
mv "$TMP_FILE" "${TARGET_PATH}"

log_info "Wrote corrected copy: $TARGET_PATH"
exit 0
