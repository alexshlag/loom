# Loomana Architecture

This document describes the system architecture, data flow, and key design patterns that power Loomana. Understanding this will help you extend the wiki, debug issues, or integrate it into your own tools.

---

## Overview: Four Layers of Abstraction

```
┌─────────────────────────────────────┐
│          USER INTERFACE              │ ← You provide sources, ask questions
│  ─────────────────────────────────── │
│         PROCESS WORKFLOWS           │ ← ingest / query / lint (process-*.json)
│  ─────────────────────────────────── │
│        RULES & SCHEMA LAYER         │ ← rules/*.json + AGENTS.md (schema_ref)
│  ─────────────────────────────────── │
│       DATA & STORAGE LAYER          │ ← wiki/**, raw/**, meta/**, scripts/
└─────────────────────────────────────┘
```

**Design philosophy:** Every layer reads the one below it. Nothing writes up to layers above — only through defined workflows. This prevents chaos and keeps the system predictable.

---

## Layer 1: Data & Storage (Bottom)

### The Wiki (`wiki/`)

The wiki is where structured knowledge lives. It's organized by category, not flat:

```
wiki/
├── entities/       ← Concrete objects: people, companies, technologies
│   ├── loomana.md
│   └── ...         (13 pages)
├── concepts/       ← Abstract ideas, principles, methodologies
│   ├── llm-wiki.md
│   └── ...         (25 pages)
├── syntheses/      ✓ Deep analysis combining multiple sources
│   └── rag-vs-llm-wiki-pattern.md    (2 pages)
├── comparisons/    ✓ Comparative analyses of related concepts
│   ├── loom-vs-claude-obsidian.md    (4 pages)
├── templates/      ← Markdown template files for new pages
├── overview.md     → Current state of knowledge across all categories
├── index.md        → Structured index with summaries per category
├── log.md          → Chronological action journal
└── hot.md          → Session context: focus node, open pages, next steps
```

**Key principles:**
- Pages are **LLM-created**, never manually written (unless user explicitly decides)
- Every page has **frontmatter** with tags, date, type, category, sources, related links
- Categories are defined in `rules/categories.json` — they determine routing during ingest

### Raw Sources (`raw/`)

Raw sources are your immutable originals:

```
raw/
├── sources/        ← Documents, articles, URLs captured via capture flow
│   └── SRC-YYYY-MM-DD-NNN/     ← Each source gets a unique directory
├── assets/images/  ← Original image copies (binary)
├── assets/descriptions/   ← OCR + entities extracted from images (.md files)
```

**Never edited directly.** The agent uses `scripts/validate-path.sh` guardrails to prevent accidental writes. All changes happen through the **capture → integrate flow**:

1. User provides source (URL/file/text)
2. Agent captures it to `raw/sources/SRC-YYYY-MM-DD-NNN/`
3. Agent integrates by creating wiki page based on content analysis

**Why immutable?** Raw sources are evidence. If we edit them, we lose the original truth for contradiction resolution later.

### Meta Data (`meta/`) — Auto-Generated

```
meta/          ← Never committed, rebuilt automatically
├── registry.json        ← Full source-to-page mapping
├── backlinks.json       ← Which pages link to which others
├── h1-index.json        ← First-heading index for fast search
├── search-index.json    ← Semantic search index (embedding-aware)
└── source-manifest.json ← Hash-based deduplication registry
```

**Rebuilt by:** `scripts/rebuild-meta.sh` — reads all wiki pages, extracts metadata, writes JSON files. Fast and idempotent.

### Tracking State (`tracking/`)

```
tracking/          ← Partially committed (see below)
├── raw_registry.json           ✅ Tracked in git (source manifest cache)
├── similarity_index.json       ✅ Tracked (semantic similarity data)
├── domain_whitelist.json       ✅ Tracked (approved domains for web search)
└── *.json                      ❌ Auto-regenerated, not tracked
```

**Git convention:** Only explicit tracking files are committed. Everything else is local state that can be regenerated.

---

## Layer 2: Rules & Schema

### AGENTS.md — The Living Schema

`AGENTS.md` defines everything the agent needs to know:
- Wiki structure conventions (categories, naming)
- Frontmatter schema (universal across all page types)
- Process workflows overview
- Memory management patterns
- Git conventions and commit format
- Error handling protocols

**Read once at session start**, then all references point to `rules/*.json` via `schema_ref`. This keeps AGENTS.md lean (~200 lines after compactification).

### Rules Directory (`rules/`)

Technical specs extracted from AGENTS.md, organized for lazy loading:

| File | Purpose | When Read |
|------|---------|-----------|
| `categories.json` | Wiki category definitions + routing rules | On page creation |
| `link_conventions.json` | Link format, cross-link scoring algorithm | On page creation/update |
| `git_conventions.json` | Commit format, staging modes, memory sync | Before every commit |
| `contradiction_resolution.json` | Priority cascade: Code Reality > Live State > Documentation | When contradiction detected |
| `tag-guidelines.json` | Tag patterns, aliases system, enforcement rules | On page creation/update |
| `error_handling.json` | Detect → analyze → resolve → continue protocol | On process failure |
| `session_context_rules.json` | Memory architecture: layers, save triggers, grep contract | Every memory operation |
| `search_strategy.json` | Search tools, fallback chain, scoring | During query workflow |
| ... + 20 more files | Various technical specs | As triggered by processes |

**Lazy loading pattern:** Agent reads a rule file only when a process step references it. No global loading of all rules at once — this keeps context window manageable (~86KB total instead of bloating).

### Schema Ref (`schema_ref`) Pattern

Process files don't duplicate rules — they reference them:

```json
{
  "step_id": "create_page",
  "action": {
    "rule": "rules/link_conventions.json#EXT-RES1"
  }
}
```

The agent reads `rules/link_conventions.json` **only** when it encounters this reference. This is the core of Loomana's context optimization — every token saved in schema_ref goes toward actual data, not boilerplate instructions.

---

## Layer 3: Process Workflows (Middle)

Three process files define complete workflows for different operations:

### Ingest (`process-ingest.json`)

**Purpose:** Add sources to the wiki and create structured pages.

**Flow diagram:**
```
User provides source
    ↓
Step 1: Guardrails validation (validate-path.sh)
    ↓
Step 2: Delta tracking hash check (rebuild-source-manifest.sh --scan-only)
    ↓
Step 3: Capture → raw/sources/SRC-YYYY-MM-DD-NNN/
    ↓
Step 4: Content analysis + classification (entity/concept/synthesis)
    ↓
Step 5: Frontmatter generation (tags, sources, aliases via web_search)
    ↓
Step 6: Discussion with user (optional, for complex sources)
    ↓
Step 7: Cross-link identification (auto-crosslink.sh)
    ↓
Step 8: Write page to wiki/ + update index.md + log.md
    ↓
Memory sync → working_memory.json + hot.md
```

**Key decisions:**
- Source deduplication via hash comparison (`rules/delta_tracking.json`)
- Evidence grade auto-assigned from source authority (`rules/evidence_grade.json`)
- If ≥3 related sources detected → batch ingest cluster trigger (`scripts/batch-ingest.sh --scan`)

### Query (`process-query.json`)

**Purpose:** Search wiki, synthesize answers with citations.

**Flow diagram:**
```
User asks question
    ↓
Step 0: Session bootstrap (working_memory.json + hot.md)
    ↓
Step 1: Intent detection + topic continuity bias
    ↓
Step 2: Search — index.md → semantic → grep-fallback
    ↓
Step 3: Read relevant pages, extract facts/citations
    ↓
Step 4: Synthesize answer with sources cited
    ↓
Step 5: Contradiction detection (check if multiple authoritative answers)
    ↓
Step 6: Novel insight? → propose saving as new wiki page
    ↓
Memory sync → working_memory.json + hot.md
```

**Search hierarchy:**
1. **Index scan** (`wiki/index.md`) — fast, category-based filtering
2. **Semantic search** (`tracking/similarity_index.json`) — embedding-aware relevance
3. **Grep fallback** — regex-injection cleanup for broad keyword matching

### Lint (`process-lint.json`)

**Purpose:** Maintain wiki health — contradictions, orphans, broken links.

**Flow diagram:**
```
Trigger: periodic / on-demand / agent detection of stagnation
    ↓
Check 1-15: Various lint validations (see scripts/lint.sh)
    ↓
Output: Dry summary of issues found
    ↓
If contradictions detected → resolve via priority cascade
    If orphans found → propose cross-linking to existing pages
    If broken links → suggest fixes in wiki/**
    ↓
User reviews → approves changes → agent commits
```

**Non-blocking:** Lint runs quietly; only reports issues. Agent proposes solutions but never auto-applies them without user approval (unless explicit permission).

---

## Layer 4: User Interface (Top)

Users interact through two modes:

### Mode A: Passive Consumption
- Ask questions → receive answers with citations
- Read wiki pages directly in your editor
- Review lint reports and approve/reject fixes

### Mode B: Active Source Provisioning
- Provide URLs, files, or text to ingest
- Discuss complex sources (agent asks clarifying questions)
- Propose schema changes via `[schema-patch]` commands

---

## Memory Architecture

### Three Context Layers

| Layer | File | Purpose | Lifetime |
|-------|------|---------|----------|
| **Session memory** | `working_memory.json` | Bridge: focus_node, open_pages, dead_ends, next_steps_todo | Per-session (clear & rewrite) |
| **Hot context** | `wiki/hot.md` | Current session's active focus and decisions | Per-session |
| **Chronological log** | `wiki/log.md` | All actions recorded chronologically | Permanent |

### Memory Lifecycle

1. **Session start**: Read `working_memory.json` → load current state
2. **During operation**: Agent updates memory in-place (read → modify → write)
3. **Process complete**: Write to WM + hot.md, auto-cleanup completed items
4. **Memory sync required** after dev commits; wiki-mode only needs WM update

### Grep Contract

Agent uses specific grep patterns for safe reading:

- ✅ Allowed: `grep -r "pattern"`, `awk '/regex/' file`, `jq '.field'`
- ❌ Never: Reading entire large files (>1MB), scanning all JSON at once without filtering

**Why?** To prevent context bloat — agent only reads what's relevant to current step.

---

## Error Handling Protocol

Loomana uses a **4-step detect-analyze-resolve-continue loop**:

```
STEP 1: DETECT    → Process fails, error code >0
                    ↓
STEP 2: ANALYZE   → Classify: syntax error? missing rule? data corruption?
                    ↓
STEP 3: RESOLVE   → Apply fix per priority (tool fix first, wiki rewrite only if source changed)
                    ↓
STEP 4: CONTINUE  → Retry step with correction; log resolution in log.md
```

**Key principle:** Fix the tool/script that caused error — don't patch wiki pages for process bugs. Wiki page rewrites only happen when source data actually changed.

---

## Git Workflow

### Commit Format Convention

All commits follow: `<type> | <scope>: <description>`

| Type | Purpose | Example |
|------|---------|---------|
| `feat` | New feature/script/rule | `feat | lint: add check_12_for_orphan_pages` |
| `fix` | Bug fix in scripts/processes | `fix | memory: correct WM write timing` |
| `refactor` | Structural improvement without behavior change | `refactor | rules: consolidate duplicate checks` |
| `schema` | Changes to AGENTS.md, process files, rules/ | `schema | ingest: unify crosslink step_7` |
| `lint` | Lint fixes applied to wiki pages | `lint | fix: resolve 3 contradiction pairs` |
| `ingest` | New source added to wiki | `ingest | add entity: pi-coding-agent` |
| `query` | Query result saved as new page | `query | synthesis on temporal_decay_patterns` |

### Git Modes

- **Wiki mode**: Only `wiki/*.md` changed → `git add wiki/*.md` (lightweight)
- **Dev mode**: Any `.sh/.json/py/md` in root/rules/scripts/ → full staging required

**Memory sync is REQUIRED after dev commits:** Update WM + hot.md before committing. Never skip this.

---

## Data Flow Summary

```
USER PROVIDES SOURCE
    ↓ (URL/file/text)
raw/sources/SRC-YYYY-MM-DD-NNN/      ← Capture (immutable)
    ↓ (content analysis)
process-ingest.json                    ← Classify, generate frontmatter
    ↓ (write via agent)
wiki/entities/concepts/syntheses/     ← New page created with cross-links
    ↓ (index update + logging)
wiki/index.md, wiki/log.md            ← Structured index refreshed

USER ASKS QUESTION
    ↓
process-query.json                    ← Intent detection → search → synthesis
    ↓ (read wiki pages via grep/fetch)
Answer generated with facts + citations
    ↓ (novel insight? save?)
New page creation OR answer delivered

AGENT RUNS LINT PERIODICALLY
    ↓
scripts/lint.sh                       ← 15+ checks across wiki structure
    ↓ (report issues → propose fixes)
User reviews contradictions/orphans/broken links
```

---

## Extending the System

### Adding New Rules

1. Create `rules/new-rule.json` with JSON schema
2. Reference it in process files via `schema_ref`: `"rule": "rules/new-rule.json"`
3. Agent will read on demand — no global loading needed

### Adding New Scripts

Follow conventions from RULES.md:
- Every script uses `set -euo pipefail`, paths quoted
- `--help` flag mandatory for quick reference
- Exit codes >0 indicate errors (so agent can fix)
- JSON → jq/python, Markdown → awk/sed/grep (no manual string concatenation)

### Adding New Wiki Categories

1. Update `rules/categories.json` — add category definition + routing rules
2. Process files will automatically use new category via schema_ref pattern
3. Templates in `wiki/templates/` can be extended for new page types

---

## Summary

Loomana's architecture is built on four layers:
- **Data layer** (raw/wiki/meta) — immutable sources, LLM-owned wiki, auto-generated metadata
- **Rules layer** (AGENTS.md + rules/*.json) — lazy-loaded via schema_ref to keep context lean
- **Process layer** (ingest/query/lint) — defined workflows with clear inputs/outputs
- **User interface** — passive consumption or active source provision

All layers are governed by the **schema_ref pattern**: no duplication, only references. This keeps the system maintainable and extensible without context bloat.

For next steps: read `docs/wiki-structure.md`, `docs/scripts-guide.md`, or jump to your area of interest in `rules/`.
