#!/usr/bin/env bash
# utilities/common.sh — Shared utility functions for all scripts

log_error() {
    local msg="$1"
    echo "[!] [ERROR] $msg" >&2
}

log_warn() {
    local msg="$1"
    echo "[*] [WARN] $msg" >&2
}

# Run command safely, capture output and exit code without aborting on set -e
# Usage: safe_run "command args" varname [allowed_exit_codes_comma_separated]
# Example: safe_run "./script.sh" result_var "0 1" allows both codes
safe_run() {
    local cmd="$1"
    local varname="$2"
    
    # Execute command, capture both stdout and stderr
    local output=""
    local exit_code=0
    output=$(bash -c "$cmd" 2>&1) || exit_code=$?
    
    shift 2
    
    # Parse allowed codes (space or comma separated)
    local allowed_codes="$*"
    if [ -z "$allowed_codes" ]; then
        allowed_codes="0"  # default: only allow success
    fi
    
    # Check if exit code is in allowed list
    local match=false
    for allowed in $(echo "$allowed_codes" | tr ',;' ' '); do
        if [ "$exit_code" -eq "$allowed" ] 2>/dev/null; then
            match=true
            break
        fi
    done
    
    # Report error only when exit code is not allowed
    if ! $match; then
        log_error "Command exited with code $exit_code (allowed: $allowed_codes): $(echo "$output" | head -1)"
    fi
    
    # Assign output to caller's variable using nameref
    local -n ref=$varname
    ref="$output"
}
