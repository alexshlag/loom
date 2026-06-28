#!/usr/bin/env bash
# scripts/lib.sh — Shared utilities for all wiki scripts
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ─── Atomic Write Pattern ────────────────────────────────
# Write to .tmp → mv (atomic) to prevent corruption on crash.
# Usage: atomic_write "target_file" <content_or_pipe>
# Example: cat source.txt | atomic_write target.json
atomic_write() {
    local target="$1"
    local tmp="${target}.tmp.$$"

    # Copy to temp file (tee preserves stdin)
    tee "$tmp" > /dev/null || { rm -f "$tmp"; return 1; }

    # Atomic move
    if ! mv "$tmp" "$target" 2>/dev/null; then
        # Failed — cleanup
        rm -f "$tmp"
        echo "[!] atomic_write: failed to write $target" >&2
        return 1
    fi
}

# ─── Atomic Write with Content ───────────────────────────
# Usage: atomic_write_content "file" "content"
atomic_write_content() {
    local target="$1"
    local content="$2"
    local tmp="${target}.tmp.$$"

    if ! printf '%s' "$content" > "$tmp"; then
        rm -f "$tmp"
        echo "[!] atomic_write_content: failed to write $target" >&2
        return 1
    fi

    if ! mv "$tmp" "$target" 2>/dev/null; then
        rm -f "$tmp"
        echo "[!] atomic_write_content: failed to write $target" >&2
        return 1
    fi
}

# ─── Cleanup on Exit ─────────────────────────────────────
# Usage: cleanup_temp_files in trap handler
_cleanup_patterns=()
cleanup_add() {
    _cleanup_patterns+=("$1")
}

atomic_write_with_cleanup() {
    local target="$1"
    shift
    local tmp="${target}.tmp.$$"

    # Set up trap for this temp file
    cleanup_add "$tmp"

    # Copy to temp (tee preserves stdin)
    tee "$tmp" > /dev/null || { rm -f "$tmp"; return 1; }

    if ! mv "$tmp" "$target" 2>/dev/null; then
        rm -f "$tmp"
        echo "[!] atomic_write: failed to write $target" >&2
        return 1
    fi

    # Remove from cleanup list (already written successfully)
    local new_patterns=()
    for p in "${_cleanup_patterns[@]}"; do
        if [ "$p" != "$tmp" ]; then
            new_patterns+=("$p")
        fi
    done
    _cleanup_patterns=("${new_patterns[@]}")
}

# ─── Error Logging Standard ──────────────────────────────
# Usage: log_error "level" "message"
log_error() {
    local level="${1:-ERROR}"
    local msg="$2"
    local ts
    ts=$(date -u '+%Y-%m-%dT%H:%M:%SZ')
    echo "$ts | [$level] $msg" >&2
}

# ─── Safe JSON Generation ────────────────────────────────
# Usage: generate_json "key1" "value1" "key2" "value2" ... > output.json
generate_json() {
    local -a keys=()
    local -a vals=()
    
    while [[ $# -gt 0 ]]; do
        keys+=("$1")
        shift
        vals+=("$1")
        shift
    done
    
    python3 -c "
import json, sys
data = {}
for k, v in zip(sys.argv[1::2], sys.argv[2::2]):
    data[k] = v
print(json.dumps(data, indent=2, ensure_ascii=False))
" "${keys[@]}" "${vals[@]}"
}
