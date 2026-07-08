#!/usr/bin/env bash
# orphan-report.sh — Detects orphan pages, suggests top crosslink candidates (score ≥5), outputs JSON report
# Usage: ./orphan-report.sh [--quiet] [wiki_dir]
# Output: JSON to stdout with orphans[], suggestions[]; stderr human-readable summary
# Note: Does NOT auto-fix. Returns structured data for agent review.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
WIKI_DIR="${1:-$PROJECT_ROOT/wiki}"
BACKLINKS_JSON="$PROJECT_ROOT/meta/backlinks.json"
QUIET=false
[[ "${2:-}" == "--quiet" ]] && QUIET=true

export WIKI_DIR BACKLINKS_JSON SCRIPT_DIR PROJECT_ROOT QUIET
python3 "$SCRIPT_DIR/../scripts/_orphan_report_impl.py"

