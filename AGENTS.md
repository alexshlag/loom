# Loomana: Wiki Schema, Agent Instructions & Conventions

## What This Is

This is an **LLM-powered personal knowledge base** — a wiki that grows with every source and question. Full project name: `Loomana`; short name: `loom`.

_Idea: [Andrej Karpathy](https://karpathy.ai/). Reference: [LLM Wiki gist](https://gist.github.com/karpathy/ed8f284379605148297b7a8be01eb580)._

---

## Overview

This document defines the wiki's structure, conventions, and general concepts. Agent reads this at session start for context.

Process-specific workflows → `process-ingest.json`, `process-query.json`, `process-lint.json`
Niche technical specs → `rules/*.json` (read on demand via schema_ref)

---

## Context Management — All Rules Transient

**Problem**: ~86KB accumulated context → memory bloat.

**Solution**: All rules Transient — read fresh from source, forget after use.

### How It Works

- **AGENTS.md** — read once at session start (general context)
- **Process files** — read before each process execution
- **rules/*.json** — read on demand via schema_ref when a step requires it
- **Memory layer** (working_memory.json, hot.md, log.md) — read/write per context rules

### Session Bootstrap (REQUIRED)

At session start, read [session_bootstrap.json](rules/session_bootstrap.json) and execute ALL steps in order. Do not skip.

> File defines explicit load sequence: `working_memory.json`, `wiki/hot.md`.

### Context Lifecycle (Continued)

2. **Process start**: Read the specific process-*.json file
3. **During process**: Follow schema_ref → rules/*.json as needed
4. **Process complete**: Forget transient rules, write to working_memory + hot.md

> **Scope definitions**: `rules/context-scopes.json`
> **Memory architecture**: `rules/session_context_rules.json`

---

## Roadmap & Project Plan (Development Mode)

- **[PLAN.md](PLAN.md)** — project roadmap, phase statuses, pending tasks. **Read before starting work**.
- **[FEATURES_PLAN.md](FEATURES_PLAN.md)** — architectural improvements implementation plan.
- **[issues.md](issues.md)** — bug registry. **Read during ingest/query/lint** to avoid known issues.

### Code Conventions

During script writing/debugging: [RULES.md](RULES.md).

#### JSON Instruction Compactification (R01-R07)

Before editing `process-*.json` and `rules/*.json`: read §9 of [RULES.md#instruction-compactification](RULES.md#9-instruction-compactification) + apply compact-json-instructions/SKILL.md (R07: preserve examples as conditional logic).

---

## Git Conventions

Commit format, staging modes, pre-commit workflow, prohibited commands, memory sync → `rules/git_conventions.json`. Agent **MUST read** this file before EVERY commit operation.

### Pre-Commit Workflow (REQUIRED)

1. **Read rule**: `rules/git_conventions.json` — detect mode from changes
2. **Mode detection**: 
   - Only `wiki/*.md` → **wiki mode**
   - Any `.sh/.json/py/md` in root, rules/, scripts/ → **dev mode**
3. **Stage**: `git add <mode-command>` (never `git add *`, never `git commit -a`)
4. **Verify**: `git status --short` — ensure no untracked/unstaged remain
5. **Commit format**: `<type> | <scope>: <description>` (see rules/git_conventions.json#commit_format)
6. **Memory sync**:
   - dev mode → update WM + hot.md
   - wiki mode → update WM focus_node + next_steps_todo

> Rule: Never commit without reading git_conventions.json first. Memory sync on dev commit is REQUIRED.

## Process Roles

---

## Process Roles

Three process files — each defines a complete workflow:
- **Ingest**: `process-ingest.json`
- **Query**: `process-query.json`
- **Lint**: `process-lint.json`

> Agent reads the process file before starting its workflow. Steps reference rules/*.json via schema_ref — no inline duplication.

**Batch Ingest Trigger**: `scripts/batch-ingest.sh --scan` clusters ≥3 related sources → `rules/batch_ingest_trigger.json`

---

## Architecture Layers

### 1. Raw Sources (`raw/`)

- Immutable originals (documents, articles, images, data)
- Agent reads only — no direct edits
- Write access via `scripts/validate-path.sh` guardrails
- All changes through: capture → integrate flow

> Guardrails: `rules/path-guard-check.json`

### 2. The Wiki (`wiki/`)

- LLM-generated markdown files organized by type
- Agent owns fully — creates, updates, cross-references

```json
{
  "structure": {
    "entities/": "specific identifiable objects (people, companies, technologies)",
    "concepts/": "abstract ideas, principles, methodologies",
    ...
    "assets/images/": "copies of original images (.png, .jpg, .jpeg, .gif)",
    "assets/descriptions/": "markdown descriptions of images: OCR + entities + metadata",
    "snapshot.md": "one-page snapshot of current facts from all wiki pages"
  }
}
```

> Categories: `rules/categories.json`

#### Assets & Media Pipeline

| Subdirectory | Purpose | Format |
|---|---|---|
| `raw/assets/images/` | Original image copies | Binary |
| `raw/assets/descriptions/` | OCR + entities + metadata | `.md` |

**Image ingest**: copy to `raw/assets/images/` → extract OCR/entities → save description `.md` → wikilink in page → `related` backlink.

**Conventions**: snake_case filenames with context prefix. Description files contain OCR text, entities, and metadata (dimensions, format, date_ingested). Auto-generated during ingest.

### 3. Summary / FAQ Pages (`wiki/syntheses/`)

Creation triggers, lifecycle (decay/merge/update), frontmatter template → `rules/faq_summary.json`.

> Agent reads this before any summary page operation.

### 4. Schema (this document)

- Defines wiki structure, conventions, workflows
- Co-evolves with user

### 5. Context Bridge (`working_memory.json`)

- Session bridge: focus_node, open_pages, dead_ends, next_steps_todo
- **Clear & Rewrite**: Never append — read → modify in memory → write complete document
- **Auto-cleanup**: Filter completed/outdated elements before write
- Does not duplicate wiki — session metadata only

> Full spec: `rules/session_context_rules.json`

### 6. Agent Rules & Conventions (`rules/`)

- Directory of technical specs extracted from AGENTS.md
- JSON for structured data/algorithms; Markdown for procedural text
- Agent reads rule file only when a process step references it (lazy via schema_ref)

---

## Rules Reference

Consolidated index of all niche/specific rules. Read on demand when a process step references them.

| Rule File | Purpose | Trigger |
|---|---|---|
| `rules/auto_rebuild_metadata.json` | Metadata rebuild modes per process | Before wiki edit |
| `rules/non_blocking_lint.json` | Lint checks, quiet mode, cron safety | Before lint |
| `rules/contradiction_resolution.json` | Cascade priority for conflicting sources | On contradiction detected |
| `rules/delta_tracking.json` | Hash-based source deduplication | Before ingest |
| `rules/error_handling.json` | Detect → analyze → resolve → continue | On process failure |
| `rules/evidence_grade.json` | Source authority auto-assignment | During page creation |
| `rules/execution_contract.json` | Proposal → Action (no permission stops) | Session start |
| `rules/execution_modes.json` | Silent/verbose flag management | Per turn |
| `rules/external_sources_policy.json` | Wiki create/update routing | Page write operation |
| `rules/link_conventions.json` | Link format, crosslink scoring | During page creation |
| `rules/compounding_workflow.json` | Compound answer → save decision | Query with novel insight |
| `rules/search_strategy.json` | Search tools, fallback chain, scoring | During query |
| `rules/session_context_rules.json` | Memory layers, save triggers, grep contract | Every memory operation |
| `rules/silent_output.json` | Output contract (final results only) | Session start |
| `rules/snapshot_format.json` | Snapshot lifecycle (create/update/archive) | Project mode active |
| `rules/structural_requirements.json` | Page structure validation | Page creation/update |
| `rules/tag-guidelines.json` | Tag patterns, aliases, enforcement | Page creation/update |
| `rules/work_modes.json` | Mode determination algorithm | Before context decisions |

---

## Page Templates & Frontmatter

### ⚠️ Global Rule: Template Editing Policy

> **Free editing of shared templates is prohibited.** Structural changes require user approval. Agent may propose via `[schema-patch]` but not apply independently.

### Universal Frontmatter (All Types)

**Mandatory for all document types.**

```yaml
---
tags: [] # keyword-tags — rules/tag-guidelines.json
date: YYYY-MM-DD # current system date (not source-derived!)
type: documentation # documentation | code_reality | live_state
category: entity # entity | concept | synthesis | comparison | note | project | bibliography | resource
aliases: [] # discoverability synonyms — rules/tag-guidelines.json#aliases_system
sources: [] # data origins (raw/, wiki paths, web_search)
related: [] # related wiki pages (wiki-relative paths)
---
```

| Field | Required | Description |
|---|---|---|
| `tags` | ✅ | Domain-specific keyword-tags (3-7). See `rules/tag-guidelines.json`. |
| `date` | ✅ | Current system date (YYYY-MM-DD). Never from source/commit dates. |
| `type` | ✅ | Reality layer: `documentation` / `code_reality` / `live_state`. Used in contradiction resolution. |
| `category` | ✅ | Wiki section: entity/concept/synthesis/comparison/note/project/bibliography/resource. |
| `aliases` | ⚠️ | Discoverability synonyms. See `rules/tag-guidelines.json#aliases_system`. |
| `sources` | ✅ | Data sources: raw/ paths, wiki paths, or `web_search`. |
| `related` | ✅ | Wiki-relative paths to related pages. Empty = no connections. |

### Auto-computed Fields

- **evidence_grade**: auto-assigned from source authority → `rules/evidence_grade.json`

### Language Policy

- Section headers: **always English** (structural anchors)
- Page content: follows source language (bilingual allowed)
- Agent responses: translate headers to match user's question language
- Mixed-language pages: encouraged for bilingual sources

> Details: `rules/language_policy.json`

### Template Co-evolution Process

1. **Agent proposes** → log via `process-ingest.json#schema_evolution`
2. **User approves** → agent commits update
3. **New scenarios** → discuss → add to schema
4. **Never auto-modify** — user-approved only

### Template Files

Templates in `wiki/templates/`. Recommended, not enforced. Frontmatter fixed by Universal Frontmatter — no template-specific field lists.

**Canonical**: `AGENTS.md#template_files`

---

## Date Convention Rule

- Frontmatter `date` = **current system date** (never from source filename / commit dates)
- Log entries: `## [YYYY-MM-DD] action | description`
- Timestamps in JSON: ISO-8601 `YYYY-MM-DDTHH:MM:SS+TZ`

> Enforced by: `lint.sh check_id=6`

---

## Schema Inheritance & Routing

> Rule: never duplicate AGENTS.md rules in process files. Always use `schema_ref` to canonical source.

All canonical references in the schema_ref field of process files. Agent follows them from there.

> **Wiki operation routing**: `rules/external_sources_policy.json`
