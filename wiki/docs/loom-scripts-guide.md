---
tags: [Loomana, loom, scripts, automation, guardrails]
date: 2026-07-08
type: documentation
category: docs
aliases: [cli-tools, validation-scripts, lint-scripts]
sources: [docs/scripts-guide.md]
related: [wiki/docs/loom-getting-started.md, wiki/docs/loom-architecture.md, wiki/docs/loom-rules-reference.md]
---
# Scripts Guide — Loomana Automation Toolkit

# Scripts Guide — Loomana Automation Toolkit

Page covering Scripts Guide — Loomana Automation Toolkit — overview, usage patterns, and related resources.
## Overview

Loomana ships with **~30 scripts** in `scripts/` that handle automation: metadata rebuilds, lint checks, source validation, auto-crosslinking, and memory management. Every script follows strict conventions (`set -euo pipefail`, `--help` mandatory, exit codes 0=success / >0=error).

---

## Shared Utilities

### `lib.sh` — Central Utility Library

Sourced by most scripts to provide:

| Function | Purpose |
|----------|---------|
| `atomic_write target <content>` | Write to `.tmp` → `mv` (crash-safe) |
| `cleanup_add pattern` | Register files for auto-cleanup on EXIT |
| `_set_cleanup_trap` | Install EXIT trap calling cleanup function |
| `log_error level message` | Timestamped error logging to stderr |

> **Every script that writes files should source lib.sh + call `_set_cleanup_trap`.** Prevents orphan temp files on crash.

---

## Ingest Pipeline Scripts

| Script | Purpose | Exit Codes |
|--------|---------|------------|
| `validate-path.sh <path>` | Guardrails for raw/ — blocks direct edits to protected zones (wiki/, meta/) | 0=allowed, 1=blocked |
| `check-new-sources.sh [--quick]` | Scans raw/sources/SRC-* for new packages not in registry | 0=no new, 1=new found, 2=cached |
| `classify-source.sh <url>` | Domain classification → authority grade + recommended wiki path | 0 always |
| `batch-ingest.sh [--scan]` | Clusters ≥3 related sources with shared keywords | 0=none, 1=clusters ready |
| `rebuild-source-manifest.sh --scan-only` | Hash-based deduplication registry for raw sources | Updates tracking/source-manifest.json |
| `text-similarity.sh [--threshold N]` | Detect copy-paste chains via n-gram comparison (≥70% similarity) | JSON array of pairs |

---

## Query & Search Scripts

| Script | Purpose | Notes |
|--------|---------|-------|
| `wiki-search.sh --category <cat> --query <text>` | Smart category-based search with relevance prioritization | Uses index.md → semantic → grep fallback chain |
| `date-consistency.sh` | Checks date consistency between frontmatter and "Updated" sections | Reports mismatches as JSON array |

---

## Lint & Audit Scripts

### Comprehensive Validation (`lint.sh`)

Runs 15+ checks across wiki structure, frontmatter, links, contradictions. Non-blocking (always exits 0 unless error).

| Check ID | What It Checks |
|----------|---------------|
| #1 | Contradictions between pages |
| #2 | Structural violations (FIRST-BLOCK-V1) |
| #3 | Empty/generic tags |
| #4 | Missing frontmatter |
| #5 | Broken links |
| #6 | Filename collisions / naming convention violations |
| #7 | Excessive empty lines |
| #8 | Duplicate titles within category |
| #9 | Orphan pages (no incoming backlinks) |
| #10 | Date consistency |
| #11 | Source freshness |
| #12 | Evidence grade compliance |
| #13 | Tag validation |
| #14 | Crosslink completeness |
| #15 | Markdown formatting |

### Other Audit Scripts

- `docs-audit.sh --mode <a\|b\|c>` — Structural check for wiki/docs/ pages (STATE A/B/C logic)
- `orphan-pages.sh` — Returns JSON of pages with zero backlinks
- `duplicate-titles.sh` — Finds duplicate H1 headings within categories
- `filename-audit.sh [--fix]` — Scans concepts/ for naming violations + suggests renames
- `tag-audit.sh [--fix]` — Tag audit with auto-fix for generic tags
- `structural-fix.sh [--fix]` — Fixes FIRST-BLOCK-V1 violations (missing body text between H1 and ##)

---

## Metadata & Indexing Scripts

### `rebuild-meta.sh [--index-only]`

Single-pass meta regeneration using Python — generates registry.json, backlinks.json, h1-index.json, search-index.json in ONE subprocess instead of N separate calls.

- `--index-only` → fast refresh (~0.5s), rebuilds only index.md
- Incremental mode detects changed files via timestamp file

### Other Metadata Scripts

| Script | Purpose |
|--------|---------|
| `regenerate-backlinks.sh [wiki] [output]` | Rebuilds meta/backlinks.json from wiki markdown links |
| `auto-crosslink.sh --score <threshold>` | Multi-level crosslink discovery with scoring (H1 match, shared sources, semantic keywords) |

---

## Contradiction Resolution Scripts

- `detect-contradications.sh` — Soft scan for conflicting facts across pages → JSON output
- `apply-contradiction-fix.sh [--dry-run] --target <page>` — Shows proposed diff without applying

---

## Git & Version Control Scripts

### `git-auto-commit.sh <type> <scope> <description>`

Harness-independent auto-commit. Detects wiki vs dev mode from changes, stages appropriate files automatically.

**Usage:**
```bash
./scripts/git-auto-commit.sh "feat" "lint" "add check_12_orphan_detection"
```

---

## Memory & Context Scripts

| Script | Purpose |
|--------|---------|
| `load-hot-cache.sh [wiki]` | Loads wiki/hot.md into context (exits 1 if missing — graceful) |
| `load-hot-cache.sh [path]` | Restores session from backup hot.md file |
| `check-wiki-changes.sh [wiki]` | Early-exit guard for harness hooks |

---

## Quick Reference Table

| Need | Script | Typical Args |
|------|--------|--------------|
| Validate path | `validate-path.sh` | `<path>` |
| New sources? | `check-new-sources.sh` | `--quick` |
| Lint check | `lint.sh` | `--quiet`, `--skip-checks 1,3` |
| Rebuild index | `rebuild-meta.sh` | `--index-only` |
| Auto-crosslink | `auto-crosslink.sh` | `--score 3` |
| Commit changes | `git-auto-commit.sh` | `<type> <scope> <desc>` |

---

## Conventions Summary

1. **Strict mode** — Every script: `set -euo pipefail` (some have it commented during refactor)
2. **Quoted paths** — `"${var}"` everywhere to prevent word splitting
3. **JSON via Python/jq** — Never manual echo/printf for JSON construction
4. **Markdown via awk/sed/grep** — Standard text processing only
5. **--help mandatory** — Every script accepts `--help` or `-h`
6. **Exit codes >0 = errors** — Scripts should exit 0 on success

---

## See Also

- [`wiki/docs/loom-getting-started.md`](loom-getting-started.md) — Getting started with Loomana
- [`wiki/docs/loom-architecture.md`](loom-architecture.md) — How scripts fit into architecture layers
- [`wiki/docs/loom-rules-reference.md`](loom-rules-reference.md) — Rules that govern script behavior
