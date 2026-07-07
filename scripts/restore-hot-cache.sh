#!/usr/bin/env bash
set -euo pipefail
# Graceful harness hook: exits 1 if wiki/hot.md missing (no vault = no-op)
#
# restore-hot-cache.sh — Harness-independent context restoration after compaction
# Emulates claude-obsidian's PostCompact hook: restores wiki/hot.md lost during compact
# Returns 1 if no vault detected (graceful no-op), 0 otherwise

[ -f wiki/hot.md ] || exit 1

echo "=== HOT CACHE RESTORED ==="
cat wiki/hot.md
echo "=== END HOT CACHE ==="

exit 0
