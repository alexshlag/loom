# Loomana Session Lifecycle Guide

This document describes the complete lifecycle of a Loomana session — from bootstrap through execution to shutdown. Understanding this flow helps you debug context loss, recover corrupted state, and know exactly what happens behind the scenes.

---

## Overview: The Three-Phase Model

Every session follows three phases:

```
PHASE 1: BOOTSTRAP    → Load existing memory + hot cache
PHASE 2: EXECUTION   → Process (query/ingest/lint) with live memory updates
PHASE 3: SHUTDOWN     → Persist state, update hot.md, close context bubble
```

Each phase interacts with three **memory layers** (`session_context_rules.json`):

| Layer | File | Purpose | Lifetime | Write Trigger |
|-------|------|---------|----------|---------------|
| Working Memory (WM) | `working_memory.json` | Current-session ops bridge: focus_node, open_pages, dead_ends | One session (persisted across sessions via hot.md snapshot) | Every turn — read → modify → write complete file |
| Hot Context | `wiki/hot.md` | Long-term snapshot for next session bootstrap | Survives compaction; read on next session start | Immediately after action; aggregated from WM + log.md tail |
| Chronological Log | `wiki/log.md` | Append-only chronicle of all actions | Permanent | After every significant operation (append only, never overwrite) |

> **Rule:** Never append to JSON files — always read full file → modify in memory → write complete document. Logs are the only exception: append-only with `cat >>`.

---

## Phase 1: Bootstrap

The bootstrap sequence is defined by `rules/session_bootstrap.json`. Agent MUST execute all steps in order at session start.

### Standard Bootstrap Flow

```
Step 1: Read working_memory.json → get focus_node, open_pages, current_mode, last_updated
    ↓ (if stale >30 days or empty)
Fallback Step 2A: Grep log.md for recent context (tail -20, NOT cat entire file)
    ↓
Step 2: Read wiki/hot.md → get active_project, pending_tasks, recent_changes
    ↓
Step 3: Read rules/git_conventions.json → detect staging mode + commit format
    ↓
Step 4: Scan wiki/skills/ directory → load skills into WM.skills_loaded (non-blocking)
```

### Bootstrap Decision Tree

```
working_memory.json exists AND last_updated <30 days?
    ├── YES → Use WM as primary context → Continue to hot.md read
    └── NO → Fall back to log.md grep:
               - grep -m 20 '' wiki/log.md | tail -20
               - grep -m 10 'project_name' wiki/log.md
             → Reconstruct focus_node from recent entries
```

### What Bootstrap Loads Into Memory

After bootstrap completes, the agent's working memory should contain:

- `focus_node` — current operational focus (e.g., "Phase 23 docs")
- `current_mode` — project | query | discussion | lint
- `open_pages` — max 3 wiki pages currently in context bubble
- `dead_ends` — paths that failed / questions without answers
- `query_summary` — snapshot of last query (intent, pages_read, key_findings)
- `skills_loaded` — array of {name, category} from wiki/skills/ scan

> **Context Bubble Rule:** Never hold more than 3 wiki pages in context simultaneously. Close one to open another.

---

## Phase 2: Execution

Execution mode depends on which process file is active: `process-query.json`, `process-ingest.json`, or `process-lint.json`. Each writes to working_memory differently.

### Memory Write Triggers During Execution

| Event | Rule ID | Target Section in hot.md | WM Sync Action |
|-------|---------|--------------------------|----------------|
| User message received | HOT-SAVE-QUERY-V1 | Active Session Context (topic, query_intent) | Update WM.query_summary.key_findings |
| Action completed | HOT-SAVE-ACTION-V1 | Recent Changes + System State | Update WM.query_summary.pages_read + key_findings |
| Wiki page modified | HOT-WIKI-CHANGES-V1 | System State → Recent Changes | Immediate write (no batching) |

### Concurrent Trigger Rule

When multiple triggers fire simultaneously: **write ALL relevant sections in one pass** — not sequentially. This prevents partial writes and race conditions during compaction.

### Mode-Specific Behavior During Execution

#### Query Mode (`process-query.json`)

- WM.current_mode = `"query"`
- Memory written after each synthesis step (step_2.3)
- Trajectory captured if `compounding_flagged` OR complexity ≥ medium
- Auto-distillation of trajectory via `distill.sh --trajectory <path>` on capture complete

#### Ingest Mode (`process-ingest.json`)

- WM.current_mode = `"project"` or `"query"` (depending on source type)
- Memory written after page creation/update + crosslink identification
- Delta tracking prevents duplicate ingest via hash comparison
- Batch cluster detection triggers `batch-ingest.sh --scan` if ≥3 related sources detected

#### Lint Mode (`process-lint.json`)

- WM.current_mode = `"lint"` (implicit, no explicit mode switch needed)
- Memory written after issues reported + fixes proposed
- Non-blocking: reports issues but never auto-applies without user approval
- Broken links tracked in WM.broken_links_resolved for cross-session continuity

---

## Phase 3: Shutdown & Persistence

At the end of a meaningful operation (not every turn), agent writes to memory.

### Standard Shutdown Sequence

```
Step 1: Update working_memory.json
    - next_steps_todo → refined based on current progress
    - open_pages → only keep relevant pages for next session
    - dead_ends → add any unresolved paths
    - query_summary → snapshot of last operation

Step 2: Write to wiki/hot.md (immediately, NOT deferred)
    - active_project.focus_node → from WM.focus_node
    - pending_tasks → update based on current progress
    - recent_changes → aggregated from log.md tail (~last 15 entries)

Step 3: Append to wiki/log.md (append-only)
    - Format: ## [YYYY-MM-DD] action | description
    - Never overwrite, never truncate — append only with cat >>

Step 4: Context bubble cleanup
    - If context compaction occurred → call load-hot-cache.sh || true
    - Close pages not relevant to next session's likely focus
```

### Memory Sync Requirements by Git Mode

| Git Mode | Required WM Update | hot.md Write? | Log Append? |
|----------|-------------------|---------------|-------------|
| Wiki mode (only wiki/*.md changed) | ✅ WM.focus_node + next_steps_todo | ✅ Yes | ✅ Yes |
| Dev mode (.sh/.json/py/md changes in root/rules/scripts/) | ✅ Full WM + hot.md sync | ✅ Yes | ✅ Yes |

> **Rule:** Memory sync is REQUIRED after dev commits. Wiki-mode only needs WM focus_node update but should still write hot.md for continuity. Never skip this.

---

## Recovery: Corrupted or Missing Memory

### Scenario A: working_memory.json Is Empty or Stale (>30 days)

```
Detection: last_updated field >30 days OR file doesn't exist
    ↓
Recovery steps:
1. grep -m 20 '' wiki/log.md | tail -20 → reconstruct recent focus
2. If log.md also empty → session starts fresh (no context loss, just new session)
3. Set WM.focus_node = "Unknown — recovered from log"
4. Continue with whatever the user asks; rebuild focus organically
```

### Scenario B: hot.md Is Corrupted or Missing

```
Detection: Can't parse YAML frontmatter OR file doesn't exist
    ↓
Recovery steps:
1. Don't crash — session continues without hot.md (non-blocking)
2. WM.focus_node may be stale but still usable from working_memory.json
3. On next meaningful operation, recreate hot.md fresh with current state
4. Log the recovery in log.md: "## [YYYY-MM-DD] recovered hot.md → recreated"
```

### Scenario C: Both WM and hot.md Are Lost

This is rare — it means both session memory AND long-term snapshot are gone. Usually caused by manual deletion or file corruption.

```
Recovery:
1. grep -m 50 '' wiki/log.md | tail -50 → find last meaningful operation
2. Rebuild WM.focus_node from log entries (most recent project/topic)
3. Create fresh hot.md with current timestamp + minimal snapshot
4. No data loss — only session continuity is affected, not actual wiki content
```

---

## Memory Layer Relationships

```
working_memory.json ────(aggregated from)────► wiki/hot.md
     ▲                                         ▲
     │ read/write per turn                     │ snapshot for next bootstrap
     │                                         │
     └─────────────(written by agent)──────────┘

wiki/log.md ◄──(append-only chronicle of all operations)─── [both layers write here]
```

**Key distinction:** WM is the **operational memory** (current session, turn-to-turn), hot.md is the **continuity snapshot** (next session bootstrap). They share `focus_node` and `next_steps_todo` but serve different purposes: WM is "what am I doing RIGHT NOW", hot.md is "where was I when I last stopped?"

---

## Grep Contract — Safe Reading Patterns

To prevent context bloat, agent follows strict grep rules during all phases:

### ✅ Allowed Patterns

```bash
grep -m N 'pattern' wiki/     # Read up to N matches (required)
head -n 20 file.md            # Read frontmatter or top lines
sed -n 'X,Yp' file.md        # Extract specific line ranges
jq '.field' file.json         # Read JSON fields safely
```

### ❌ Prohibited Patterns

```bash
cat large_file.md             # >50 lines → token overload
grep 'pattern' wiki/          # No -m flag → could output thousands of lines
awk '{print}' file           # Unfiltered reading → context bloat
```

**Why these rules?** LLM context windows are finite. Reading entire files wastes tokens and causes hallucination from noise. Only read what's relevant to current step.

---

## Natural Memory Translation

When agent writes to WM or hot.md, it should use natural language — not robotic system descriptions:

- ✅ "we're working on Phase 23 docs"
- ❌ "agent is processing phase_23 documentation generation"
- ✅ "the day before yesterday we added Symfony concepts"
- ❌ "timestamp: 2026-07-06 action: ingest"

Reference: `wiki/concepts/natural-memory.md` — full guidelines for human-friendly memory entries.

---

## Quick Reference: Common Operations

| Operation | WM Update | hot.md Write | Log Append |
|-----------|-----------|--------------|------------|
| Query answered | ✅ key_findings | ✅ Active Session Context | ✅ Yes |
| Page created/updated | ✅ next_steps_todo, open_pages | ✅ System State + Recent Changes | ✅ Yes |
| Lint issue reported | ✅ broken_links_resolved (if applicable) | ✅ Recent Changes | ✅ Yes |
| Memory compaction | ❌ (state lost temporarily) | ✅ Restore from hot-cache.sh | N/A |
| Session end | ✅ Final state snapshot | ✅ Aggregated snapshot | ✅ Yes |

---

## Summary

Session lifecycle in Loomana:

1. **Bootstrap** — read WM → fallback to log if stale → read hot.md → scan skills (non-blocking)
2. **Execution** — live memory writes per turn, mode-specific behavior, concurrent triggers batched into one write
3. **Shutdown** — persist WM + hot.md + append-to-log, context bubble cleanup, restore-hot-cache after compaction

Recovery paths exist for corrupted/missing files (never crash session). Grep contract prevents context bloat. Natural language in memory entries keeps human-readable state.

For process-specific flows: read `process-query.json`, `process-ingest.json`, or `process-lint.json` as needed via schema_ref pattern.
