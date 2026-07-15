# Rules Reference Guide

Technical specs for `rules/*.json`, lazy-loaded via `schema_ref`. Compactified per RULES.md §9 (R01-R07): minimal verbosity, conditional logic preserved, examples as when/action constructs.

> **All rule files compactified 2026-01:** removed redundant descriptions, merged overlapping sections, converted verbose lists to compact tables. Total context savings: ~500 tokens.

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

Wiki category definitions with routing rules.

### Link Conventions (`link_conventions.json`)

Internal link format + crosslink scoring algorithm (Script Suggests, Agent Decides).

### Git Conventions (`git_conventions.json`)

Commit format, staging modes, memory sync requirements. **MUST read before every commit.**

### Contradiction Resolution (`contradiction_resolution.json`)

Priority cascade: Code Reality > Live State > Documentation.

### Evidence Grade (`evidence_grade.json`)

Auto-computed evidence levels during ingest: documented > corroborated > assertion_only.

### Error Handling (`error_handling.json`)

4-step protocol: Detect → Analyze → Resolve → Continue. Resolution strategies per error type.

### Tag Guidelines (`tag-guidelines.json`)

Tag patterns (3-7), aliases system, prohibited generics, cross-reference enforcement.

### Naming Conventions (`naming_conventions.json`)

Project prefixing rules + exception list for universal patterns.

### Delta Tracking (`delta_tracking.json`)

Hash-based source deduplication before ingest.

### Search Strategy (`search_strategy.json`)

Primary tool, fallback chain, intent analysis, scoring weights.

### Session Context Rules (`session_context_rules.json`)

Memory architecture: layers, save triggers, grep contract.

### Skill Format (`skill_format.json`)

Wiki skill format spec — sections, naming convention (-skill.md suffix), dependencies.

### Structural Requirements (`structural_requirements.json`)

Page structure validation per category (FIRST-BLOCK-V1).

---

## Process-Related Rules

### Session Bootstrap (`session_bootstrap.json`)

Load sequence at session start: WM → hot.md.

### Execution Contract (`execution_contract.json`)

Proposal → Action (no permission stops).

### Work Modes (`work_modes.json`)

Mode determination algorithm: discussion / silent / verbose.

### Silent Output (`silent_output.json`)

Output contract for background processes — final results only.

### Compounding Workflow (`compounding_workflow.json`)

Decision logic: when query answer should be saved as new wiki page.

---

## Quality & Validation Rules

### Non-Blocking Lint (`non_blocking_lint.json`)

Lint checks, quiet mode, cron safety.

### Path Guard Check (`path-guard-check.json`)

Path validation guardrails for raw/ writes.

### Protected Zones (`protected_zones.json`)

Directories/files agents must not edit directly.

### Broken Link Handling (`broken_link_handling.json`)

Broken link resolution tree + auto-fix thresholds.

### Date Convention (`date_convention.json`)

Date formatting rules, system date vs source date.

### Snapshot Format (`snapshot_format.json`)

Snapshot lifecycle: create/update/archive format and triggers.

---

## External Sources & Skills

### External Sources Policy (`external_sources_policy.json`)

Wiki create/update routing from external sources.

### Skill Search Sources (`skill_search_sources.json`)

Curated source list for external skill search.

### Skill Safety Check (`skill_safety_check.json`)

Safety validation before importing external skills.

---

## Memory & Context Rules

### Session Bootstrap (`session_bootstrap.json`)

Session bootstrap load sequence: WM → hot.md → rules.

### Session Context Rules (`session_context_rules.json`)

Memory architecture: layers, save triggers, grep contract.

### Context Scopes (`context-scopes.json`)

Context window allocation per process phase.

---

## Auto-Generated & Index Rules

### Auto Update Index (`auto_update_index.json`)

Index.md auto-update triggers and format.

### Auto Rebuild Metadata (`auto_rebuild_metadata.json`)

Metadata rebuild modes per process.

### Batch Ingest Trigger (`batch_ingest_trigger.json`)

Cluster detection (≥3 related sources → batch ingest).

---

## Decision & Language Rules

### Decision Rules (`decision-rules.md`)

Markdown supplement to JSON rules — decision trees that don't fit cleanly into JSON schemas.

### Language Policy (`language_policy.json`)

Language conventions: English headers, bilingual content.

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
