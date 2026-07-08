# Scripts Guide

Complete reference for all scripts in `scripts/`. Each script uses `set -euo pipefail`, supports `--help` (or `-h`), and follows the convention: **exit code 0 = success, exit code >0 = error**. All JSON output is generated via Python's `json.dumps()` — never manual string concatenation.

---

## Shared Utilities

### `lib.sh`

Central utility library sourced by most scripts. Provides:

| Function | Purpose | Usage |
|----------|---------|-------|
| `atomic_write target <content>` | Write to `.tmp` → `mv` (atomic, crash-safe) | `cat data.json \| atomic_write output.json` |
| `atomic_write_content target "data"` | Same but with string content directly | `atomic_write_content file.json '{"key":"value"}'` |
| `cleanup_add pattern` | Register files for auto-cleanup on EXIT | `cleanup_add "/tmp/*.txt"` |
| `_set_cleanup_trap` | Install EXIT trap calling `cleanup_temp_files()` | Call once after sourcing lib.sh |
| `log_error level message` | Timestamped error logging to stderr | `log_error "WARN" "something happened"` |
| `generate_json k1 v1 k2 v2 > out.json` | Safe JSON generation via Python | `generate_json name Alice age 30 > data.json` |

> **Every script that writes files should source lib.sh and call `_set_cleanup_trap`.** This prevents orphan temp files on crash.

---

## Ingest Pipeline

### `validate-path.sh <path>`

Guardrails for raw sources — blocks direct edits to protected zones (wiki, meta, rules).

- **Args:** `<path>` — path to validate
- **Exit code:** 0 = allowed, 1 = blocked (protected zone)
- **Example:** `./scripts/validate-path.sh ~/Downloads/paper.pdf` → writes to raw/sources/SRC-*
- **Used by:** All ingest steps before writing

### `check-new-sources.sh [--quick] [raw_dir] [registry_file]`

Scans `raw/sources/SRC-*` for new packages not yet in registry.

- **Args (optional):** `--quick` (fast mode, cached 1h), `--max N` (depth limit, default: 10)
- **Exit code:** 0 = no new sources, 1 = found new sources (printed to stdout), 2 = cached_skip (--quick only)
- **Example:** `./scripts/check-new-sources.sh --quick` → exits immediately if checked <1h ago

### `classify-source.sh <url_or_domain> [--dry-run] [--verbose]`

Domain classification for documentation sources — determines authority level, category routing.

- **Args:** `<url_or_domain>` (required), `--dry-run`, `--verbose`
- **Output:** JSON with domain authority grade, recommended wiki path
- **Example:** `./scripts/classify-source.sh github.com/alexshlag --verbose`

### `batch-ingest.sh [--scan]`

Batch ingest orchestrator — clusters ≥3 related sources and suggests wiki pages.

- **Args (optional):** `--scan` — scan mode, outputs cluster analysis JSON
- **Exit code:** 0 = no clusters found, 1 = clusters ready for processing
- **Example:** `./scripts/batch-ingest.sh --scan` → detects Symfony cluster: messenger, twig, assetmapper

### `rebuild-source-manifest.sh [--scan-only]`

Hash-based source deduplication registry. Scans all raw sources, computes hashes, compares against corrected copies.

- **Args (optional):** `--scan-only` — only scan, don't write manifest
- **Output:** Updates `tracking/source-manifest.json`
- **Example:** `./scripts/rebuild-source-manifest.sh --scan-only` → checks for modified raw sources

### `text-similarity.sh [--threshold N] [wiki_dir]`

Detect copy-paste chains via n-gram comparison. Graceful by design — never fails, always returns JSON result.

- **Args (optional):** `--threshold N` (similarity threshold 0-1, default: 0.7)
- **Output:** JSON array of similarity pairs with scores
- **Example:** `./scripts/text-similarity.sh --threshold 0.6` → finds pages with >60% overlap

### `unified-pass.sh [--wiki-dir <path>]`

Single walk, three analyses — orchestrator that runs structural validation + backlink detection + duplicate detection in one pass instead of N separate subprocesses.

- **Args (optional):** `--wiki-dir <path>` — custom wiki directory
- **Output:** Combined analysis JSON to stdout
- **Example:** `./scripts/unified-pass.sh --wiki-dir /path/to/wiki` → runs all checks once, ~2s faster than sequential

---

## Query & Search

### `wiki-search.sh [--category <cat>] [--query <text>] [wiki_dir]`

Smart category-based wiki search with relevance prioritization. Uses index.md → semantic → grep fallback chain.

- **Args (optional):** `--category <cat>` filter, `--query <text>` search term
- **Output:** Ranked list of relevant wiki pages
- **Example:** `./scripts/wiki-search.sh --category entities --query "messaging"` → returns entity pages about messaging systems

### `date-consistency.sh [wiki_dir]`

Checks date consistency between frontmatter dates and "## Updated" sections. Reports mismatches where page content is stale but frontmatter says recent (or vice versa).

- **Args (optional):** `[wiki_dir]` — default: current wiki directory
- **Output:** JSON array of pages with date inconsistencies
- **Example:** `./scripts/date-consistency.sh` → finds 5 pages with mismatched dates

---

## Lint & Audit

### `lint.sh [--quiet] [--skip-checks ID1,ID2] [wiki_dir]`

Comprehensive lint audit — runs 15+ checks across wiki structure, frontmatter, links, contradictions. Non-blocking (always exits 0 unless error).

- **Args (optional):**
  - `--quiet` — suppress output, only set exit code
  - `--skip-checks ID1,ID2` — skip specific check IDs (e.g., "1,3")
  - `[wiki_dir]` — custom wiki directory path
- **Checks:** Contradictions (#1), structural violations (#2), empty/generic tags (#3), missing frontmatter (#4), broken links (#5), filename collisions (#6), excessive empty lines (#7), duplicate titles (#8), orphan pages (#9), date consistency (#10), source freshness (#11), evidence grade compliance (#12), tag validation (#13), crosslink completeness (#14), markdown formatting (#15)
- **Example:** `./scripts/lint.sh --quiet` → exits 0 if all clean, 1+ if issues found (but doesn't block flow)

### `docs-audit.sh [--mode <a|b|c>] [wiki_dir]`

Audit wiki/docs/ pages for structural issues: missing nav headers, broken links, orphaned pages, duplicate content.

- **Args (optional):**
  - `--mode <a\|b\|c>` — STATE A (no docs dir), B (orphaned docs), C (mature docs)
  - `[wiki_dir]` — default: current wiki directory
- **Exit code:** 0 = clean, 1 = issues detected
- **Example:** `./scripts/docs-audit.sh --mode c` → checks mature docs for overlapping content

### `orphan-pages.sh [wiki_dir]`

Finds wiki pages without incoming links (no backlinks). Uses meta/backlinks.json instead of O(n²) grep — O(1) lookup per page.

- **Args (optional):** `[wiki_dir]`
- **Output:** JSON array of orphaned page paths
- **Example:** `./scripts/orphan-pages.sh` → returns pages with zero incoming links

### `duplicate-titles.sh [wiki_dir]`

Checks for duplicate titles within wiki categories. Uses Python + hash-set O(n) instead of multiple subprocess head calls.

- **Args (optional):** `[wiki_dir]`
- **Output:** JSON array of duplicate title groups
- **Example:** `./scripts/duplicate-titles.sh` → finds pages with identical H1 headings in same category

### `filename-audit.sh [--fix] [wiki_dir]`

Scans wiki/concepts/ for naming convention violations: project-specific tags (e.g., symfony-messaging) without matching prefix in filename.

- **Args (optional):** `--fix` — attempt auto-fix for simple renames
- **Output:** JSON array of violations with severity and suggested new names
- **Example:** `./scripts/filename-audit.sh` → returns `{file: "messenger-component.md", severity: "HIGH", suggested_name: "symfony-messenger-component.md"}`

### `tag-audit.sh [--fix] [--quiet] [wiki_dir]`

Tag audit with auto-fix capability — finds generic tags (e.g., "tech", "important") and replaces them with domain-specific ones.

- **Args (optional):**
  - `--fix` — apply automatic fixes for tag violations
  - `--quiet` — only report, don't fix
- **Output:** JSON audit results to stdout when not fixing
- **Example:** `./scripts/tag-audit.sh --fix` → replaces generic tags with specific ones across wiki

### `structural-fix.sh [--fix] [wiki_dir]`

Fixes FIRST-BLOCK-V1 violations — missing body text between H1 and first ## heading. Adds minimal content paragraph when violation detected.

- **Args (optional):**
  - `--fix` — apply fixes automatically
  - `[wiki_dir]` — default: current wiki directory
- **Exit code:** 0 = no violations or all fixed, 1 = violations remain (without --fix)
- **Example:** `./scripts/structural-fix.sh --fix` → adds placeholder paragraphs to structural-violation pages

### `check-structural.sh [wiki_dir]`

Same as structural-fix.sh but in read-only mode — just finds violations without fixing.

- **Args (optional):** `[wiki_dir]`
- **Output:** JSON array of structural violation paths
- **Example:** `./scripts/check-structural.sh` → returns pages missing body text between H1 and ##

---

## Metadata & Indexing

### `rebuild-meta.sh [--index-only] [wiki_dir]`

Single-pass meta regeneration using wiki-walk.py. Generates registry.json, backlinks.json, h1-index.json, search-index.json from all wiki pages in ONE Python subprocess instead of N separate calls.

- **Args (optional):**
  - `--index-only` — only rebuild index.md (skip registry.json and backlinks.json)
  - `[wiki_dir]` — default: current wiki directory
- **Features:** Incremental mode detects changed files via timestamp file; full rebuild when timestamp missing
- **Example:** `./scripts/rebuild-meta.sh --index-only` → fast refresh, ~0.5s for index only

### `regenerate-backlinks.sh [wiki_dir] [output_json]`

Regenerates meta/backlinks.json from wiki files — reads all wikilinks in markdown and builds reverse mapping.

- **Args (optional):** `[wiki_dir]`, `[output_json]` (default: `meta/backlinks.json`)
- **Output:** Writes backlinks.json to specified path
- **Example:** `./scripts/regenerate-backlinks.sh wiki/ meta/backlinks.json`

### `auto-crosslink.sh [--score <threshold>] [wiki_dir]`

Multi-level crosslink discovery for wiki pages. Four scoring levels: H1 title match → shared sources in frontmatter → semantic keywords → related page overlap. Auto-generates `related:` suggestions.

- **Args (optional):**
  - `--score <threshold>` — minimum crosslink score to suggest (0-4, default: 2)
  - `[wiki_dir]` — default: current wiki directory
- **Output:** JSON array of suggested crosslinks with scores
- **Example:** `./scripts/auto-crosslink.sh --score 3` → only suggests strong crosslinks (score ≥3)

---

## Contradiction Resolution

### `detect-contradications.sh [wiki_dir]`

Soft scan for potential contradictions in wiki — parses frontmatter dates + key facts, builds comparison matrix. Identifies conflicting claims across pages.

- **Args (optional):** `[wiki_dir]`
- **Output:** JSON array of contradiction pairs with severity scores
- **Example:** `./scripts/detect-contradications.sh` → returns `{page1: "x.md", page2: "y.md", conflict: "..."}'`

### `apply-contradiction-fix.sh [--dry-run] [--target <page_path>]`

Semi-auto generation of diff for contradiction sections. Shows what changes would be made to resolve a detected contradiction without actually writing files (unless --fix is added).

- **Args (optional):**
  - `--dry-run` — show diff without applying
  - `--target <page_path>` — specific page to fix
- **Output:** Diff output to stdout showing proposed changes
- **Example:** `./scripts/apply-contradiction-fix.sh --dry-run --target wiki/entities/foo.md` → shows what contradiction fix would look like

---

## Memory & Context

### `load-hot-cache.sh [wiki_dir]`

Graceful harness hook — exits 1 if wiki/hot.md missing (no vault = no-op), otherwise loads hot cache into environment. Used by query workflow to restore session context.

- **Args (optional):** `[wiki_dir]` — default: `wiki/`
- **Exit code:** 0 = loaded, 1 = no hot.md found
- **Used by:** process-query.json step_0.25, process-ingest.json post_action

### `check-wiki-changes.sh [wiki_dir]`

Graceful harness hook — early exits with 1 if prerequisites missing (no vault, no git). Checks whether wiki has been modified since last check.

- **Args (optional):** `[wiki_dir]`
- **Exit code:** 0 = changes detected or pristine, 1 = prerequisites missing
- **Used by:** Pre-commit workflow to decide memory sync requirements

---

## Raw Source Management

### `raw-correct.sh <source_path> <corrected_content>`

Safe write wrapper for agent to create corrected copies in raw/corrected/. Agent writes processed/corrected markdown files via this script (never direct to protected zones).

- **Args:** `<source_path>` (original), `<corrected_content>` (processed text)
- **Output:** Writes corrected file to `raw/corrected/<basename>.md`
- **Example:** `./scripts/raw-correct.sh raw/sources/SRC-001/README.md "Fixed content"` → creates raw/corrected/README.md

### `raw-link-repair.sh [--dry-run] [raw_dir]`

Converts relative markdown links in raw GitHub sources to permalinks (GitHub raw URLs, commit-specific URLs). Makes wiki pages resilient to repository reorganizations.

- **Args (optional):**
  - `--dry-run` — show what would change without writing
  - `[raw_dir]` — default: raw/sources/
- **Output:** Modified source files with permalinks injected
- **Example:** `./scripts/raw-link-repair.sh --dry-run raw/sources/` → shows which links need permalink conversion

---

## Git & Version Control

### `git-auto-commit.sh <type> <scope> <description>`

Harness-independent auto-commit for wiki changes. Emulates claude-obsidian's PostToolUse hook without harness dependency. Detects mode automatically (wiki vs dev) and handles staging accordingly.

- **Args:**
  - `<type>` — commit type: feat, fix, refactor, schema, lint, ingest, query
  - `<scope>` — scope identifier: entities, concepts, scripts, rules, etc.
  - `<description>` — human-readable description of changes
- **Example:** `./scripts/git-auto-commit.sh "feat" "lint" "add check_12_orphan_detection"` → stages appropriate files and commits

---

## Skills & Distillation

### `export-skill.sh <skill-file-name-without-extension> [destination-dir]`

Export skill from wiki/skills/ → .pi/skills/<skill-name>/SKILL.md. Bridges wiki skills with Pi runtime skill system.

- **Args:**
  - `<skill-file-name>` — name without .md extension
  - `[destination-dir]` — default: ~/.pi/skills/ (Pi's global skills directory)
- **Example:** `./scripts/export-skill.sh memory-hooks-integration-with-process` → copies to .pi/skills/memory-hooks/SKILL.md

---

## Safety & Locking

### `wiki-lock.sh <action> <page_path>`

Per-file advisory locking for safe multi-writer vault mutation. Prevents concurrent writes to the same wiki page from multiple agent sessions or processes.

- **Args:**
  - `<action>` — lock, unlock, check (acquire lock, release lock, test if locked)
  - `<page_path>` — path to wiki page requiring lock
- **Example:** `./scripts/wiki-lock.sh lock wiki/entities/foo.md` → acquires exclusive write lock on foo.md

---

## Performance & Benchmarks

### `benchmark-rebuild.sh [wiki_dir]`

Runs rebuild-meta.sh multiple times and reports average execution time. Useful for measuring performance impact of script optimizations (like batched JSON reads).

- **Args (optional):** `[wiki_dir]`
- **Output:** Execution timing report to stderr
- **Example:** `./scripts/benchmark-rebuild.sh` → runs 10 iterations, reports mean/median/stddev

### `batch-extract-json.sh <json_data> field1 field2 ...`

Extract multiple fields from JSON in a single Python call — avoids fork overhead of calling jq/python N times for N fields.

- **Args:** `<json_data>` (string or file path), followed by field names
- **Output:** Extracted values as newline-separated `field: value` pairs
- **Example:** `./scripts/batch-extract-json.sh '{\"name\":\"Alice\",\"age\":30}' name age` → outputs `name: Alice\nage: 30`

---

## Quick Reference Table

| Script | Primary Use | Typical Args | Exit Codes |
|--------|-------------|--------------|------------|
| `validate-path.sh` | Path guardrails | `<path>` | 0=OK, 1=blocked |
| `check-new-sources.sh` | Detect new raw sources | `--quick`, `--max N` | 0=no, 1=yes, 2=cached |
| `classify-source.sh` | Domain authority grading | `<url> --verbose` | 0 always |
| `batch-ingest.sh` | Cluster detection | `--scan` | 0=none, 1=clusters |
| `rebuild-meta.sh` | Index + registry rebuild | `--index-only` | 0 success |
| `wiki-search.sh` | Category-based search | `--category`, `--query` | 0 always |
| `lint.sh` | Comprehensive validation | `--quiet`, `--skip-checks` | 0=clean, >0=issues |
| `docs-audit.sh` | Docs structural check | `--mode a\|b\|c` | 0=clean, 1=issues |
| `auto-crosslink.sh` | Crosslink discovery | `--score N` | 0 always |
| `git-auto-commit.sh` | Auto commit | `<type> <scope> <desc>` | 0 success |

---

## Conventions Summary

All scripts follow these conventions:
1. **`set -euo pipefail`** — strict mode in every script (some have it commented during refactor)
2. **Paths quoted** — `"${var}"` everywhere to prevent word splitting
3. **JSON via Python/jq** — never manual echo/printf for JSON construction
4. **Markdown via awk/sed/grep** — text processing with standard tools
5. **`--help` mandatory** — every script accepts `--help` or `-h` for usage info
6. **Exit codes >0 = errors** — scripts should exit 0 on success, non-zero on failures
7. **lib.sh cleanup** — any temp files must be registered via `cleanup_add()` + `_set_cleanup_trap()`

> See [`RULES.md`](../RULES.md) for additional technical conventions and best practices.

---

## Next Steps

For more detail:
- [`docs/architecture.md`](architecture.md) — How scripts fit into the layer architecture
- [`rules/error_handling.json`](../rules/error_handling.md) — Detect-analyze-resolve-continue protocol
- `scripts/*.sh --help` — Run any script with `--help` for live usage info
