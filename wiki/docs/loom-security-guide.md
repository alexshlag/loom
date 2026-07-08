---
tags: [Loomana, loom, security, privacy, data-protection, gitignore, credential-handling]
date: 2026-07-08
type: documentation
category: concept
aliases: [privacy, data-safety, source-protection]
sources: ["docs/security-guide.md", ".gitignore"]
related: ["wiki/docs/loom-getting-started", "wiki/docs/loom-architecture"]
---

# Security & Privacy Guide

Loomana is designed for **personal knowledge management** with private data. All your sources, notes, and research stay local — nothing is uploaded to the cloud or shared automatically. This guide covers how Loomana protects your data and what you should be aware of when using it.

---

## Data Privacy Overview

| Data Type | Where It Lives | Is It Committed? | Can AI Harness Read It? |
|-----------|---------------|------------------|------------------------|
| Raw sources (URLs, documents, text) | `raw/sources/` | ❌ Never — excluded by `.gitignore` | Only your active harness during a session |
| Wiki pages (structured knowledge) | `wiki/**/*.md` | ✅ Yes (if repo is public) | Anyone with access to committed wiki content |
| Metadata & indexes | `meta/**` | ❌ Never — auto-generated, excluded by `.gitignore` | Your harness only |
| Session memory | `working_memory.json`, `wiki/hot.md` | ❌ Not tracked in git | Only during active session |
| Git history | Committed wiki + docs | ✅ Yes (if repo is public) | Anyone who clones your repository |

**Key principle:** Private data lives in `raw/`. Public knowledge lives in `wiki/`. The `.gitignore` file prevents accidental commits of private data.

---

## What `.gitignore` Protects

Loomana's `.gitignore` blocks several categories from being committed:

### Raw Sources (`raw/**`)
All raw sources are excluded — documents you paste, URLs you fetch, files you upload. They never enter git history.

```bash
# ✅ Safe to add — won't be committed
echo "My research notes" > raw/sources/SRC-001/notes.md
```

### Metadata (`meta/**`)
Auto-generated indexes (registry.json, backlinks.json, search-index.json) are rebuilt fresh every time — they're never tracked.

### Agent Local Configs (`.pi/`, `.obsidian/`)
Machine-specific configurations that only matter on your local machine.

### OS / Editor Artifacts (`*.swp`, `__pycache__/`, `.DS_Store`)
Standard cleanup patterns to keep the repository clean across different operating systems and editors.

---

## Handling Sensitive Data

If your raw sources contain sensitive information (credentials, API keys, personal data), follow these rules:

### Before Adding a Source

1. **Strip sensitive content** before providing it to your agent
   ```bash
   # ❌ Don't paste: "My password is abc123"
   # ✅ Do: Remove credentials and other sensitive fields first
   ```

2. **Use redacted copies** for documents that contain private data
   - Create a clean copy (replace emails, phone numbers, addresses with placeholders)
   - Provide the sanitized version to your agent

### After Ingest

1. **Verify wiki pages don't leak raw content** — sometimes agents summarize and accidentally include sensitive fields from raw sources
2. **Check `wiki/index.md`** — summaries might reference specific details you wanted redacted
3. **Remove or replace** any accidental exposure in wiki pages before committing

### Git History Safety

If you accidentally committed a private file:

```bash
# Remove from git history immediately (before pushing)
git rm --cached raw/sources/leaked-file.md
git commit -m "fix | security: remove accidentally committed source"
git push --force-with-lease  # If already pushed, force-update remote
```

For commits that have already been pushed to a **public** repository, delete the file from git history entirely using `git filter-branch` or `BFG`. See [GitHub's cleaning repo guide](https://docs.github.com/en/authentication/keeping-accounts-and-data-private-removing-sensitive-data-in-a-commit).

---

## Working With Public Repositories

If your Loomana repository is public, be aware:

### What Others Can See
- All **committed wiki pages** — the knowledge graph you've built
- All **docs/** directory content — guides, architecture descriptions, scripts references
- Git history of commits and changes

### What They Cannot See
- Raw sources (`raw/` is never committed)
- Session memory (`working_memory.json`, `hot.md`)
- Metadata indexes (`meta/**`)
- Your local agent configuration (`.pi/`, `.obsidian/`)

### Recommendations for Public Repositories

| Practice | Why |
|----------|-----|
| Only commit sanitized wiki pages | Remove any private context that was used to build them |
| Use `.gitattributes` to auto-filter sensitive patterns on commit | Prevent accidental commits of credentials, keys, tokens |
| Regularly audit committed content with `git log -p --raw` | Spot any raw source data that somehow got committed |
| Consider a private fork for wiki + docs if you want full privacy | Public repo gets the schema/rules; private one keeps your knowledge graph |

---

## AI Harness Data Flow Awareness

When using an AI coding harness (Claude Code, Cursor, Pi, etc.), understand what it can see:

### What Your Harness Can Read
- Everything in the repository — `wiki/`, `docs/`, `rules/`, `scripts/`
- The raw sources you **explicitly provide** to it during a session
- Session memory files (`working_memory.json`, `hot.md`)

### What It Cannot Access (Unless You Tell It To)
- Files outside the repository directory
- Your system's private directories (`~/.ssh/`, `~/.gnupg/`, etc.)
- Network access — unless your harness has web_search or fetch capabilities enabled

### Session Data Is Ephemeral
The AI harness processes your sources and creates wiki pages in one session. Its conversation context is **temporary** — once the session ends, the harness doesn't retain your raw sources in memory (unless it's a long-running session with active context).

---

## Git Conventions for Safety

Loomana enforces specific git conventions to prevent accidental data leaks:

### Never Use `git add *`
Always stage files explicitly by category. This prevents accidentally adding untracked sensitive files:

```bash
# ✅ Correct — only wiki changes (no raw sources)
git add wiki/entities/*.md

# ❌ Dangerous — could include everything, including raw/ and temp files
git add *
```

### Dev Mode vs Wiki Mode
- **Wiki mode:** Only `wiki/*.md` changed → lightweight staging
- **Dev mode:** Scripts, rules, process files changed → explicit staging required + memory sync

See [`rules/git_conventions.json`](../rules/git_conventions.md) for full details. The agent reads this file before every commit to ensure correct behavior.

---

## Credential & Token Handling in Scripts

Loomana scripts **never** require or store credentials. They operate purely on local filesystem paths:

### Safe Patterns (What Loomana Uses)
- File path arguments passed as shell variables
- Read operations via `cat`, `awk`, `grep`, `jq` — all local
- Git commands with standard credential helpers (system-managed, not script-stored)

### Patterns to Avoid in Custom Scripts
```bash
# ❌ Never hardcode credentials in scripts
API_KEY="sk-abc123" curl -H "Authorization: $API_KEY" https://api.example.com

# ❌ Never store tokens in plain files
echo "$TOKEN" > ~/.looma-token.txt
```

---

## Audit Checklist

Run these periodically to ensure your data stays private:

| Check | Command | Frequency |
|-------|---------|-----------|
| Verify raw/ is not committed | `git ls-files raw/` (should be empty) | After every commit |
| Check for accidental commits of sensitive files | `git log --all --raw \| grep -E "(password|key|token)"` | Monthly |
| Review what's in git history vs local only | `git diff --cached --name-only` before committing | Every time you commit |
| Ensure `.gitignore` still blocks raw/** | `cat .gitignore \| grep "raw"` | After repo setup changes |

---

## Summary of Privacy Guarantees

1. **Raw sources never committed** — excluded by `.gitignore`, validated by scripts
2. **Metadata is ephemeral** — rebuilt fresh every time, never stored permanently
3. **Session memory is per-session** — cleared and rewritten each session (never persisted across sessions)
4. **Agent reads on demand** — only accesses what's explicitly needed for current operation; no global loading of all files at once
5. **No external uploads** — nothing leaves your machine automatically; any network access requires explicit harness capabilities

---

## Next Steps

- [`docs/getting-started.md`](getting-started.md) — Safe onboarding flow with private data handling
- [`rules/git_conventions.json`](../rules/git_conventions.md) — Git staging rules that prevent accidental commits of raw sources
- `scripts/validate-path.sh` — Path guardrails that block writes to protected zones
