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
- **[issues.md](issues.md)** — bug registry and known issues. Documents found bugs, logs fixes. **Read issues.md during ingest/query/lint** — to avoid duplicating known problems and understand system limitations.

### 🛠 Code Conventions

During the period of script writing and debugging, the following code development standard applies: [RULES.md](RULES.md).

---

## 🔖 Git Conventions

**Commit format**: `<type> | <scope>: <description>` (feat|fix|refactor|schema|lint|ingest|query; description lowercase).

Full specification including allowed/prohibited commands, pre-commit memory sync workflow (`rules/session_context_rules.json`), and regular wiki memory sync → **see [rules/git_conventions.json](rules/git_conventions.json)**.

> Schema ref: `rules/git_conventions.json`.

---

## 🔄 Process Roles

- Each role is a separate process file in the root directory.
- Each role inherits common rules from AGENTS.md.

**Full workflow for each role** — defined in the corresponding file:

| Role   | File                                       | Description                                                                        |
| ------ | ------------------------------------------ | ---------------------------------------------------------------------------------- |
| Ingest | [process-ingest.json](process-ingest.json) | Ingest new sources: capture → integrate                                            |
| Query  | [process-query.json](process-query.json)   | Answers via knowledge base, synthesis, compounding                                 |
| Lint   | [process-lint.json](process-lint.json)     | Periodic wiki health check — **non-blocking** via `scripts/lint.sh`                |

---

### Batch Ingest Trigger

When agent receives ≥3 related sources or user provides multiple files: `scripts/batch-ingest.sh --scan` scans all files, extracts H1/tags/keywords, groups by shared entities. Result → clusterized JSON for user decision-making.

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
    "snapshot.md": "one-page snapshot of current facts from all wiki pages (see below)"
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

- Summary answer pages — synthesis from ≥3 wiki sources forming complete coverage of a specific topic
- **Search priority**: syntheses/ → concepts/ → entities/ (FAQ layer searched first)
- Agent manages this layer autonomously: creates, merges, splits, removes outdated pages

**Creation Trigger:**
| Scenario | Agent Action |
|----------|--------------|
| Answer aggregates from **≥3 wiki pages** | ✅ Auto-create summary page in syntheses/, establish internal links (crosslinks), add external sources via ingest flow |
| Answer from internet (web_search) | ⚠️ Propose to user create FAQ page. If agreed → full ingest + links |
| Answer from 1-2 sources, no new insight | ❌ Do not create summary — just answer, possibly add to existing entity/concept |

**Lifecycle Rules:**
| Event | Action |
|-------|--------|
| Two summaries cover the same topic | Merge → one page, old links updated to new |
| Summary outdated (last_seen > 30 days without queries) | Decay: -50% popularity boost. Agent may merge into fresher page or delete if duplicate |
| New query → different top_path for same topic | Update existing summary + last_seen = current, popularity_score++ |
| Summary page requires user approval (external sources) | ⚠️ Do not create without explicit confirmation from user |

**Frontmatter type for FAQ pages:**

```yaml
---
tags: [summary, faq, ...]
date: YYYY-MM-DD
type: faq_summary # ← explicitly mark as question response
sources: [...]
related: []
---
```

> Schema ref: `rules/faq_summary.json`.

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

**Canonical rules source**: `rules/session_context_rules.json` defines complete algorithm for memory layer work (working_memory.json, hot.md, log.md), save_triggers, and read_algorithm. Agent reads this file before every memory action.

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
  {"approach": "grep across all wiki", "reason": "too much noise, index.md works better"}
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

Some fields are automatically computed by agent during ingest — no manual filling required.

#### `evidence_grade` — fact evidence level

**When applied**: Only for sources with `type: documentation`. For `code_reality` and `live_state` — auto-status `documented` (machine verification = high grade).

| Grade            | When to assign                                                                        | Meaning                    |
| ---------------- | ------------------------------------------------------------------------------------- | -------------------------- |
| `documented`     | Fact from authoritative source (official docs, project wiki, core-maintainer blog)   | High confidence            |
| `corroborated`   | Fact confirmed by 2+ independent sources                                            | Medium-high confidence     |
| `assertion_only` | Assertion without confirmation or from weak source (generic blog, forum post)        | Low confidence             |

**Auto-compute rules:**

1. Agent analyzes source during ingest → automatically assigns grade to each fact
2. Grade recorded in page metadata (not in body)
3. During contradiction resolution: `documented(1) > corroborated(2) > assertion_only(3)` — works as sub-priority for documentation sources
4. **Never set manually** — only by agent from source authority analysis

> Schema ref: `rules/evidence_grade.json`.

---

### 🌐 Language Policy for Wiki Pages & Agent Responses

#### Page Structure Headers (Templates)

- **All section titles in templates are English** — `## Definition`, `## Key Characteristics`, `## Principles`, `## Context`, `## Analysis`, `## Conclusions`, etc.
- This provides consistent structural anchors for agent navigation, regardless of content language
- Templates serve as machine-readable guide for agent — headers don't change with user language preference

#### Page Content Language

- Content follows source language
- Bilingual sources → bilingual sections (allowed and normal)
- No forced translation required at ingest time

#### Agent Response Translation

- When synthesizing answer: **translate section headers to match user's question language**
  - User asked in Russian → agent uses `Определение`, `Ключевые характеристики`, etc.
  - User asked in English → agent uses `Definition`, `Key Characteristics`, etc.
- Content paraphrasing is agent's discretion — can quote directly, summarize, or translate

#### Mixed-Language Pages

- Allowed and encouraged when reflecting bilingual sources
- Agent treats each section independently for translation at response time

**Canonical reference:** `AGENTS.md#language_policy`

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

### 🗂 Wiki Categories

Category order and definitions are stored in **`rules/categories.json`**. Agent reads them from there — never hardcodes. All scripts (rebuild-meta.sh, wiki-search.sh, duplicate-titles.sh) also read from this JSON.

> File: `rules/categories.json`.
---


### Compounding Workflow

**Schema ref**: `rules/compounding_workflow.json`

Answer is considered compound (requires saving as new wiki page) if synthesis from ≥2 wiki pages produces novel insight, contradiction resolved between sources, or existing entity/concept supplemented with new facts → **propose save to user**. Synthesis = new logical conclusion (A+B→C), not mere aggregation.

> Full decision logic: `rules/compounding_workflow.json` — scoring system, duplicate check, web source transitions.

---

### Wiki Snapshot (`wiki/snapshot.md`)

```json
{
  "format": {
    "title": "# Wiki Snapshot — Active Projects",
    "description": "One-page file for project context — list of user's active projects and related wiki pages.",
    "structure": {
      "header": "# Wiki Snapshot — Active Projects",
      "sections": [
        { "name": "## Active Projects", "type": "project_list" },
        {
          "name": "### [Project Name]",
          "properties": [
            "status: active/completed/on-hold",
            "context: brief project goal and current status",
            "related_pages: links to Entity/Concept pages"
          ]
        },
        { "name": "---\\n*Last updated: YYYY-MM-DD*", "type": "footer" }
      ]
    },
    "load_conditions": {
      "read_when": "WORK_MODE is project and snapshot contains entry for this project",
      "never_read": [
        "oneoff questions",
        "deep-dive study (query/discussion modes)"
      ]
    },
    "update_rules": [
      { "action": "create", "trigger": "user declares new project" },
      {
        "action": "update",
        "trigger": "every ingest/query that adds or changes related wiki pages"
      },
      {
        "action": "archive",
        "trigger": "project completed — entry moved to wiki/projects/, removed from snapshot.md"
      }
    ],
    "rule": "agent never loads snapshot.md if user is not working on a project. session starts with index.md + overview.md."
  }
}
```

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
| **hot.md** | Long-term snapshot — active project/session context. Survives compaction via restore-hot-cache.sh | Between sessions | Agent writes snapshot |
| **log.md** | Append-only chronicle of actions and wiki changes | Forever | Agent appends only |

**Quick interaction flow**: Session start → read WM → restore-hot-cache.sh → grep log (last 20 entries). Session end → write to WM → write snapshot to hot.md.

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

---

## 🔍 Search & Discovery

Search strategy is fully defined in **`rules/search_strategy.json`**. Agent reads from there — no hardcoded rules.

> File: `rules/search_strategy.json`.
---


---

## 📅 Date Convention Rule

- Frontmatter `date` = **current system date** (never derive from source filename / git commit dates)
- Log entries: `## [YYYY-MM-DD] action | description`
- Timestamps in JSON: ISO-8601 `YYYY-MM-DDTHH:MM:SS+TZ`

> Enforced by: `lint.sh check_id=6` (date_consistency_check).

---

## 🔧 Auto-Rebuild Metadata & Non-blocking Lint

### Meta Rebuild Path

#### Canonical: `scripts/rebuild-meta.sh [--index-only]`

- Full rebuild: `./scripts/rebuild-meta.sh` (registry + backlinks)
- Index only: `./scripts/rebuild-meta.sh --index-only` (index.md H1+first sentences)

`./scripts/rebuild-meta.sh` → rebuilds all meta files (`registry.json` + `backlinks.json` + `index.md`)

`--index-only` flag → rebuilds only `wiki/index.md` (H1 headers + first sentences per category)

**Trigger points**: After any wiki edit in Ingest / Query / Lint processes.

> Full integration flow: `process-ingest.json#step_3a` (full), `process-query.json#post_check`, `process-lint.json#check_id_7`

### Auto-update Index

`./scripts/rebuild-meta.sh --index-only` → rebuilds `wiki/index.md` (H1 headers + first sentences per category)

**Trigger**: Ingest process after create_page/update_existing. Lint after link_validation.

> Logic details: script parses wiki/*/_.md, groups by subdirectory, sorts alphabetically.

### Non-blocking Lint (Phase 3)

`scripts/lint.sh` — autonomous lint-audit script that does not block agent turn.

#### When Called

| Process            | Trigger                                                                                      |
| ------------------ | -------------------------------------------------------------------------------------------- |
| **Standalone**     | `./scripts/lint.sh [--quiet] [--skip-checks ID1,ID2]` — can be run separately or by cron    |
| **Process-lint**   | Instead of inline lint → call `./scripts/lint.sh --quiet`                                    |

#### How to Use

```bash
# Full check (stdout = JSON report, stderr = human-readable)
cd /path/to/loomana && ./scripts/lint.sh

# Quiet mode (JSON only on stdout, no output on stderr)
cd /path/to/loomana && ./scripts/lint.sh --quiet

# Skip specific checks
cd /path/to/loomana && ./scripts/lint.sh --skip-checks 3,5
```

#### Output Format (JSON on stdout)

```json
{
  "timestamp": "YYYY-MM-DDTHH:MM:SS",
  "wiki_dir": "wiki/",
  "checks_run": 11,
  "issues_found": {
    "contradictions": 0,
    "orphan_pages": 3,
    "orphan_paths": [],
    "new_sources_unprocessed": 5,
    "duplicate_titles": 0,
    "date_inconsistencies": 0,
    "broken_links": 2,
    "auto_repaired_links": 1,
    "agent_review_required": 0,
    "agent_review_details": [],
    "contradictions_deep": 0,
    "text_similarity_overlaps": 0,
    "hot_cache_stale": false
  },
  "total_issues": 10,
  "status": "ISSUES_FOUND"
}
```

#### Checks Performed by Script

| Check ID | Name                  | Script                                     | Result                                                    |
| -------- | --------------------- | ------------------------------------------ | --------------------------------------------------------- |
| 1        | Contradictions (soft) | `## Обновлено` grep                        | Pages count for agent review                              |
| 2        | Orphan pages          | `orphan-pages.sh`                          | Count + paths of orphaned wiki pages                      |
| 3        | Knowledge gaps        | —                                          | Skipped (agent review required)                           |
| 4        | New sources available | `check-new-sources.sh --max 10`            | NEW: package list                                         |
| 5        | New topics proposal   | —                                          | Skipped (requires external sources)                       |
| 6        | Mechanical linting    | `duplicate-titles.sh` + frontmatter checks | Duplicate count, missing fields                           |
| 7        | Date consistency      | `date-consistency.sh`                      | Inconsistencies count                                     |
| 8        | Broken links auto-resolve | `unified-pass.sh --auto`               | JSON: broken_links[] + auto_repaired + agent_review_required |
| 9        | Contradictions deep scan | `detect-contradications.sh`             | potential_contradictions count + conflicts[]              |
| 10       | Text similarity scan  | `text-similarity.sh --scan-all`            | matches[] with similarity_score, file1, file2             |
| 11       | Hot cache stale check | `check-wiki-changes.sh`                    | WIKI CHANGES DETECTED / no changes                        |

#### Why This Matters

- **Does not block agent turn**: lint runs separately, does not require inline execution
- **Scalability**: can be run by cron (e.g., every 4 hours)
- **Single entry point**: all checks in one script → simple call from any process
- **JSON output for machine parsing**: stdout = structured report, stderr = human-readable

#### Cron example (optional)

```bash
# crontab -e — automatic lint every N hours
0 */4 * * * cd /path/to/loomana && ./scripts/lint.sh --quiet >> logs/lint.log 2>&1
```

---

## 🔄 Schema Inheritance & Routing

### Schema Inheritance

Process files inherit from AGENTS.md via `schema_ref` (never duplicate rules).

#### Canonical References

| Reference                | Path                                                                                        |
| ------------------------ | ------------------------------------------------------------------------------------------- |
| Meta rebuild             | `./scripts/rebuild-meta.sh`                                                                 |
| Search priority          | `process-query.json#search_priority_details`                                                |
| Lint script              | `./scripts/lint.sh`                                                                         |
| Contradiction resolution | `process-query.json#contradiction_resolution_flow → authoritative > temporal > user_review` |

> Rule: never duplicate AGENTS.md rules in process files. Always add `schema_ref` for canonical source.

---

### Wiki Operation Routing Contract

**Schema ref**: `rules/external_sources_policy.json` — full routing contract for wiki create/update operations.

> Rule: never duplicate AGENTS.md rules in process files. Always add `schema_ref` for canonical source.
---