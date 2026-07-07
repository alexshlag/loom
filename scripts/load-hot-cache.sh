#!/usr/bin/env bash
set -euo pipefail
# Graceful harness hook: exits 1 if wiki/hot.md missing (no vault = no-op)
#
# load-hot-cache.sh — Harness-independent session bootstrap
# Emulates claude-obsidian's SessionStart hook: loads wiki/hot.md at session start
# Returns 1 if no vault detected (graceful no-op), 0 otherwise

[ -f wiki/hot.md ] || exit 1

echo "=== HOT CACHE ==="
cat wiki/hot.md
echo "=== END HOT CACHE ==="

exit 0
