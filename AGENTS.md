# Loomana: Wiki Schema, Agent Instructions & Conventions

## What This Is

This is an **LLM-powered personal knowledge base** — a wiki that grows with every source and question. Full project name: `Loomana`; short name: `loom`.

_Idea: [Andrej Karpathy](https://karpathy.ai/). Reference: [LLM Wiki gist](https://gist.github.com/karpathy/ed8f284379605148297b7a8be01eb580)._

---

## 📋 Overview

This document defines the wiki's structure, conventions, and workflows. It serves as the single source of truth for how the agent should operate when:

- Ingesting new sources
- Answering questions through the knowledge base
- Maintaining and performing health-checks on the wiki

This Schema **co-evolves** with the user, updating alongside accumulated experience.

---

## 🧠 Context Management — All Rules Transient (Phase 32)

### Why This Matters

AGENTS.md and process files (`process-ingest.json`, `process-query.json`, `process-lint.json`) together occupy ~86KB of context. This is excessive session context.

**Problem**: Agent retains all rules in context even after process completion → memory bloat.

**Solution**: ALL rules are Transient — read fresh from source before every action. No persistent memory needed because:

- `agent_read_instructions` in each process file mandates reading AGENTS.md before execution
- This guarantees context refresh at EVERY process start, regardless of when session began

### How It Works (v2.0)

```json
{
  "scope_definition": "rules/context-scopes.json",
  "policy": "ALL rules Transient — read fresh from source files on demand"
}
```

**Agent reads fresh from source files only when needed:**

- AGENTS.md → before EVERY process (auto-read via `agent_read_instructions` in process files)
- Process-specific rules → only during active process, forget after completion
- Hybrid rules (templates, link conventions) → read when actively working on that topic
- NEVER stores any rule content in persistent memory beyond the current turn

### Context Management Rules

1. **Session start**: DO NOT load any rules into persistent memory.
2. **Process start**: Agent MUST read AGENTS.md (per `agent_read_instructions` in process file), then read process-specific transient rules.
3. **Process complete**: Forget all transient rules unless user says "keep this".
4. **Read on demand**: For hybrid rules → read from source only when actively working on that topic.

### Schema Reference

- Full scope definitions: `rules/context-scopes.json` (v2.0)
- Auto-read mechanism in process files: `agent_read_instructions` field mandates AGENTS.md refresh

> Schema ref: `rules/context-scopes.json`.

### Current Scope Breakdown

**ALL rules are Transient:**

- ✅ Memory contract, execution contract, error handling → read fresh from AGENTS.md
- ✅ Git conventions, protected zones, silent output → read fresh when needed
- ✅ Page templates, link conventions, crosslinks → read on demand
- ✅ Process-specific rules → read only during active process

**Result**: Zero persistent context bloat — agent always reads latest version of every rule.

---

## 📍 Roadmap & Project Plan (Development Mode)

- **[PLAN.md](PLAN.md)** — project roadmap: phase statuses, pending phases, integration fixes (IF-1..IF-4), theoretical questions. **Always read before starting work** — determines priorities and context.
- **[FEATURES_PLAN.md](FEATURES_PLAN.md)** — implementation plan for architectural improvements based on research (ingest algorithms comparison): advisory locking, background synthesis, contradiction flagging, mode-aware routing, address assignment.
- **[wiki/issues.md](wiki/issues.md)** — bug registry and known issues. Documents found bugs, logs fixes. **Read issues.md during ingest/query/lint** — to avoid duplicating known problems and understand system limitations.

### 🛠 Code Conventions

During the period of script writing and debugging, the following code development standard applies: [RULES.md](RULES.md).

#### JSON Instruction Compactification (R01-R07)

Before working with `process-*.json` and `rules/*.json`: read §9 INSTRUCTION COMPACTIFICATION from [RULES.md#instruction-compactification](RULES.md#9-instruction-compactification) + apply `.pi/skills/compact-json-instructions/SKILL.md` criteria to remove verbosity without losing logic (R07: preserve examples that form conditional `if/else` behavior).

---

## 🔖 Git Conventions

Commit format, staging modes, pre-commit workflow (incl. prohibited commands), memory sync triggers → `rules/git_conventions.json`.

> Agent reads this file before every commit.

---

## 🔄 Process Roles

Three role files — each defines its full workflow:
- **Ingest**: `process-ingest.json`
- **Query**: `process-query.json`
- **Lint**: `process-lint.json`

> Agent reads process file before starting work. No inline definitions.

### Batch Ingest Trigger

`scripts/batch-ingest.sh --scan` — clusters ≥3 related sources by shared entities → JSON for user decision-making.

**Trigger**: User provides multiple files or agent receives ≥3 related sources.

> Details: `rules/batch_ingest_trigger.json`.

---

## 🏗 Architecture Layers

### 1. Raw Sources (`raw/`)

- Immutable collection of original documents, articles, images, data
- Agent reads from them but does not modify directly
- Write access restricted via `scripts/validate-path.sh` guardrails
- All changes only through: capture → integrate flow (never direct edits)

### 2. The Wiki (`wiki/`)

- Directory of LLM-generated markdown files, organized by type
- Agent owns this layer fully — creates pages, updates them, maintains cross-references
- User reads; agent writes and maintains

```json
{
  "structure": {
    "entities/": "specific identifiable objects (people, companies, technologies)",
    "concepts/": "abstract ideas, principles, methodologies",
    ...
    # Full category list → [rules/categories.json](rules/categories.json) — canonical source
    # Agent reads order and labels from JSON, never hardcodes
    "assets/images/": "copies of original images (.png, .jpg, .jpeg, .gif)",
    "assets/descriptions/": "markdown descriptions of images: OCR + entities + metadata",
    "wiki/snapshot.md": "one-page snapshot of current facts from all wiki pages (see below)"
  }
}
```

> **Categories under wiki/** are listed in [rules/categories.json](rules/categories.json). Agent always reads them from there — never hardcodes.

#### Assets & Media Pipeline (`raw/assets/images/`, `raw/assets/descriptions/`)

Two related subdirectories for image work:

| Subdirectory               | Purpose                                              | Format         |
| -------------------------- | ---------------------------------------------------- | -------------- |
| `raw/assets/images/`       | Copies of original images (.png, .jpg, .jpeg, .gif)  | Binary files   |
| `raw/assets/descriptions/` | Markdown descriptions with OCR, entities and metadata | `.md` files    |

**Image ingest workflow:**

1. Image copied to `raw/assets/images/` via capture flow
2. Agent extracts: OCR text, identifies entities in image, generates metadata
3. Description saved as `.md` in `raw/assets/descriptions/` with name matching original image
4. Image link added to wiki page via wikilink: `![[raw/assets/images/filename.png]]`
5. Description file links back to the wiki page via frontmatter `related` field

**Conventions:**

- File names: snake_case with context prefix (e.g., `diagram_architecture_overview.png`)
- Description files contain: `[OCR text]`, `[entities detected]`, `[metadata: dimensions, format, date_ingested]`
- Agent auto-generates descriptions during ingest — no manual filling required

> Media pipeline is a workflow description (not a rule) — kept inline. Brief ref to asset conventions in process files.

### 3. Summary / FAQ Pages (`wiki/syntheses/`)

Creation triggers, lifecycle rules (decay/merge/update), frontmatter template → `rules/faq_summary.json`.

> Agent reads this file before any summary page operation.

### 4. Schema (this document)

- Defines wiki structure, conventions, and workflows
- Makes the agent a disciplined wiki custodian, not a general chatbot
- Co-evolves between human and agent per Karpathy's original idea

### 5. Context Bridge (`working_memory.json`)

- Bridge file between sessions — preserves focus, open_pages, dead_ends, next_steps_todo
- Agent reads at session start → rewrites on completion
- **Clear & Rewrite Rule**: Never append to JSON files. Always read the entire file → modify in memory → write back the complete document.
  - This prevents key duplicates that arise when agent writes over old content without clearing.
  - Example: if `focus_node` changes value — agent must completely rewrite the file, not just add new key on top.
- **Auto-cleanup Rule**: Before every write() to working_memory.json, agent must filter out completed/outdated elements from arrays. Never append to existing arrays without cleanup.
  - `next_steps_todo`: delete tasks with status `completed` or no longer relevant
  - `broken_links_resolved`: **do not delete** — this is audit trail, add new entry on top
  - `open_pages`, `dead_ends`: clean after session close (dismiss all read)
  - Example: if task completed — remove it from `next_steps_todo` before write()
- Does not duplicate wiki — stores only session metadata (not the pages themselves)

**Canonical rules source**: `rules/session_context_rules.json` defines complete algorithm for memory layer work (working_memory.json, wiki/hot.md, wiki/log.md), save_triggers, and read_algorithm. Agent reads this file before every memory action.

> Schema ref: `rules/session_context_rules.json`.

**Format:**

```json
{
  "last_updated": "YYYY-MM-DDTHH:MM:SS+TZ",
  "current_mode": "query | ingest | discussion | project | lint",
  "focus_node": "[page_name] — what agent is doing right now",
  "open_pages": [
  {"path": "wiki/entities/pi-coding-agent.md", "status": "reading" | "updating"}
  ],
  "dead_ends": [
  {"approach": "grep across all wiki", "reason": "too much noise, wiki/index.md works better"}
  ],
  "query_summary": {
  "intent": "What user was looking for",
  "pages_read": ["list of read pages"],
  "key_findings": ["3-5 points"]
  },
  "next_steps_todo": [
  {"task": "Create synthesis on RAG vs LLM Wiki Pattern", "priority": "high"}
  ]
}
```

---

### 6. Agent Rules & Conventions (`rules/`)

- Directory of technical specifications and niche instructions moved from AGENTS.md to reduce context bloat.
- Format: **JSON or Markdown** — choose based on content nature:
  - JSON → structured data, algorithms, arrays/objects, machine-parseable rules
  - Markdown → procedural text, narrative explanations, template structures, human-readable workflows
- No format restrictions — match the medium to the message
- Contains rules: `protected_zones.json`, `error_handling.json`, `execution_contract.json`, `link_conventions.json`, `search_strategy.json`, `tag-guidelines.json`, `session_context_rules.json`, and others.
- AGENTS.md contains links (`schema_ref`) to these files instead of duplicating — agent reads rule only when it needs to apply it.

---

## 📄 Page Templates & Frontmatter

### ⚠️ Global Rule: Template Editing Policy

> **Free editing of shared templates is prohibited.** Any changes to the `Page Templates` section or their structural elements require user approval.
>
> All templates are a shared contract between agent and user. Agent may propose improvements via `[schema-patch]`, but not apply independently.

---

### 📋 Universal Frontmatter (All Types)

**Mandatory section for all document types.** Machine-readable metadata, uniform regardless of page type.

```yaml
---
tags: [] # recommended keyword-tags for classification and search — see rules/tag-guidelines.json
date: YYYY-MM-DD # current system date (not from source!)
type: documentation # reality layer: documentation | code_reality | live_state
category: entity # wiki section: entity | concept | synthesis | comparison | note | project | bibliography | resource
aliases: [] # discoverability synonyms — words user actually types in query, see rules/tag-guidelines.json#aliases_system
sources: [] # where data comes from (raw/..., wiki paths, web_search)
related: [] # related wiki pages (wiki-relative paths)
---
```

**Fields:**
| Field | Required | Description |
|-------|----------|-------------|
| `tags` | ✅ | Recommended array of keyword-tags (3-7 tags) for classification, search, and organization. Agent receives recommended patterns from `rules/tag-guidelines.json`. Domain-specific tags required — generic tags prohibited. Examples: `symfony`, `hexagonal-architecture`, `doctrine`, `phpunit` (not `entity/concept`). |
| `date` | ✅ | Current system date in YYYY-MM-DD format. Never derived from source filename or commit dates. |
| `type` | ✅ | Reality layer — data credibility level: `documentation` (docs/articles/blogs), `code_reality` (machine-verifiable code, GitHub issues/PRs), `live_state` (ephemeral metrics, API responses, logs). Used in contradiction resolution cascade algorithm. |
| `category` | ✅ | Wiki section page belongs to: `entity`, `concept`, `synthesis`, `comparison`, `note`, `project`, `bibliography`, `resource`. Determines where to place page (entities/, concepts/, syntheses/, comparisons/). |
| `aliases` | ⚠️ Recommended | Array of discoverability-synonyms — words user actually types in queries. Include product names, synonyms, author references, bilingual variants (EN/RU). Never put architecture terms as aliases. Canonical: `rules/tag-guidelines.json#aliases_system`. |
| `sources` | ✅ | List of data sources: raw source paths, wiki-relative paths, or `web_search` marker. Can contain any sources — not only raw/. |
| `related` | ✅ | Array of wiki-relative paths to related pages (e.g., `[wiki/entities/symfony.md]`). Empty array means "no connections". |

---

### 🔍 Auto-computed Fields (Agent-level)

Some fields are automatically computed during ingest — no manual filling required.

- **evidence_grade**: auto-assigned based on source authority → `rules/evidence_grade.json`

> Schema ref: `rules/evidence_grade.json`.

---

### 🌐 Language Policy

- Section headers in templates: **always English** (`## Definition`, etc.) — structural anchors.
- Page content: follows source language. Bilingual allowed.
- Agent responses: translate headers to match user's question language.
- Mixed-language pages: encouraged when reflecting bilingual sources.

> Details: `rules/language_policy.json`.

---

### 🔄 Template Co-evolution Process

1. **Agent proposes** structural improvement → log via `process-ingest.json#schema_evolution`
2. **User reviews and approves** → agent commits update
3. **New scenarios detected** → discussed in context.md → added to schema
4. **Never auto-modify templates** — always user-approved changes

---

### 📐 Template Files

Detailed page templates stored in `wiki/templates/`.

> Templates are **recommended**, not enforced. Agent may add/remove sections as needed.
>
> **Frontmatter composition is fixed and defined only by Universal Frontmatter section — no template-specific field lists allowed.** Any changes to frontmatter fields require updating scripts that enforce the schema.

**Canonical**: `AGENTS.md#template_files`

---



### Compounding Workflow

**Schema ref**: `rules/compounding_workflow.json`

Answer is considered compound (requires saving as new wiki page) if synthesis from ≥2 wiki pages produces novel insight, contradiction resolved between sources, or existing entity/concept supplemented with new facts → **propose save to user**. Synthesis = new logical conclusion (A+B→C), not mere aggregation.

> Full decision logic: `rules/compounding_workflow.json` — scoring system, duplicate check, web source transitions.

---

### Wiki Snapshot (`wiki/snapshot.md`)

**Purpose**: One-page active projects context — loaded only when WORK_MODE=project AND snapshot has entry for this project.

**Format & lifecycle rules**: `rules/snapshot_format.json` — structure, triggers (create/update/archive), load conditions.

> Agent: never load snapshot.md unless user is working on a project. Session starts with wiki/index.md + overview.md.

---

## 🧠 User Work Modes

**Schema ref**: `rules/work_modes.json` — full specification of 5 work modes with compaction policies, session persistence rules, and mode determination algorithm.

> Agent reads this file before any context management decision. Contains conditional behavior logic (R07-compliant).
---

---

## 🧠 Memory Architecture Contract (system rules)

Full specification for memory layers, save triggers, read patterns, grep contract, compaction handling → **see [rules/session_context_rules.json](rules/session_context_rules.json)**.

> Canonical: `rules/session_context_rules.json` — full specification for memory architecture, save triggers, read patterns, constraints.

### Three-Layer Model Summary

| File | Role | Lifespan | RW |
|------|------|----------|----|
| **working_memory.json** | Current-session operational memory (focus_node, next_steps_todo) | Short: one session | Agent writes every turn |
| **wiki/hot.md** | Long-term snapshot — active project/session context. Survives compaction via restore-hot-cache.sh | Between sessions | Agent writes snapshot |
| **wiki/log.md** | Append-only chronicle of actions and wiki changes | Forever | Agent appends only |

**Quick interaction flow**: Session start → read WM → restore-hot-cache.sh → grep log (last 20 entries). Session end → write to WM → write snapshot to wiki/hot.md.

> Full details: `rules/session_context_rules.json#flow` and `rules/session_context_rules.json#constraints`.

---

## ⚡ Execution Contract — Proposal → Action, Never Stop at "Shall I run it?"

Agent never stops after proposing a plan or asking permission to execute. Full rules and trap patterns in extracted file.

> Schema ref: `rules/execution_contract.json`.
---


---

## 🤫 Silent-Only Output Contract

Agent shows only final results. All intermediate operations go to `wiki/log.md` via append — user does not see them. Full rules in extracted file.

> Schema ref: `rules/silent_output.json`.
---


## ⚙️ Execution Modes

Agent manages two independent modes:

| Flag             | Values                       | Stored In                                              |
| ---------------- | ---------------------------- | ------------------------------------------------------ |
| `current_mode`   | `query` / `ingest` / `project` | working_memory.json (defines **what** agent does)      |
| `execution_mode` | `silent` / `verbose`         | working_memory.json (defines **how** results shown)    |

**Rules:**

- Default: `execution_mode = "silent"`. Does not output agent reasoning, invoked commands and their results to user. Shows only final answer.
- Trigger: user explicitly asks `"verbose"`, `"debug mode"`, `"show steps"` → agent sets `"verbose"` in WM and works one turn.
- Auto-reset: after verbose-answer agent resets to `"silent"`.
- Explicit reset: user says `"quiet"`, `"silent"`, `"less"` → instant reset.

> Schema ref: `rules/execution_modes.json`.

## 📅 Date Convention Rule

- Frontmatter `date` = **current system date** (never derive from source filename / git commit dates)
- Log entries: `## [YYYY-MM-DD] action | description`
- Timestamps in JSON: ISO-8601 `YYYY-MM-DDTHH:MM:SS+TZ`

> Enforced by: `lint.sh check_id=6` (date_consistency_check).

---

## 🔧 Auto-Rebuild Metadata & Non-blocking Lint

### Schema References

- **Auto-rebuild**: `rules/auto_rebuild_metadata.json` — modes, triggers per process (ingest→full, query→post-check, lint→index-only)
- **Non-blocking lint**: `rules/non_blocking_lint.json` — check table, usage rules (quiet mode, skip flags), cron safety

> Agent: read these files when you need to know which rebuild mode to use and how to call lint.sh.

---

## 🔄 Schema Inheritance & Routing

> Rule: never duplicate AGENTS.md rules in process files. Always add `schema_ref` to canonical source.

All canonical references are in the schema_ref field of each process file (`process-ingest.json`, `process-query.json`, `process-lint.json`). Agent reads them from there.

### Wiki Operation Routing Contract

**Schema ref**: `rules/external_sources_policy.json` — full routing contract for wiki create/update operations.

---
