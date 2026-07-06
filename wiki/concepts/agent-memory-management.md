---
tags: [memory, agent-behavior, recall-system, trajectory-capture]
date: 2026-07-06
type: documentation
category: concept
sources: ["web_search", "research/ingest-algorithms-comparison.md"]
related: ["wiki/concepts/natural-memory.md", "rules/session_context_rules.json"]
---
- [[wiki/concepts/natural-memory.md]] (score: 5)

# Agent Memory Management — Techniques and Recommendations

This page explores memory management for LLM agents as a key concept in our knowledge base.


## Definition
Systematic approaches to managing what an agent remembers, how it recalls information across sessions, and how it captures experiences into reusable patterns — all without external dependencies (no vector DBs, no cloud services).


## Principles

### Zero-Dependency File-Based Memory
Modern research shows that plain files (Markdown/JSON) can outperform complex memory systems when properly structured. Key findings:

1. **Plain Markdown + Git** = durable, versionable, human-readable memory system. No database required.
2. **Hybrid Recall** (lexical + semantic) achieves 90%+ accuracy on knowledge benchmarks vs ~78% for dense-only. The lexical component handles exact identifiers; semantic catches paraphrased concepts.
3. **Trajectory Capture → Distillation** pipeline is the emerging standard: record raw tool-call sequences, distill them into reusable skill/case pages.
4. **Two-tier memory** (working + permanent) mirrors cognitive science — transient context for immediate tasks, structured knowledge base for long-term recall.


## Techniques Overview

### 1. Memory Architecture Patterns

#### Three-Layer Model (Recommended)
| Layer | Purpose | Storage | Lifespan |
|-------|---------|---------|----------|
| **Working** | Current session focus, open pages, next steps | `working_memory.json` | Session |
| **Hot Cache** | Active project context, recent facts | `hot.md`, snapshots | Between sessions |
| **Permanent** | Structured knowledge base with crosslinks | Wiki directory | Forever |

**Why it works:** Each layer has clear boundaries — working memory is volatile (session-scoped), hot cache bridges sessions but stays small (< 5KB), permanent wiki grows organically. This prevents context window bloat while preserving searchability.

#### Cognitive Recall Pattern
Hybrid retrieval combining:
- **Lexical** (BM25-style): Fast exact-match, handles identifiers/codes/names perfectly
- **Semantic**: Catches paraphrased concepts where surface vocabulary differs
- **Graph/Link-based**: Follows wikilinks for structural context

### 2. Capture Patterns

#### Trajectory Logging
Record the agent's own tool-call sequences:
```json
{
  "id": "TRJ-042",
  "prompt": "User task description",
  "steps": [
    {"role": "user", "text": "..."},
    {"role": "assistant", "tool_calls": [{"name": "read", ...}]},
    {"role": "tool", "tool_name": "read", "is_error": false}
  ]
}
```

**Distillation flow:** Raw trajectory → extracted.md summary → skill/case page via wiki_ensure_page.  
The trajectory is immutable; distillation produces the reusable artifact.

#### Atomic Capture (Retro)
Quick knowledge capture without full ingest overhead:
- Single `wiki_retro` call creates a wiki page directly
- Used for post-task insights, not raw source material
- Lightweight alternative to `wiki_capture_source`

### 3. Recall Strategies

#### Two-Stage Recall (Recommended)
**Stage 1:** Rank links based on relevance score — no content loaded yet  
**Stage 2:** Agent expands chosen links via `read` tool  

**Advantage:** Keeps context window small while giving agent control over what to explore deeper. Works well for large wikis (>50 pages).

#### Pseudo-Relevance Feedback (PRF)
Extract distinctive terms from top-3 results, use them to boost semantically related pages. This gives semantic expansion without external dependencies:
```
Query: "Authentication" → Top result mentions JWT, OAuth, sessions
→ These terms boost other auth-related pages automatically
```

### 4. Distillation Patterns

#### Trajectory → Skill Mapping
| Raw Data | Distilled Output | Trigger |
|----------|------------------|---------|
| Successful tool-call sequence | Reusable skill page (`wiki/skills/*.md`) | After non-trivial task |
| Failed sequence with analysis | Case page with lessons learned | When failure reveals pattern |
| Partial success + improvements | Refined case → eventual skill | Multiple iterations |

**Quality criteria:** A good distillation captures the *procedure*, not just the outcome. It should be generalizable across tasks.


## Analysis

### Comparison of Approaches

| Approach | Pros | Cons | Fit for Loomana |
|----------|------|------|-----------------|
| **Three-Layer File-Based** (Recommended) | Zero deps, git-native, human-readable | Manual search needed | ✅ **Best fit** — matches our architecture already |
| Hybrid Recall (lexical + semantic) | High accuracy, handles paraphrasing | Requires embedding model for semantic part | ⚠️ Good as future enhancement |
| Trajectory → Distillation | Captures agent expertise organically | Requires session access to extract trajectories | ✅ **Strong fit** — complements our existing processes |
| Vector DB (Pinecone/Weaviate) | Powerful similarity search | External dependency, API costs | ❌ No — violates zero-dependency principle |
| SQLite-first Memory | Structured queries, deduplication | Binary format, not git-friendly | ⚠️ Possible but adds complexity |

### Key Findings from Research

1. **File-based systems outperform expectations**: Plain Markdown + Git provides durable memory without external services. The key is structure (index.md, registry.json) rather than technology.
2. **Hybrid recall is the gold standard**: Systems combining lexical + semantic retrieval achieve 90%+ accuracy vs ~78% for dense-only. Our current `recall.sh` approach uses PRF (Phase 1a) with TF-IDF-like scoring — already adds semantic expansion without external models.
3. **Trajectory capture → distillation is emerging as best practice**: The pi-llm-wiki implementation (recal.ts, trajectory.ts) shows how to record agent behavior and turn it into reusable skills automatically. This aligns perfectly with our compounding workflow.


## Conclusions

### Recommended Implementation Path for Loomana

**Phase 1 (Immediate):** Enhance existing recall system
- ✅ PRF-enhanced recall implemented in `scripts/memory/recall.sh` — Stage 1 (links-first ranking) + Stage 2 (content expansion)
- Two-stage recall (links-first mode) for large wikis (>50 pages)
- Improve registry.json with metadata for better ranking

**Phase 2 (Next Sprint):** Trajectory capture integration
- Implement trajectory logging in process-query.json → session hooks
- Create `raw/trajectories/TRJ-*` directory structure
- Distill captured trajectories into skill/case pages via wiki_ensure_page

**Phase 3 (Future):** Hybrid recall with local embeddings (optional)
- If embedding model available, add semantic recall alongside lexical
- Precompute page vectors at write time (offline)
- Query vector only at recall time (cached per session)


## Evolution Rules
- This page is a living document — update as we implement new features
- Each phase completion → add results to "Conclusions" section
- Track which recommendations become implemented vs theoretical

## Related Pages
* [process-query.json#web_ingest_flow](../../process-query.md#web-ingest-flow) — transition from query to ingest, where memory capture happens
* [process-ingest.json#step_3_analysis](../../process-ingest.md#step-3-analysis) — knowledge integration logic
* [AGENTS.md#memory_architecture_contract](../../AGENTS.md#memory-architecture-contract) — session context rules

---

## 📐 Loomana Memory Layer Architecture (Implementation Design)

### Current State: What We Have

**Existing memory infrastructure:**
| Component | Location | Purpose | Status |
|-----------|----------|---------|--------|
| Three-layer model | `working_memory.json`, `hot.md` + wiki/ | Session → long-term bridge → permanent knowledge | ✅ Implemented (loosely defined) |
| Lexical search | `wiki-search.sh`, grep-based indexing (legacy) | Keyword matching across wiki pages | ⚠️ Working, but limited to exact match |
| PR-enhanced recall | `scripts/memory/recall.sh` ← **current canonical engine** (Stage 1: links-first, Stage 2: content expansion) | ✅ Working — replaces wiki-search.sh in process-query.json |
| Meta files | `meta/registry.json`, `backlinks.json` | Page metadata + link relationships | ✅ Maintained by rebuild scripts |
| Process hooks | `process-query.json#working_memory_hooks`, `process-ingest.json` | Session memory sync triggers | ⚠️ Fragmented, tightly coupled with main logic |

**Gaps to address:**
1. **Memory operations are inline** — every process (query/ingest) handles memory directly → context bloat  
2. **No trajectory capture** — agent experience not recorded systematically
3. ~~Recall is purely lexical~~ — no semantic-like expansion for paraphrased concepts ~~→ Phase 1a Task #3: PRF-enhanced recall (`scripts/memory/recall.sh`) implemented~~
4. ~~Hot cache rebuilds on every session~~ — unnecessary I/O if wiki hasn't changed ~~→ Phase 1a Task #4: hot-cache-update.sh check-only mode integrated into process-query.json step_0.25~~
5. **Distillation is ad-hoc** — no automated pipeline from captured data to reusable skills

---

### Proposed Architecture: Separate Memory Layer as Background Subsystem

**Design Principle:** Memory management should be a separate subsystem that operates in background, triggered by hooks/events rather than explicit steps in main processes. This keeps query/ingest/lint focused on their core tasks.

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│   Query      │     │    Ingest    │     │       Lint       │
│  Process     │◄───►|   Process    │◄───►│    Process       │
└──────┬───────┘     └──────┬──────┘     └────────┬────────┘
       │                    │                      │
       ▼                    ▼                      ▼
  Memory Hooks      Memory Hooks              Memory Hooks
       │                    │                      │
       ▼                    ▼                      ▼
┌─────────────────────────────────────────────────────────┐
│              MEMORY MANAGEMENT LAYER                     │
│                                                          │
│  ┌───────────┐  ┌───────────────┐  ┌──────────────────┐ │
│  │ Recall    │  │ Trajectory    │  │ Distillation     │ │
│  │ Engine    │  │ Logger        │  │ Pipeline         │ │
│  └───────────┘  └───────────────┘  └──────────────────┘ │
│                                                          │
│  ┌───────────┐  ┌───────────────┐  ┌──────────────────┐ │
│  │ PRF       │  │ Session       │  │ Skill/Case       │ │
│  │ Enhancer  │  │ State Tracker │  │ Curator          │ │
│  └───────────┘  └───────────────┘  └──────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

**Key design decisions:**
1. **Background processing**: Memory operations happen via hooks → memory layer processes asynchronously (non-blocking)  
2. **No inline complexity**: Main process files don't include memory management logic; they emit events/hooks  
3. **Separation of concerns**: Query/ingest/lint focus on content; memory layer handles how that content is stored, recalled, and distilled  
4. **Zero dependencies**: All implemented via existing scripts + shell functions in `scripts/memory/`  

---

### 1. Memory Management Layer (Background Subsystem)

**Location:** `scripts/memory/` — new directory for memory management utilities

**Core modules:**

#### a) Recall Engine (`scripts/memory/recall.sh`)
- `scripts/memory/recall.sh` now integrated into process-query.json — replaces wiki-search.sh calls with PRF-enhanced recall  
- Two-stage recall: links-first, then content expansion  
- Handles >50 pages efficiently by ranking before loading content  

```bash
# Usage:
./scripts/memory/recall.sh "<query>" --prf --top N --stage=links|content
```

**How it works:**
1. **Stage 1 (links):** Run lexical search → rank results using PRF boost  
2. **PRF extraction:** From top-3 results, extract distinctive terms (TF-IDF-like)  
3. **Boost phase:** Re-score wiki pages that match PRF terms  
4. **Stage 2 (content):** Only load content from final ranked links  
5. **Output:** `JSON` array of `{path: "wiki/...", score: 0.XX, preview: "..."}`  

**Integration point:** `scripts/memory/recall.sh` now replaces all wiki-search.sh calls in process-query.json — Stage 1 (links) returns ranked paths, Stage 2 (content) expands only selected pages.

#### b) Trajectory Logger (`scripts/memory/traj-capture.sh`)
- Captures agent session data (tool calls, user interactions, outcomes)  
- Writes to `raw/trajectories/TRJ-{timestamp}-{id}/`  
- Produces `packet.json` (full sequence) + `extracted.md` (human summary)  

```bash
# Called from process hooks:
./scripts/memory/traj-capture.sh --prompt "<user query>" --steps "<tool_calls JSON>" --outcome "success|partial|failure"
```

**Output structure:**
```
raw/trajectories/
├── TRJ-20260706-1430-query-memory/
│   ├── packet.json    # Full tool-call sequence (immutable)
│   └── extracted.md   # Human-readable summary
```

#### c) Distillation Pipeline (`scripts/memory/distill.sh`)
- Converts captured trajectories into reusable skills/cases  
- Auto-detects reusable patterns from trajectory data  
- Creates wiki pages via `wiki_ensure_page(type='skill'|'case')`  

```bash
# Called after task completion:
./scripts/memory/distill.sh --trajectory "raw/trajectories/TRJ-*" --type skill|case --auto
```

**Quality criteria (from research):**
| Criterion | Check | Implementation |
|-----------|-------|----------------|
| **Full Coverage** | All effective steps captured in pattern | `packet.json` → `extracted.md` comparison |
| **Frequency Awareness** | Patterns covering more cases get priority | Track trajectory reuse count in metadata |
| **Procedure over Outcome** | Describes procedure, not just result | Distillation script checks for procedural content |
| **Cross-task Generalization** | Works for similar tasks, not just one | Test against 2+ existing wiki scenarios |

---

### 2. Process Integration: Hooks → Background Processing

Current problem: memory management logic is inline in process files (query/ingest/lint).  
Solution: decouple via hooks — processes emit events, memory layer handles them asynchronously.

**Modified hook structure for `process-query.json`:**
```json
{
  "memory_hooks": [
    {
      "trigger": "on_search_complete",
      "actions": [
        {
          "action_name": "update_recall_ranking",
          "command": "./scripts/memory/recall.sh --rank \"<query>\" --top 10"
        }
      ]
    },
    {
      "trigger": "on_task_complete",
      "actions": [
        {
          "action_name": "capture_trajectory_if_nontrivial",
          "command": "./scripts/memory/traj-capture.sh --prompt \"<user_query>\" --steps \"<tool_calls>\" --outcome \"success\"",
          "condition": "task_complexity >= medium"
        }
      ]
    },
    {
      "trigger": "on_wiki_page_created",
      "actions": [
        {
          "action_name": "update_backlinks_and_index",
          "command": "./scripts/memory/backlink-update.sh --page \"<new_path>\""
        }
      ]
    }
  ]
}
```

**Modified hook structure for `process-ingest.json`:**
```json
{
  "memory_hooks": [
    {
      "trigger": "on_source_ingested",
      "actions": [
        {
          "action_name": "register_in_registry",
          "command": "./scripts/memory/source-register.sh --path \"<source_path>\" --hash \"<sha256>\""
        }
      ]
    },
    {
      "trigger": "on_page_update_completed",
      "actions": [
        {
          "action_name": "update_hot_cache_if_changed",
          "command": "./scripts/memory/hot-cache-update.sh --check-only"
        }
      ]
    }
  ]
}
```

**Key change:** Processes no longer directly manage memory — they trigger hooks → memory layer processes asynchronously.

---

### 3. Two-Stage Recall Implementation (Phase 1)

**Solution:** Two-stage recall via `scripts/memory/recall.sh` — Stage 1 ranks links first (no content loaded), Stage 2 loads only final top-K pages.  
**Solution:** Two-stage recall — rank first, load second.

```bash
# scripts/memory/recall.sh --enhanced workflow:

# Stage 1: Rank links (no content loaded yet)
grep -m 30 "<query>" wiki/index.md → top N candidates

# PRF extraction from top-3 results  
head -n 20 candidate1.md | extract_distinctive_terms() → TF-IDF-like scores
head -n 20 candidate2.md | extract_distinctive_terms() → ...
head -n 20 candidate3.md | extract_distinctive_terms() → ...

# Boost phase: re-score pages matching PRF terms
grep -m 10 "PRF_term_1" wiki/index.md → boost score +2
grep -m 10 "PRF_term_2" wiki/index.md → boost score +1

# Stage 2: Load content from final ranked links (top K)
head -n 50 ranked_k.md → agent reads only selected pages
```

**Benefits:**
- Context window stays small until stage 2  
- Agent sees structured results with scores before loading content  
- PRF provides semantic-like expansion without external models  

---

### 4. Hot Cache Optimization (Phase 1)

Current: `load-hot-cache.sh` runs every session, reading all wiki files.  
Problem: unnecessary I/O if wiki hasn't changed since last session.

**Solution:** Check-only mode that skips rebuild if no changes detected.
```bash
# scripts/memory/hot-cache-update.sh --check-only
# Returns exit code 0 = "no changes", 1 = "changes detected"
# Only full rebuild triggered when exit code != 0
```

**Integration:** Replace `./scripts/load-hot-cache.sh || true` in process-query.json with:
```json
{
  "command": "./scripts/memory/hot-cache-update.sh --check-only || true",
  "condition": "exit_code_1 → proceed to full rebuild"
}
```

---

### 5. Trajectory Capture Integration (Phase 2)

**Where hooks need to be added:**

#### In `process-query.json` — after task completion:
Add hook at step_3 (result_fixation):
```json
{
  "trigger": "on_task_complete",
  "actions": [
    {
      "action_name": "capture_trajectory_if_nontrivial",
      "command": "./scripts/memory/traj-capture.sh --prompt \"<user_query>\" --steps \"<tool_calls>\"",
      "condition": "compounding_flagged OR task_complexity >= medium"
    }
  ]
}
```

#### In `process-ingest.json` — after ingest completion:
Add hook at step_10 (register_source_ingested):
```json
{
  "trigger": "on_source_ingested",
  "actions": [
    {
      "action_name": "capture_trajectory_if_nontrivial",
      "command": "./scripts/memory/traj-capture.sh --prompt \"<user_query>\" --steps \"<tool_calls>\"",
      "condition": "new_page_created OR page_updated"
    }
  ]
}
```

---

### 6. Distillation Pipeline (Phase 2)

**Flow:** Raw trajectory → extracted.md summary → skill/case page via wiki_ensure_page

```
raw/trajectories/TRJ-*
   ↓ (agent reads packet.json + extracted.md)
wiki/skills/*.md OR wiki/cases/*
   ↓ (via wiki_ensure_page with type='skill'|'case')
crosslinks added to related pages
   ↓ (via scripts/auto-crosslink.sh)
```

**Trigger conditions for distillation:**
| Condition | Action |
|-----------|--------|
| Trajectory has ≥3 tool calls AND successful outcome | Create skill page (`wiki/skills/`) |
| Trajectory has failure + analysis | Create case page with lessons learned (`wiki/cases/`) |
| Multiple trajectories show same pattern → merge into consolidated skill |

**Quality gates for distillation:**
1. **Procedure check**: Distilled page must describe *how* (steps, conditions), not just *what happened*  
2. **Cross-task test**: Skill should be applicable to 2+ similar scenarios in wiki  
3. **No duplication check**: `scripts/memory/distill.sh --check-dup` ensures no existing skill covers the same pattern  

---

### 7. Process File Modifications Required

#### `process-query.json`:
1. Replace inline memory operations with hook-based triggers  
2. Add `memory_hooks` section with:
   - `on_search_complete` → recall ranking update  
   - `on_task_complete` → trajectory capture if nontrivial  
   - `on_wiki_page_created` → backlink/index update  
3. Update step_1 to use PRF-aware recall engine  

#### `process-ingest.json`:
1. Replace inline memory operations with hook-based triggers  
2. Add `memory_hooks` section:
   - `on_source_ingested` → registry update  
   - `on_page_update_completed` → hot cache refresh if changed  
3. Update step_9_post_checks to call hooks instead of direct scripts  

#### `process-lint.json`:
1. Add hook for trajectory distillation queue:
   ```json
   {
     "trigger": "post_lint_check",
     "actions": [
       {
         "action_name": "check_pending_distillations",
         "command": "./scripts/memory/distill.sh --check-undistilled"
       }
     ]
   }
   ```

---

### 8. Summary: What Changes, How to Organize

**What we have now:**
- ✅ Three-layer memory model (working → hot cache → permanent wiki)  
- ✅ Lexical search with grep-based indexing  
- ✅ Meta files maintained by rebuild scripts  
- ⚠️ Fragmented hooks, tightly coupled with main logic  

**What we add in Phase 1:**
- ✅ PRF-enhanced recall (`scripts/memory/recall.sh`) — semantic-like expansion without external models  
- ✅ Two-stage recall (links-first mode) — context window stays small for large wikis  
- ✅ Hot cache optimization (check-only mode) — skip rebuild if wiki unchanged  

**What we add in Phase 2:**
- ✅ Trajectory capture (`scripts/memory/traj-capture.sh`) — record agent experience systematically  
- ✅ Distillation pipeline (`scripts/memory/distill.sh`) → convert trajectories to reusable skills/cases  
- ✅ Hook-based memory management — decouple from main processes, background processing  

**What changes in process files:**
- Query/ingest/lint no longer directly manage memory  
- Memory operations happen via hooks → memory layer processes asynchronously  
- Processes emit events; memory layer handles storage/recall/distillation  

---

## Evolution Rules
- This page is a living document — update as we implement new features  
- Each phase completion → add results to "Conclusions" section  
- Track which recommendations become implemented vs theoretical  

## Related Pages
* [process-query.json#web_ingest_flow](../../process-query.md#web-ingest-flow) — transition from query to ingest, where memory capture happens
* [process-ingest.json#step_3_analysis](../../process-ingest.md#step-3-analysis) — knowledge integration logic  
* [AGENTS.md#memory_architecture_contract](../../AGENTS.md#memory-architecture-contract) — session context rules

## Updated [2026-07-06] — Implementation design phase
- **Research**: Analyzed 8+ open-source implementations (pi, pi-llm-wiki, memfabric, cortex-memory, etc.)  
- **Design**: Memory layer architecture with separation of concerns (background processing via hooks)  
- **Phase 1 plan**: PRF enhancement + two-stage recall + hot cache optimization  
- **Phase 2 plan**: Trajectory capture → distillation pipeline integration  
- **Process file changes needed**: Decouple memory operations into hook-based background subsystem  
