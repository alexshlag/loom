#!/usr/bin/env bash
# load-hot-cache.sh — Harness-independent session bootstrap
# Emulates claude-obsidian's SessionStart hook: loads wiki/hot.md at session start
# Returns 1 if no vault detected (graceful no-op), 0 otherwise

[ -f wiki/hot.md ] || exit 1

echo "=== HOT CACHE ==="
cat wiki/hot.md
echo "=== END HOT CACHE ==="

exit 0
