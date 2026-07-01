#!/usr/bin/env bash
# check-wiki-changes.sh — Harness-independent session hygiene at end of wiki work
# Emulates claude-obsidian's Stop hook: detects wiki changes and guides hot.md update
# Returns 0 if changes detected (guide agent to update), 1 otherwise

[ -d .git ] || exit 1
[ -d wiki ] || exit 1

CHANGED=$(git diff --name-only HEAD 2>/dev/null | grep '^wiki/' || true)
[ -z "$CHANGED" ] && exit 1

cat << PROMPT
=== WIKI CHANGES DETECTED ===
Modified:
$CHANGED

Update wiki/hot.md with a summary (under 500 words):
- Last Updated, Key Recent Facts, Recent Changes, Active Threads
=== END PROMPT ===
PROMPT

exit 0
