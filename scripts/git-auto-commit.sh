#!/usr/bin/env bash
# git-auto-commit.sh — Harness-independent auto-commit for wiki changes
# Emulates claude-obsidian's PostToolUse hook without harness dependency
# Safe to call after any Write/Edit that touches wiki/, .raw/, or .vault-meta/

set -euo pipefail

# Safety: no-op if not in a git repo
[ -d .git ] || exit 0

# Respect user override via flag file
if [ -f .vault-meta/auto-commit.disabled ]; then
  exit 0
fi

# Respect concurrency via wiki-lock (if available)
if [ -x scripts/wiki-lock.sh ]; then
  LOCK_LIST=$(bash scripts/wiki-lock.sh list 2>/dev/null) || {
    mkdir -p .vault-meta
    printf '%s git-auto-commit: wiki-lock failed; skipped\n' \
      "$(date '+%Y-%m-%dT%H:%M:%SZ')" >> .vault-meta/hook.log
    exit 0
  }
  [ -n "$LOCK_LIST" ] && exit 0   # another writer active — skip safely
fi

# Stage only wiki paths (never project junk or raw/)
git add -- wiki/ 2>/dev/null || exit 0

# Only commit if there are changes in wiki/ (avoid empty commits)
if git diff --cached --quiet --wiki/; then
  # No changes — skip commit silently
  exit 0
fi

git commit -m "wiki: auto-commit $(date '+%Y-%m-%d %H:%M')" -- wiki/ 2>/dev/null || true

exit 0
