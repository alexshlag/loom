---
tags: [Loomana, loom, conventions, frontmatter-schema, commit-format, evidence-grading, tag-patterns]
date: 2026-07-08
type: documentation
category: concept
aliases: []
sources: ["docs/api-conventions.md"]
related: ["wiki/docs/loom-architecture", "wiki/docs/loom-rules-reference", "rules/categories.json", "rules/tag-guidelines.json"]
---
# API Conventions Guide

# API Conventions Guide

Page covering API Conventions Guide — overview, usage patterns, and related resources.
## Frontmatter Schema

Every wiki page has YAML frontmatter at the top. This is the canonical schema:

```yaml
---
tags: [Loomana, loom, conventions, frontmatter-schema, commit-format, evidence-grading, tag-patterns]              # 3-7 domain-specific keywords (see Tag Patterns below)
date: YYYY-MM-DD                       # Current system date — NEVER source-derived!
type: documentation                    # documentation | code_reality | live_state
category: entities                     # Must match categories.json definition
aliases: [synonym1, synonym2]          # Discoverability synonyms
sources:                               # Data origins (raw/ paths, wiki relative, or web_search)
  - raw/sources/SRC-YYYY-MM-DD-NNN/    # Raw source directory path
  - wiki/entities/symfony-messenger.md  # Related wiki page (relative)
  - web_search                         # Web search result marker
related:                               # Wiki-relative paths to connected pages — empty = no connections
  - wiki/concepts/cache-system.md
---
```

### Field Specifications

| Field | Type | Required | Auto-computed? | Notes |
|-------|------|----------|----------------|-------|
| `tags` | string[] | ✅ Yes | ❌ No | 3-7 keywords. See Tag Patterns section below for valid patterns and prohibited generics. |
| `date` | YYYY-MM-DD | ✅ Yes | ❌ No | **Current system date.** Never use source filename, commit date, or web crawl timestamp. |
| `type` | enum | ✅ Yes | ❌ No | Reality layer: `documentation` (conceptual/historical), `code_reality` (actual implementation), `live_state` (current observable state). Used in contradiction resolution. |
| `category` | enum | ✅ Yes | ❌ No | Must match one of the categories from `rules/categories.json`. Determines directory and auto-crosslink routing. |
| `aliases` | string[] | ⚠️ Recommended | ❌ No | Discoverability synonyms — what users actually type in queries. See Tag Guidelines for full rules. |
| `sources` | string[] | ✅ Yes | ❌ No | Data origins: raw/ paths, wiki-relative paths (`wiki/entities/foo.md`), or `"web_search"` marker. At least one required per page. |
| `related` | string[] | ⚠️ Recommended | ❌ No | Wiki-relative paths to connected pages. Empty = no connections (rare). Agent auto-suggests via crosslink scoring. |

### Auto-computed Fields (Not in Frontmatter)

- **evidence_grade** — Assigned during ingest based on source authority:
  - `documented` — authoritative sources (official docs, project wiki, core maintainer blog)
  - `corroborated` — confirmed by 2+ independent sources
  - `assertion_only` — unconfirmed or from weak sources (generic blog, forum post)

> Evidence grade is stored in page metadata, not visible in frontmatter body text. Used internally for contradiction resolution priority cascade: documented > corroborated > assertion_only.

---

## Commit Format Convention

All commits follow a strict format that enables easy filtering and understanding of project history:

```
<type> | <scope>: <description>
```

### Types

| Type | Purpose | Example |
|------|---------|---------|
| `feat` | New feature, script, rule, or process improvement | `feat | lint: add check_12_orphan_detection` |
| `fix` | Bug fix in scripts, processes, or rules | `fix | memory: correct WM write timing` |
| `refactor` | Structural improvement without behavior change | `refactor | rules: consolidate duplicate checks` |
| `schema` | Changes to AGENTS.md, process files, rules/*.json | `schema | ingest: unify crosslink step_7` |
| `lint` | Lint fixes applied to wiki pages (contradictions, orphans, formatting) | `lint | fix: resolve 3 contradiction pairs` |
| `ingest` | New source added to wiki with page creation | `ingest | add entity: pi-coding-agent` |
| `query` | Query result saved as new wiki page (synthesis, comparison) | `query | synthesis on temporal_decay_patterns` |

### Scope Constraints

- **Scope**: lowercase component/module name — no spaces, no special characters
- **Description**: lowercase imperative summary — what changed, not why

**Valid examples:**
```
feat | lint: add check_12_orphan_detection
fix | memory: correct WM write timing
refactor | rules: consolidate duplicate checks
schema | ingest: unify crosslink step_7
lint | fix: resolve 3 contradiction pairs
ingest | add entity: pi-coding-agent
query | synthesis on temporal_decay_patterns
```

**Invalid examples:**
```
feat | Lint Check: Add orphan detection    ← uppercase scope, descriptive instead of imperative
fix | memory-fix | WM timing               ← multiple scopes, no separator after description
schema | AGENTS.md | Updated schema        ← uppercase, uses pipe in description
```

### Staging Modes

Before committing, detect the mode from changes:

| Mode | Trigger Condition | Command |
|------|-------------------|---------|
| **Wiki mode** | Only `wiki/*.md` changed (no scripts/rules/process files modified) | `git add wiki/` |
| **Dev mode** | Any `.sh/.json/py/md` in root, rules/, scripts/, or process-*.json changed | `git add -A` |

> **Never use `git add *` or `git commit -a`.** Always stage explicitly with the correct command. Memory sync is REQUIRED after dev commits (update WM + hot.md). Wiki mode only needs WM update.

---

## Evidence Grading System

Evidence grade is auto-computed during ingest based on source authority analysis:

### Grade Levels

| Grade | Confidence Level | When to Assign | Example Sources |
|-------|------------------|----------------|-----------------|
| **documented** | High | Fact from authoritative source | Official docs, project wiki, core maintainer blog, RFC, spec document |
| **corroborated** | Medium-high | Fact confirmed by 2+ independent sources | Multiple blogs with same claim, stack overflow answer + official doc confirming |
| **assertion_only** | Low | Unconfirmed assertion or from weak source | Generic blog post, forum comment, unverified tweet, single unsourced claim |

### Assignment Rules

1. **Agent analyzes source during ingest** and automatically assigns grade to each fact extracted
2. **Grade recorded in page metadata** — not visible in frontmatter body text
3. **Used in contradiction resolution:** documented(1) > corroborated(2) > assertion_only(3) as sub-priority for documentation sources
4. **Never set manually** — only assigned by agent from source authority analysis

### Conflict Resolution Priority Cascade

When contradictions are detected between pages:

```
PRIORITY 1: Code Reality (always wins)
           ← Actual implementation / code in repository

PRIORITY 2: Live State (next)  
           ← Current system state, observable and timestamped

PRIORITY 3: Documentation (fallback)
           ← Only when no code/live available, uses evidence_grade sub-priority

Evidence Grade Sub-Priority (within documentation):
   documented > corroborated > assertion_only
```

### Constraints

- **NEVER** allow user override for objective facts (e.g., "2+2=4", "API returns status 200")
- **NEVER** skip the cascade order — always apply priority_1 > priority_2 > priority_3
- **NEVER** use documentation if code_reality or live_state exists

---

## Tag Patterns & Enforcement

### Valid Tag Pattern

```
{domain-entity} + {specific-concept} + {technology/role}
```

This ensures 3+ tags with meaningful specificity. Examples:

| Page Type | Good Tags | Bad Tags |
|-----------|-----------|----------|
| Entity (symfony-messenger) | `symfony`, `messaging-bus`, `php-framework` | `framework`, `tool`, `tech` |
| Concept (hexagonal-architecture) | `clean-architecture`, `ports-and-adapters`, `design-pattern` | `architecture`, `pattern`, `generic` |
| Synthesis (rag-vs-llm-wiki) | `rag-pattern`, `llm-wiki`, `knowledge-retrieval` | `ai`, `research`, `comparison` |
| Comparison (loom-vs-claude) | `loomana`, `claude-code`, `wiki-comparison` | `tools`, `comparison`, `review` |

### Prohibited Generic Tags

Never use these alone as tags:
- `architecture` — too broad, not domain-specific
- `admin` — meaningless without context
- `ai` — extremely generic
- `cms` — doesn't indicate specific CMS type
- `framework` — not a framework name itself
- `tool` — useless on its own
- `workflow` — could mean anything
- `testing` — too broad, needs domain qualifier
- `knowledge-base` — meta-category, not domain-specific
- `platform` — extremely generic

### Category-Specific Patterns

| Directory | Pattern | Example Good Tags |
|-----------|---------|-------------------|
| `entities/` | `{primary-name} + {category-sub} + {language-tech}` | `symfony`, `doctrine-orm`, `twig` |
| `concepts/` | `{concept-name} + {pattern-type} + {implementation}` | `hexagonal-architecture`, `event-dispatcher`, `state-machine` |
| `syntheses/` | `{topic} + {comparison-type} + {methodology}` | `rag-vs-llm-wiki`, `compounding-pattern` |
| `comparisons/` | `{entity-a} + {entity-b} + {comparison-dimension}` | `symfony-ux-packages`, `loom-vs-claude-obsidian` |

### Cross-Reference Enforcement Rule

**If page A links to page B → both must share at least one common tag.** This ensures crosslinks are semantically meaningful and not just structural noise. The agent enforces this during ingest via `process-ingest.json#post_check`.

### Language Consistency

Use **either English OR Russian within one document** — never mix languages in tags. English is preferred for consistency with AGENTS.md conventions. Exceptions: Russian-only content pages may use ru-tags exclusively (but not mixed EN/RU).

---

## Link Format Conventions

### Internal Links

```markdown
[text](wiki-relative-path.md)
```

- **Allowed:** `[symfony messenger](entities/symfony-messenger.md)` — relative to wiki/ root
- **Cross-category exception:** `../` allowed for cross-category links (e.g., concepts → entities) as long as target exists under wiki/
- **Prohibited:** `./` dot-relative paths never used

### External Links

```markdown
[text](https://example.com/page)
```

- **Standard:** Canonical HTTP/HTTPS URLs only
- **Prohibited:** `[text](raw/**)` — never link to raw/ from wiki pages; `[text](../**)` — relative external paths prohibited
- **Unavailability check:** Log broken URLs (404/timeouts), inform user, do NOT auto-remove

### Crosslink Scoring Algorithm

The `auto-crosslink.sh` script uses a weighted scoring system:

| Signal | Weight | Example |
|--------|--------|---------|
| H1 title match | 3 points | Both pages have "Symfony Messenger" in heading |
| Shared sources (base) | 2 points | Both cite official Symfony docs |
| Shared sources (additional) | +1 per extra source | If both also cite RFC, add another point |
| Frontmatter related overlap | 4 points | Both already list each other as "related" |

**Thresholds:**
- ≥5: Strong candidate — suggest with confidence
- 3-4: Weak signal — suggest for review
- <3: Ignore (below noise floor)

> **Script Suggests, Agent Decides.** `auto-crosslink.sh` generates candidates via scoring; the agent performs semantic validation and contextual reasoning before writing crosslinks.

---

## Naming Conventions Summary

### Entity Pages (`wiki/entities/`)

Pattern: `<project-slug>-<entity-type>.md`

| Correct | Incorrect |
|---------|-----------|
| `symfony-messenger.md` | `messenger-component.md` (bare name) |
| `ai-factory.md` | (already prefixed — good example) |
| `nodejs.md` | (project IS the slug — acceptable) |

### Concept Pages (`wiki/concepts/`)

Two sub-patterns:

1. **Abstract-only** (truly framework-agnostic): bare name
   - ✅ `cache-system.md`, `hexagonal-architecture.md`, `doctrine-orm.md`
2. **Project-specific**: always prefix with project slug
   - ✅ `symfony-messaging-pattern.md`, `react-hooks-pattern.md`
   - ❌ `messaging-pattern.md` (bare name for Symfony-specific concept)

### Docs Pages (`wiki/docs/`)

Pattern: `<project-slug>-<doc-type>.md`

| Correct | Incorrect |
|---------|-----------|
| `ai-factory.md` | (already prefixed) |
| `symfony-cli-guide.md` | `cli-guide.md` (bare name) |

### Comparison Pages (`wiki/comparisons/`)

Pattern: `<a>-vs-<b>.md` — both names must be present.

| Correct | Incorrect |
|---------|-----------|
| `ai-factory-vs-pi.md` | `factory-comparison.md` (no project names) |
| `symfony-vs-laravel-messaging.md` | `messaging-comparison.md` |

### Exception List

Truly abstract concepts that don't need prefixes:
- `cache-system.md` — Universal caching patterns
- `hexagonal-architecture.md` — Clean architecture pattern, universal across frameworks
- `doctrine-orm.md` — Doctrine ORM works with any PHP framework

> **Auto-auditing:** `scripts/filename-audit.sh` scans wiki/concepts/ for violations using detection logic. Violations flagged as HIGH severity during lint (check_id=6). Require user approval before rename.

---

## Memory & Context Conventions

### Session Memory (`working_memory.json`)

Structure:
```json
{
  "last_updated": "YYYY-MM-DDTHH:MM+TZ",
  "current_mode": "discussion | silent | verbose",
  "focus_node": "Current topic or task being worked on",
  "next_steps_todo": ["task1", "task2"],
  "open_pages": [],
  "dead_ends": [],
  "query_summary": { ... }
}
```

**Rule:** Never append — read → modify in memory → write complete document. Auto-cleanup completed/outdated items before write.

### Hot Context (`wiki/hot.md`)

Markdown format with sections:
- Active Project (WORK_MODE)
- Recent Changes (`[YYYY-MM-DD] action | description`)
- System State (Active Threads, Recent Activity)

**Rule:** Update after every significant operation. Memory sync REQUIRED after dev commits.

### Grep Contract

Safe reading patterns for agent:
- ✅ Allowed: `grep -r "pattern"`, `awk '/regex/' file`, `jq '.field'`
- ❌ Never: Reading entire large files (>1MB), scanning all JSON at once without filtering

> **Why?** To prevent context bloat — agent only reads what's relevant to current step.

---

## Quick Reference Card

| Convention | Rule | Example |
|------------|------|---------|
| **Commit format** | `<type> \| <scope>: <desc>` | `feat \| lint: add check_12` |
| **Frontmatter date** | Current system date only | `date: 2026-07-08` |
| **Tag count** | 3-7 per page, no generics | `symfony`, `messaging-bus`, `php-framework` |
| **Evidence grade** | Auto-computed, never manual | `documented > corroborated > assertion_only` |
| **Internal links** | `[text](wiki-relative.md)` | `[[symfony-messenger]](entities/symfony-messenger.md)` |
| **External links** | Canonical HTTP/HTTPS only | No raw paths, no relative external URLs |
| **Naming** | Project prefix mandatory except abstract | `symfony-messenger.md` not `messenger-component.md` |

---

## Next Steps

For more detail:
- [`docs/architecture.md`](architecture.md) — How conventions fit into the layer architecture
- [`docs/wiki-structure.md`](wiki-structure.md) — Page creation workflow with all convention references
- [`docs/rules-reference.md`](rules-reference.md) — Full rule descriptions and lookup table
