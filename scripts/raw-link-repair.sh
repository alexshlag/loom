#!/usr/bin/env bash
# raw-link-repair.sh — Convert relative markdown links in raw GitHub sources to permalinks
# Usage: ./scripts/raw-link-repair.sh [--dry-run] [raw_dir]

set -euo pipefail

DRY_RUN=false
RAW_DIR="raw"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        *) RAW_DIR="$1"; shift ;;
    esac
done

RAW_DIR="$(cd "$(dirname "$RAW_DIR")" && pwd)/$(basename "$RAW_DIR")"

echo "=== Raw Link Repair ==="
[[ "$DRY_RUN" == true ]] && echo "[*] Mode: DRY RUN"
echo "[*] Scanning: $RAW_DIR"

# Call Python script directly (not via heredoc)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/raw-link-repair.py" "$RAW_DIR" "$DRY_RUN"
