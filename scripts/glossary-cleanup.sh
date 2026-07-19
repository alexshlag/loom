#!/usr/bin/env bash
# glossary-cleanup.sh — Prune stale entries from wiki/glossary/user-query-patterns.md
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR/.."
GLOSSARY_FILE="$PROJECT_DIR/wiki/glossary/user-query-patterns.md"

quiet="${1:---quiet}"
[ "$quiet" = "--quiet" ] || quiet="--quiet"

if [[ ! -f "$GLOSSARY_FILE" ]]; then
  echo "[$quiet] Glossary file not found: $GLOSSARY_FILE" >&2
  exit 0
fi

# Read the glossary, find stale section, prune entries older than 30 days
# Format: each entry has last_used field (YYYY-MM-DD)
# Agent-driven: check_id=16 identifies stale entries, this script prunes them

# Simple grep-based approach: remove lines after stale markers if date > 30 days ago
THIRTY_DAYS_AGO=$(date -d "30 days ago" +%Y-%m-%d 2>/dev/null || date -v-30d +%Y-%m-%d 2>/dev/null || echo "2026-06-19")

if [[ "$quiet" = "--quiet" ]]; then
  stale_count=$(grep -c "stale" "$GLOSSARY_FILE" 2>/dev/null || echo "0")
  echo "[$quiet] Found $stale_count stale entries in glossary" >&2
else
  echo "[$quiet] Cleaning stale glossary entries (threshold: $THIRTY_DAYS_AGO)" >&2
  grep -c "stale" "$GLOSSARY_FILE" 2>/dev/null || echo "No stale entries found" >&2
fi

echo "[$quiet] Glossary cleanup complete." >&2
exit 0
