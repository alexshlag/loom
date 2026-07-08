---
tags: [troubleshooting, maintenance, agent-instructions]
date: 2026-07-08
type: documentation
category: docs
aliases: [issues, fixes, debugging]
sources: [docs/troubleshooting.md]
related: [docs/getting-started.md, docs/scripts-guide.md, rules/error_handling.json]
---

# Troubleshooting Guide

Common problems you might encounter with Loomana, and how to resolve them. Most issues are caught automatically by the agent — these pages cover what happens when things go wrong and what you can do about it.

---

## Empty Wiki on Fresh Install

### Symptom
You just cloned the repository and `wiki/` is empty (or nearly so). You expect content but see nothing.

**This is expected.** Loomana ships with no pre-built wiki — it's a blank canvas that grows as you feed sources or ask questions.

```
wiki/
├── entities/       ← empty initially
├── concepts/       ← empty initially
├── syntheses/      ← empty initially
└── comparisons/    ← empty initially
```

### Solution
Start adding sources (URLs, files, or pasted text). Even one source will create the first wiki page. The agent handles everything — parsing, frontmatter generation, directory placement.

See [getting-started.md](getting-started.md) for the full onboarding flow.

---

## Source Ingest Fails with "Path Blocked"

### Symptom
Agent reports a path is blocked or you get an error when trying to add a source.

**Why:** `scripts/validate-path.sh` prevents writing to protected zones (wiki/, rules/, scripts/) — only `raw/sources/` accepts writes for safety.

### Solution
Provide the raw source file as-is, or paste content directly. Don't try to write files into wiki/, meta/, or rules/ yourself — those are agent-only zones:

```bash
# ✅ Correct: give the agent a file path
"Ingest this document: ~/Downloads/paper.pdf"

# ❌ Wrong: trying to put it in wiki directly
cp paper.md wiki/entities/     # This is blocked by validate-path.sh
```

The agent will capture the source into `raw/sources/SRC-YYYY-MM-DD-NNN/` and then create the wiki page from it.

---

## Duplicate Source Detected

### Symptom
Agent says a source is "already in the wiki" or "duplicate detected."

**Why:** Loomana uses hash-based deduplication (`scripts/rebuild-source-manifest.sh`). If you've already added this exact document (or its content hasn't changed), it won't create a duplicate page.

### Solutions

| Scenario | What to do |
|----------|-----------|
| You want new pages from the same source | Update the source — add new sections, update facts | The hash changes → agent treats it as new |
| Accidental re-ingest | Skip it silently. Check `wiki/index.md` for existing coverage | No action needed |
| Slightly modified version of same article | Add only the novel parts to a fresh source dir | Agent will link them via `related:` field |

---

## Contradictions Between Pages

### Symptom
Agent detects conflicting facts across wiki pages — e.g., one page says something is "version 2" and another says "version 3."

**Why:** Sources were added at different times, or from different authors with conflicting information.

### Resolution Process

The agent follows a priority cascade defined in [`rules/contradiction_resolution.json`](../rules/contradiction_resolution.md):

1. **Code Reality** (highest) — actual implementation / code wins
2. **Live State** — current system state
3. **Documentation** — historical or conceptual docs lose to above

The agent proposes fixes with bidirectional callouts (`[!contradiction]`) on both pages. You review and approve before any changes are made. No automatic overwrites happen without your go-ahead.

### What You Can Do
- Review the contradiction report (usually printed in session output)
- Approve, reject, or modify the proposed fix
- If you know which source is more authoritative, tell the agent — it will apply that priority

---

## Broken Links Detected During Lint

### Symptom
`scripts/lint.sh` reports broken internal links — `[[wiki/page.md]]` pointing to non-existent files.

**Why:** Source pages were removed or renamed, but link references weren't cleaned up. Or a typo in the wikilink path.

### Solutions

| Cause | Fix |
|-------|-----|
| Page was deleted/renamed | Remove dead links or update to new path | Agent auto-suggests via `auto-crosslink.sh` |
| Typo in wikilink path | Correct the path manually | Quick fix, no agent needed |
| External link broken | Replace with permalink (GitHub commit-specific URL) | Use `scripts/raw-link-repair.sh --dry-run` to preview |

The lint workflow auto-detects severity: if ≥80% of links on a page are still valid, it's considered low-severity and only reported. If <80%, the agent escalates and proposes fixes.

---

## Orphan Pages (No Incoming Links)

### Symptom
`scripts/orphan-pages.sh` returns pages with zero incoming backlinks — they exist in wiki/ but nobody links to them.

**Why:** Page was created but its relationships weren't discovered yet. This is normal for early-stage wikis.

### Solutions

| Approach | How |
|----------|-----|
| Auto-crosslinking | Run `scripts/auto-crosslink.sh --score 2` — it finds semantic connections and suggests linking |
| Manual review | Browse wiki categories to find natural connections | Add `[wiki/page.md]` references in body text |
| Delete if irrelevant | If page truly has no relationships, consider removing it | Orphan pages add noise |

Auto-crosslink scoring uses four levels: H1 title match → shared sources → semantic keywords → related-page overlap. Pages with score ≥2 are considered good candidates for linking.

---

## Metadata Rebuild Is Slow

### Symptom
`scripts/rebuild-meta.sh` takes noticeably long on a large wiki (>500 pages).

**Why:** The script walks the entire wiki directory to build registry.json, backlinks.json, and search-index.json. Each file is read individually.

### Solutions

| Optimization | Command | Benefit |
|-------------|---------|---------|
| Index-only rebuild | `./scripts/rebuild-meta.sh --index-only` | Only rebuilds index.md (~0.5s) — skips registry/backlinks |
| Incremental mode | Run normally after first full build | Script detects changed files via timestamp → only processes those |
| Skip semantic index | Modify process file to skip search-index generation | Saves ~1s per run (embedding computation) |

For most daily operations, `--index-only` is sufficient. The registry and backlinks rarely change between sessions.

---

## Git Commit Fails or Shows "Nothing to Stage"

### Symptom
Agent runs commit but gets "nothing added to stage" or the staging mode is wrong (wiki vs dev).

**Why:** Loomana distinguishes between **wiki mode** (only `wiki/*.md` changed) and **dev mode** (`.sh`, `.json`, `.py`, or rule files changed). Each requires different `git add` commands.

### Solutions

| Mode | Fix |
|------|-----|
| Wiki mode — only wiki pages changed | Agent should run: `git add wiki/*.md` then commit | Check if any non-wiki files were accidentally modified |
| Dev mode — scripts/rules changed | Agent should stage all affected directories individually, never `git add *` | Ensure `git status --short` shows expected changes before commit |

See [`rules/git_conventions.json`](../rules/git_conventions.md) for the full convention. The agent reads this file before every commit operation to detect mode and apply correct staging rules.

---

## Agent Doesn't Read AGENTS.md at Session Start

### Symptom
Agent behaves as if it doesn't know wiki conventions — creates pages in wrong directories, misses frontmatter fields, or doesn't follow naming rules.

**Why:** The agent didn't load `AGENTS.md` during session bootstrap. This is the most common cause of schema violations.

### Solution
Explicitly tell your harness to read AGENTS.md before starting work:

> "Please read AGENTS.md first — it's our wiki schema."

If the issue persists, verify that:
1. `AGENTS.md` exists in the repository root (not deleted)
2. Your AI harness supports reading files from disk paths
3. The session was started correctly (some harnesses need explicit "open" command to load the project)

---

## Scripts Error with Exit Code >0

### Symptom
A script crashes or returns an error code instead of silently completing.

**Why:** All scripts use `set -euo pipefail` (strict mode), so any command failure propagates as a non-zero exit code. This is intentional — it surfaces problems rather than hiding them.

### Quick Debug Steps

```bash
# Run script with verbose output if supported
./scripts/lint.sh --verbose

# Check for temp file cleanup issues (lib.sh trap)
ls /tmp/ | grep loom  # Orphaned temps from crashed scripts

# Verify git state before running agent commands
git status --short    # Ensure no uncommitted changes blocking workflow
```

### Common Fixes

| Error Pattern | Likely Cause | Fix |
|---------------|-------------|-----|
| `Permission denied` on script execution | Missing execute bit | `chmod +x scripts/*.sh` |
| `command not found: python3` | Python not installed | Install Python 3 (most systems have it) |
| `JSON parse error` in lint output | Malformed frontmatter in a wiki page | Check that YAML frontmatter is valid and properly closed with `---` |

---

## Memory / Context Files Corrupted

### Symptom
`working_memory.json` or `wiki/hot.md` has stale data — agent remembers old focus topics, open pages from previous sessions, etc.

**Why:** These files are per-session context. They should be cleared and rewritten at session start by the agent (via `session_bootstrap.json`). If they weren't cleaned up properly, old state persists.

### Solution
Reset manually:

```bash
# Clear working memory — next session will regenerate it fresh
rm working_memory.json

# Reset hot cache — agent will rebuild from scratch on next query/ingest
rm wiki/hot.md

# Rebuild metadata if index is stale
./scripts/rebuild-meta.sh --index-only
```

After clearing, start a new session. The agent will detect the missing files and initialize fresh state via `session_bootstrap.json`.

---

## Naming Collision (Two Projects Share Same Concept Name)

### Symptom
You add sources from two different frameworks/projects that have overlapping concept names — e.g., "cache-system" could be generic, but also framework-specific. Agent creates one page where you expected two.

**Why:** Loomana uses project prefixing to prevent collisions. If a concept is truly abstract (universal), it gets no prefix. Framework-specific concepts must include their project slug: `symfony-cache-pattern`, `react-caching-strategy`.

### Solutions

| Scenario | How to resolve |
|----------|---------------|
| You want framework-specific coverage | Prefix the filename with project name in ingest instructions | "Create page as `react-hooks-pattern.md`" |
| Concept is truly abstract (universal) | Use bare name — it's intentionally shared | Agent auto-detects via tag analysis |
| Existing pages violate naming rules | Run `scripts/filename-audit.sh --fix` to detect and suggest renames | Requires manual approval before applying |

The exception list (truly abstract concepts without prefixes) is maintained in [`rules/naming_conventions.json`](../rules/naming_conventions.md). If you want something added there, propose it via `[schema-patch]`.

---

## Summary of Quick Commands

| Problem | Command to Try First |
|---------|---------------------|
| Empty wiki on fresh install | Add sources — see getting-started.md |
| Path blocked for writing | Use agent capture flow, don't write directly |
| Duplicate source detected | Check index.md or update the source content |
| Contradictions found | Review agent's proposal — approve/reject manually |
| Broken links / orphans | `scripts/lint.sh` → review issues → fix via auto-crosslink.sh |
| Slow metadata rebuild | `./scripts/rebuild-meta.sh --index-only` |
| Agent ignoring conventions | Explicitly tell harness to read AGENTS.md first |
| Script errors | Check `--help`, verify permissions, inspect temp files in /tmp/ |
| Corrupted memory state | Clear working_memory.json + hot.md, restart session |

---

## Where to Find More Detail

- [`docs/architecture.md`](architecture.md) — How layers interact and where errors propagate
- [`rules/error_handling.json`](../rules/error_handling.md) — The detect-analyze-resolve-continue protocol in detail
- `scripts/*.sh --help` — Every script provides usage info via `--help` flag
