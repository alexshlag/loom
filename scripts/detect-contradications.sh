#!/usr/bin/env bash
# detect-contradications.sh — Soft scan for potential contradictions in wiki
# Parses frontmatter dates + key facts, builds comparison matrix
# 
# Usage: ./scripts/detect-contradications.sh [--quiet]
# Output: JSON on stdout, human-readable summary on stderr

# Note: not using set -e — exit code propagated from python3

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
WIKI_DIR="${PROJECT_ROOT}/wiki"
QUIET=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --quiet) QUIET=true; shift;;
        *) shift;;
    esac
done

export WIKI_DIR QUIET
set +e
cd "$(dirname "$0")/.."
python3 scripts/_detect_contradictions.py
exit $?
