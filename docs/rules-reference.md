# Rules Reference Guide

Complete reference for all rules in `rules/*.json`. These are the technical specs extracted from AGENTS.md — lazy-loaded via `schema_ref` only when a process step requires them. This keeps context lean (~86KB total instead of bloating with inline instructions).

---

## How Rules Work

Rules live in `rules/*.json` as structured JSON schemas. They define:
- **Conventions** (naming, link format, commit format)
- **Algorithms** (crosslink scoring, contradiction resolution cascade)
- **Policies** (source authority grading, search strategy)
- **Protocols** (error handling, memory lifecycle)

> **Agent reads rules on demand** — via `schema_ref` in process files. Never loads all rules at once. Example: `"rule": "rules/link_conventions.json#EXT-LINK-V1"` → agent fetches only that rule when writing a page.

---

## Rules Index (Alphabetical)

| Rule File | Purpose | When Read |
|-----------|---------|-----------|
| [`auto_rebuild_metadata.json`](../rules/auto_rebuild_metadata.md) | Metadata rebuild modes per process | Before wiki edit |
| [`auto_update_index.json`](../rules/auto_update_index.md) | Index.md auto-update triggers and format | During page creation |
| [`batch_ingest_trigger.json`](../rules/batch_ingest_trigger.md) | Cluster detection (≥3 related sources → batch ingest) | During source analysis |
| [`broken_link_handling.json`](../rules/broken_link_handling.md) | Broken link resolution tree + auto-fix thresholds | On broken link detected |
| [`categories.json`](../rules/categories.md) | Wiki category definitions, routing rules, labels | On every page creation |
| [`compounding_workflow.json`](../rules/compounding_workflow.md) | Compound answer → save decision (when to create new wiki page) | After query synthesis |
| [`context-scopes.json`](../rules/context_scopes.md) | Context window allocation per process phase | Session start |
| [`contradiction_resolution.json`](../rules/contradiction_resolution.md) | Priority cascade: Code Reality > Live State > Documentation | When contradiction detected |
| [`date_convention.json`](../rules/date_convention.md) | Date formatting rules, system date vs source date | On page creation/update |
| [`delta_tracking.json`](../rules/delta_tracking.md) | Hash-based source deduplication logic | Before ingest |
| [`error_handling.json`](../rules/error_handling.md) | Detect → analyze → resolve → continue protocol | On process failure |
| [`evidence_grade.json`](../rules/evidence_grade.md) | Auto-computed evidence levels: documented > corroborated > assertion_only | During page creation |
| [`execution_contract.json`](../rules/execution_contract.md) | Proposal → Action (no permission stops) contract | Session start |
| [`execution_modes.json`](../rules/execution_modes.md) | Silent/verbose flag management and output contracts | Per turn |
| [`external_sources_policy.json`](../rules/external_sources_policy.md) | Wiki create/update routing from external sources | Page write operation |
| [`faq_summary.json`](../rules/faq_summary.md) | Summary page creation triggers, lifecycle (decay/merge/update), frontmatter template | Before summary page op |
| [`git_conventions.json`](../rules/git_conventions.md) | Commit format, staging modes, memory sync requirements | **Before every commit** |
| [`language_policy.json`](../rules/language_policy.md) | Language conventions: English headers, bilingual content | Page creation/update |
| [`link_conventions.json`](../rules/link_conventions.md) | Link format, crosslink scoring algorithm, auto-fix thresholds | On page creation/update |
| [`naming_conventions.json`](../rules/naming_conventions.md) | Project prefixing — prevent filename collision across projects/frameworks | Page creation/update |
| [`non_blocking_lint.json`](../rules/non_blocking_lint.md) | Lint checks, quiet mode, cron safety (non-blocking by design) | Before lint execution |
| [`path-guard-check.json`](../rules/path_guard_check.md) | Path validation guardrails for raw/ writes | Before any write to wiki/raw |
| [`protected_zones.json`](../rules/protected_zones.md) | Protected zones that agents must not edit directly (wiki/index.md, meta/, etc.) | Before writing |
| [`search_strategy.json`](../rules/search_strategy.md) | Search tools, fallback chain, scoring hierarchy | During query workflow |
| [`session_bootstrap.json`](../rules/session_bootstrap.md) | Session bootstrap load sequence: WM → hot.md → rules | **At session start** |
| [`session_context_rules.json`](../rules/session_context_rules.md) | Memory architecture: layers, save triggers, grep contract | **Every memory operation** |
| [`silent_output.json`](../rules/silent_output.md) | Output contract (final results only, suppress intermediate noise) | Session start |
| [`skill_format.json`](../rules/skill_format.md) | Wiki skill format spec — sections, naming convention (-skill.md suffix), dependencies | On skill creation/ingest |
| [`skill_safety_check.json`](../rules/skill_safety_check.md) | Safety validation before importing external skills (no malicious code patterns) | Before external skill import |
| [`skill_search_sources.json`](../rules/skill_search_sources.md) | Curated source list for external skill search (skills.sh, GitHub org repos) | When local skills don't match query |
| [`snapshot_format.json`](../rules/snapshot_format.md) | Snapshot lifecycle: create/update/archive format and triggers | Before snapshot operation |
| [`structural_requirements.json`](../rules/structural_requirements.md) | Page structure validation — FIRST-BLOCK-V1, mandatory sections per category | On page creation/update |
| [`tag-guidelines.json`](../rules/tag_guidelines.md) | Tag patterns, aliases system, enforcement rules, prohibited generics | On page creation/update |
| [`work_modes.json`](../rules/work_modes.md) | Mode determination algorithm (discussion vs silent vs verbose) | Before context decisions |

---

## Detailed Rule Descriptions

### Categories (`categories.json`)

Defines all wiki categories with labels in English and Russian: entities, concepts, syntheses, comparisons, overviews, notes, meetings, projects, bibliography, resources, docs. The agent reads this file on every page creation — never hardcodes category definitions. New categories added automatically propagate through auto-crosslink routing.

### Link Conventions (`link_conventions.json`)

Internal link format: `[text](wiki-relative-path.md)` — dot-relative (`./`) prohibited, cross-category links use `../`. External links: canonical HTTP/HTTPS URLs only, never raw paths. Crosslink scoring algorithm with 3 levels: H1 title match (weight 3), shared sources (weight 2 + diminishing factor), frontmatter related (weight 4). Thresholds: ≥5 = strong candidate, 3-4 = weak signal, <3 = ignore.

### Git Conventions (`git_conventions.json`)

Commit format: `<type> | <scope>: <description>` with types: feat, fix, refactor, schema, lint, ingest, query. Mode detection from changes: only `wiki/*.md` → wiki mode; any `.sh/.json/py/md` in root/rules/scripts/ → dev mode. Memory sync REQUIRED after dev commits (update WM + hot.md). Never use `git add *` or `git commit -a`.

### Contradiction Resolution (`contradiction_resolution.json`)

Priority cascade: Code Reality (#1, always wins) > Live State (#2, temporal decay) > Documentation (#3). Objective facts never allow user override; subjective facts do. Evidence sub-priority: documented (highest) > corroborated > assertion_only (lowest). Resolution actions: add update section to old page, create comparison page for complex conflicts, or note in answer if unresolved.

### Evidence Grade (`evidence_grade.json`)

Auto-computed during ingest based on source authority. Three levels: `documented` (authoritative sources like official docs), `corroborated` (confirmed by 2+ independent sources), `assertion_only` (unconfirmed or from weak sources). Never set manually — only assigned by agent from source analysis. Used in contradiction resolution as sub-priority for documentation sources.

### Error Handling (`error_handling.json`)

Golden rule: "Error ≠ stop. Every error is a signal for action, not reason to stall." 4-step protocol: detect & log → analyze root cause → resolve (local-fix / schema-patch / source-conflict / dead-end) → continue. Resolution strategies depend on error type: path/link problems get local fixes; schema conflicts get proposed patches; grep noise gets strategy change.

### Tag Guidelines (`tag-guidelines.json`)

All pages MUST have 3-7 tags in pattern `{domain-entity} + {specific-concept} + {technology/role}`. Prohibited generics: architecture, admin, ai, cms, framework, tool, workflow, testing, knowledge-base, platform. Aliases system for discoverability (product names, common synonyms). Cross-reference enforcement: if page A links to B → both must share at least one tag. Language consistency: English preferred for tags.

### Naming Conventions (`naming_conventions.json`)

All pages prefixed with project slug except truly abstract concepts. Exception list: cache-system.md, hexagonal-architecture.md (universal patterns). Detection logic uses `scripts/filename-audit.sh` — if tags contain project-name AND filename lacks prefix → violation (unless in exception list). Auto-auditing runs during lint check_id=6.

### Delta Tracking (`delta_tracking.json`)

Hash-based source deduplication. Before ingest, source content is hashed and compared against existing hashes in `tracking/source-manifest.json`. Duplicate sources are skipped with warning; modified sources trigger re-ingest of changed sections only (not full rewrite).

### Search Strategy (`search_strategy.json`)

Search hierarchy: index.md scan → semantic search via similarity_index.json → grep fallback. Each step has scoring criteria and failure conditions that determine whether to proceed to next level. Web_search used for external source validation with domain whitelist from `tracking/domain_whitelist.json`.

### Session Context Rules (`session_context_rules.json`)

Memory architecture defines three layers: session memory (working_memory.json, per-session clear & rewrite), hot context (wiki/hot.md, current session focus), chronological log (wiki/log.md, append-only). Save triggers: after dev commits → update WM + hot.md; wiki changes → auto-cleanup completed items. Grep contract for safe reading patterns.

### Skill Format (`skill_format.json`)

Wiki skill format spec — files must end with `-skill.md` suffix. Required sections: Procedure (read/edit/write permissions), Context (trigger, outcome, complexity), Algorithm (REQUIRED step-by-step with conditional logic), Dependencies (rules paths via schema_ref), Notes (trajectory source). Naming convention strictly enforced by `scripts/filename-audit.sh`.

### Structural Requirements (`structural_requirements.json`)

Page structure validation per category. Main categories require body text between H1 and first ## heading (FIRST-BLOCK-V1). Docs pages have different rule: intro paragraph required instead, with mandatory navigation header/footer. Validation runs during lint check_id=2 for structural violations.

---

## Process-Related Rules

### Session Bootstrap (`session_bootstrap.json`)

Defines the exact load sequence at session start: `working_memory.json` → `wiki/hot.md`. If either file is missing or corrupted, session continues with defaults (non-blocking). Skill scan step included if wiki/skills/ exists.

### Execution Contract (`execution_contract.json`)

Proposal → Action contract: agent proposes changes but never auto-applies without user approval unless explicit permission granted. "No permission stops" principle — every significant write requires confirmation.

### Work Modes (`work_modes.json`)

Mode determination algorithm: discussion mode (interactive, asks questions), silent mode (background processing), verbose mode (detailed output). Mode affects how agent communicates with user and when to escalate decisions vs auto-proceed.

### Silent Output (`silent_output.json`)

Output contract for background processes — final results only, suppress intermediate noise. Used by lint.sh --quiet, batch-ingest --scan, and other non-interactive operations.

### Compounding Workflow (`compounding_workflow.json`)

Decision tree: when query result contains novel insight worth saving as new wiki page vs just delivering answer. Compound answers that synthesize ≥3 sources with unique conclusions → propose save. Simple fact retrieval → deliver only.

---

## Quality & Validation Rules

### Non-Blocking Lint (`non_blocking_lint.json`)

Lint always runs quietly and never blocks agent workflow. Reports issues but proposes fixes rather than auto-applying (unless explicit permission). Cron safety: designed to run without user interaction, exits 0 even when issues found.

### Path Guard Check (`path-guard-check.json`)

Guardrails preventing direct edits to protected zones. Raw sources immutable — only through capture → integrate flow. Wiki system files (index.md, overview.md, log.md) managed by rebuild-meta.sh. Rules directory never edited directly except via schema-patch workflow.

### Protected Zones (`protected_zones.json`)**

Explicitly lists directories/files that agents must not edit directly:
- `meta/*` — auto-generated, rebuilt by scripts
- `tracking/*.json` (except raw_registry.json) — regenerated state files
- System wiki pages — managed via process workflows only

### Broken Link Handling (`broken_link_handling.json`)

Resolution tree for broken links in wiki pages. Score ≥80 → auto-fix with permalink generation; score <80 → escalate non-blocking (report to user, wait for approval). External link unavailability checked before writing; 404s logged but not auto-removed from content.

### Date Convention (`date_convention.json`)

Frontmatter `date` = current system date (YYYY-MM-DD), never derived from source filename or commit dates. Log entries format: `## [YYYY-MM-DD] action | description`. Timestamps in JSON: ISO-8601 format with timezone offset. Enforced by lint.sh check_id=6.

### Snapshot Format (`snapshot_format.json`)

Lifecycle management for wiki/snapshot.md — one-page summary of current facts. Create (initial generation), update (triggered when ≥3 pages change), archive (when snapshot gets stale). Output format: structured YAML with categories, page counts, last rebuild timestamp.

---

## External Sources & Skills

### External Sources Policy (`external_sources_policy.json`)

Routing for external sources to wiki: URLs → classify authority → route to appropriate category. Web search results tagged as `"web_search"` in sources array. Never commit raw web content directly — always through ingest flow with proper frontmatter and crosslinks.

### Skill Search Sources (`skill_search_sources.json`)

Curated list of repositories where agent looks for quality skill definitions: skills.sh, GitHub org repos. No ad-hoc random search — strict source list prevents importing low-quality or malicious code.

### Skill Safety Check (`skill_safety_check.json`)

Validation rules before importing external skills: no malicious code execution patterns, no credential harvesting signatures, reasonable scope (not full frameworks). References evidence_grade.json for authority scoring of skill sources.

---

## Memory & Context Rules

### Session Bootstrap (`session_bootstrap.json`)

Explicit load sequence at session start. Step 1: read working_memory.json (if exists) → extract focus_node, next_steps_todo. Step 2: read wiki/hot.md → get current session context. Non-blocking: if either file missing, continue with defaults.

### Session Context Rules (`session_context_rules.json`)

Three memory layers defined:
1. **Session memory** — working_memory.json (bridge between turns)
2. **Hot context** — wiki/hot.md (current session focus)
3. **Chronological log** — wiki/log.md (permanent action history)

Save triggers, auto-cleanup rules, and grep contract for safe reading patterns to prevent context bloat.

### Context Scopes (`context-scopes.json`)

Defines how context window is allocated across different process phases. Each phase has a token budget; exceeding it triggers compactification or truncation strategies to stay within limits.

---

## Auto-Generated & Index Rules

### Auto Update Index (`auto_update_index.json`)**

Triggers for auto-updating wiki/index.md: new page creation, category changes, structural fixes. Format specification: hierarchical listing by category with summaries per page. Never manually edited — always via rebuild-meta.sh output.

### Auto Rebuild Metadata (`auto_rebuild_metadata.json`)

Rebuild modes per process type: full rebuild (after dev commits), incremental (on wiki-only changes), index-only (--index-only flag). Optimization notes for single-pass wiki-walk approach that eliminates N separate JSON reads.

### Batch Ingest Trigger (`batch_ingest_trigger.json`)

Trigger conditions for batch processing ≥3 related sources: same project tags, shared entity mentions, sequential topic clusters. Output format: cluster array with suggested page names and crosslinks. Runs via `scripts/batch-ingest.sh --scan`.

---

## Decision & Language Rules

### Decision Rules (`decision-rules.md`)

Markdown supplement to JSON rules — captures decision trees that don't fit cleanly into JSON schemas. Covers contradiction arbitration, user override boundaries, and escalation paths for unresolved conflicts.

### Language Policy (`language_policy.json`)

Language conventions: section headers always English (structural anchors), page content follows source language (bilingual allowed). Agent responses translate headers to match user's question language. Mixed-language pages encouraged for bilingual sources — no restriction on code-mixing in body text.

---

## Quick Reference: Rule Lookup by Scenario

| Scenario | Read This Rule |
|----------|---------------|
| Creating a new wiki page | `categories.json`, `naming_conventions.json`, `tag-guidelines.json`, `link_conventions.json`, `structural_requirements.json` |
| Resolving contradictions | `contradiction_resolution.json`, `evidence_grade.json` |
| Running lint checks | `non_blocking_lint.json`, `error_handling.json` |
| Committing changes | **`git_conventions.json`** (MUST read before every commit) |
| Querying the wiki | `search_strategy.json`, `session_context_rules.json` |
| Ingesting a new source | `delta_tracking.json`, `evidence_grade.json`, `external_sources_policy.json` |
| Managing memory/context | `session_context_rules.json`, `work_modes.json`, `silent_output.json` |
| Creating a skill from trajectory | `skill_format.json`, `naming_conventions.json` |
| Importing external skills | `skill_search_sources.json`, `skill_safety_check.json` |

> **Schema_ref pattern:** Process files reference rules via `"rule": "rules/<name>.json"` — agent reads only what's needed, when it's needed. This keeps context lean and prevents bloat.

---

## Next Steps

For more detail:
- [`docs/architecture.md`](architecture.md) — How rules fit into the layer architecture
- [`docs/wiki-structure.md`](wiki-structure.md) — Page creation workflow with rule references
- `AGENTS.md#6-agent-rules-conventions-rules` — Canonical source for all rules
