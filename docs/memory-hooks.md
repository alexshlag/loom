# Memory Hooks & Trajectory Pipeline in Loomana

This document describes the background processing system that powers Loomana's self-improvement — how agent actions are captured, analyzed, and distilled into reusable wiki skills/cases. This is the Phase 16.1 memory subsystem that runs asynchronously alongside main processes.

---

## Overview: The Hook Architecture

Memory hooks decouple content processing from memory management. Instead of inline writes scattered across process steps, each action emits events that the memory subsystem handles in background — without blocking the main flow.

### Three Layers

```
Process Layer          → query/ingest/lint (main workflow)
       │
       ▼
Memory Hooks           → async triggers per process step
       │
       ▼
Memory Subsystem       → scripts/memory/* handling: capture, distill, backlinks, hot cache
```

### Key Principles

1. **Non-blocking**: Memory operations never wait for completion — if a hook script fails (`|| true`), the main process continues
2. **No inline memory logic**: Steps like "write_to_working_memory" exist only as hook definitions in process files, not as inline commands
3. **Schema references**: Each hook action points to canonical source via `schema_ref` pattern — no duplication

---

## The Trajectory Pipeline: Capture → Distill → Wiki Skill

When the agent performs a non-trivial operation (complex query, multi-source ingest), it can be distilled into reusable knowledge artifacts. This happens in three stages:

### Stage 1: Trajectory Capture (`traj-capture.sh`)

**Purpose:** Record what the agent did — prompts, tool calls, outcomes — as structured data for later analysis.

**When triggered:** `on_search_complete` or `on_ingest_complete` hook fires when:
- `compounding_flagged = true` (answer synthesized from 2+ pages)
- OR task complexity ≥ medium

**Command format:**
```bash
./scripts/memory/traj-capture.sh \
    --prompt "user's original query" \
    --steps '[{"name":"read","tool_name":"read file.md","is_error":false}]' \
    --outcome success | partial | failure \
    --complexity low | medium | high
```

**Output:** Creates `raw/trajectories/TRJ-{timestamp}-{id}/` directory with:
- `packet.json` — structured metadata (prompt, tool_calls, outcome, complexity, agent git hash)
- `extracted.md` — human-readable summary of steps executed and errors encountered

**Directory structure:**
```
raw/trajectories/
├── TRJ-20260708-1130-a4f2c1d3/
│   ├── packet.json      # {id, timestamp, prompt, tool_calls, outcome, complexity}
│   └── extracted.md     # Human-readable summary: steps, errors, outcomes
├── TRJ-20260708-1045-b8e3d9f1/
│   ├── packet.json
│   └── extracted.md
└── index.log            # Chronological list of captured trajectory IDs
```

**Filtering:** Before capture, `--check-complexity` determines if the task warrants recording:
```bash
# Only captures if complexity >= medium (default threshold)
./scripts/memory/traj-capture.sh --prompt "..." --complexity high \
    --check-complexity --min medium
# Returns YES → capture. NO → skip silently.
```

### Stage 2: Distillation (`distill.sh`)

**Purpose:** Convert captured trajectory into a structured wiki skill or case page — reusable knowledge artifact with frontmatter, procedure steps, context metadata.

**When triggered:** `on_capture_complete` hook fires immediately after capture (via auto-distillation in process files), OR manually:
```bash
# Distill single trajectory
./scripts/memory/distill.sh --trajectory raw/trajectories/TRJ-20260708-1130-a4f2c1d3/

# Auto-distill all undistilled trajectories (batch mode)
./scripts/memory/distill.sh --auto

# Check what's pending without distilling
./scripts/memory/distill.sh --check-undistilled
```

**Distillation logic:**
```python
# Decision tree inside distill.sh:
if tool_calls.length >= 2:
    type_label = 'skill'      # Multi-step procedure → wiki skill
else:
    type_label = 'case'       # Single step → use case / problem-solution

# Naming convention (rules/skill_format.json):
if type_label == 'skill':
    final_path = "{slug}-skill.md"     # e.g., "batch-ingest-workflow-skill.md"
else:
    final_path = "{slug}-case.md"      # e.g., "contradiction-resolution-case.md"

# Duplicate detection before write:
if file_exists(final_path):
    final_path = "{slug}-{type}-{counter}.md"  # Append counter for uniqueness
```

**Generated artifact structure:**
```markdown
---
tags: [skill, skill-batch-ingest-workflow]
date: 2026-07-08
type: documentation
category: note
aliases: []
sources: ["raw/trajectories/TRJ-20260708-1130-a4f2c1d3"]
related: []
---

# Skill: Batch Ingest Workflow

## Procedure
- read file.md: OK
- grep -m 30 pattern wiki/: OK
- auto-crosslink.sh: ERROR (skipped due to validation)

## Context
- Trigger: Original task that led to this pattern
- Outcome: success
- Complexity: high

## Notes
- Distilled from trajectory "TRJ-20260708-1130-a4f2c1d3".
```

**Pre-filter:** Before distilling, `check_procedure_coverage()` verifies ≥2 meaningful steps. Trajectories with <2 steps are skipped (not useful as reusable knowledge).

### Stage 3: Pattern Matching & Prioritization (`skill-pattern-match.sh`)

Before auto-distilling multiple trajectories, the system runs a pattern scan to prioritize related ones together:
```bash
# Scan for clusterable patterns across undistilled trajectories
./scripts/memory/skill-pattern-match.sh --mode report
```

This groups similar trajectories by shared keywords/entities so that clustered skills are created from coherent groups rather than isolated captures.

### Stage 4: Index Integration

After skill/case creation, `distill.sh` appends the new file to `wiki/index.md` automatically (if it exists):
```bash
# Inside distill.sh:
if [[ -f "wiki/index.md" ]]; then
    grep -q "$generated_file" "wiki/index.md" || \
        echo "- [[$generated_file]] → $(basename "$generated_file" .md)" >> "wiki/index.md"
fi
```

This ensures new skills/cases are immediately discoverable via the wiki index without manual intervention.

---

## Hook Triggers by Process File

### Query Hooks (`process-query.json`)

| Trigger | Action | When It Fires |
|---------|--------|---------------|
| `on_search_complete` | Capture trajectory if nontrivial | After step_1 search completes; condition: compounding_flagged OR complexity ≥ medium |
| `on_wiki_page_created_or_updated` | Update backlinks and index | After page write via auto-crosslink.sh |
| `on_capture_complete` | Auto-distill captured trajectory | Immediately after traj-capture.sh succeeds (Phase 20.2) |

**Example flow:**
```
Query → step_1 search → results found
    ↓
step_2 synthesis → compounding_flagged = true (synthesized from 3 pages)
    ↓
hook: on_search_complete → traj-capture.sh --prompt "..." --steps "[...]" --outcome success --complexity high
    ↓
hook: on_capture_complete → distill.sh --trajectory "$TRAJECTORY_PATH" --auto
    ↓
Result: wiki/skills/{slug}-skill.md created, appended to wiki/index.md
```

### Ingest Hooks (`process-ingest.json`)

| Trigger | Action | When It Fires |
|---------|--------|---------------|
| `on_source_ingested` | Register in source manifest/rebuild tracking | After validate-path + delta-tracking passes |
| `on_page_update_completed` | Check hot cache freshness | After page update; triggers hot-cache-update.sh  |
| `on_new_page_created` | Auto-crosslink new page with existing wiki | After step_8a/b completes |
| `on_ingest_complete` | Capture trajectory for nontrivial ingest | After all steps complete if complexity ≥ medium |
| `on_distillation_ready` | Check pending distillations queue | Periodic check via distill.sh --check-undistilled |

**Example flow:**
```
Ingest → source validated → hash dedup passed → capture to raw/
    ↓
Content analysis → classify → frontmatter generation → page write
    ↓
hook: on_new_page_created → auto-crosslink.sh "${PAGE_PATH}" --include-root
    ↓
hook: on_ingest_complete → traj-capture.sh --prompt "..." --complexity medium
    ↓
hook: on_distillation_ready → distill.sh --check-undistilled (auto-mode)
```

### Lint Hooks (`process-lint.json`)

| Trigger | Action | When It Fires |
|---------|--------|---------------|
| `post_lint_check` | Check pending trajectory distillations | After all lint checks complete |
| `on_hot_cache_stale_detected` | Force hot cache rebuild if needed | If hot-cache-update.sh detects stale data |
| `on_orphan_pages_found` | Update backlinks after merge/delete ops | When orphan pages are detected and fixed |

---

## Auto-Distillation (Phase 20.2)

Before Phase 20.2, memory hooks only **checked** for undistilled trajectories but never actually created new skills. The fix: auto-distillation trigger fires immediately after capture.

### How It Works

```bash
# After traj-capture.sh succeeds:
distill.sh --trajectory "$TRAJECTORY_PATH" 2>/dev/null || true

# Conditions:
# - Trajectory must have ≥2 meaningful steps (check_procedure_coverage)
# - No duplicate skill/case with same slug exists (check_duplicate_skill)
# - If already referenced in wiki/skills/ or wiki/cases/, skip silently
```

### Idempotency Guarantees

1. **Duplicate detection:** `check_duplicate_skill()` scans existing skills by frontmatter tags and file existence — if a matching slug exists, the distill is skipped
2. **Already-distilled check:** `grep -r "$traj_id" wiki/skills/ wiki/cases/` — if trajectory ID appears in any skill/case, skip silently
3. **Auto-mode batch scan:** `--auto` mode runs pattern scan first, then distills all undistilled trajectories sequentially

### Result

The capture → distill loop is fully automatic via hooks:
```
Agent performs complex action → traj-capture.sh records it
    ↓
on_capture_complete hook fires → distill.sh --trajectory <path>
    ↓
Skill/case created in wiki/skills/ or wiki/cases/ with proper naming
    ↓
Appended to wiki/index.md for discoverability
```

No manual intervention required. Trajectories are captured, analyzed, and distilled into reusable knowledge artifacts automatically.

---

## Other Memory Hooks Actions

### Hot Cache Management (`hot-cache-update.sh`, `load-hot-cache.sh`)

The hot cache (`wiki/hot.md`) is refreshed periodically to ensure next-session bootstrap has fresh data:
```bash
# Check if hot cache needs refresh (non-blocking)
./scripts/memory/hot-cache-update.sh  || ./scripts/load-hot-cache.sh

# After context compaction — restore from backup
./scripts/load-hot-cache.sh || true
```

### PRF-Enhanced Recall (`recall.sh`)

Before searching wiki content, PRF (Precision-Recall-Focus) extraction improves search quality:
```bash
# Extract keywords with TF-IDF scoring + stopwords filtering
./scripts/memory/recall.sh "query text"

# Falls back to grep if recall returns nothing
grep -m 30 'keyword' wiki/index.md
```

### Broken Link Tracking (`sync-broken-links-to-wm.sh`)

After lint detects broken links, they're synced into working memory for cross-session continuity:
```bash
# Update WM.broken_links_resolved with current issues
./scripts/memory/sync-broken-links-to-wm.sh
```

---

## Schema References Summary

| Hook Action | Canonical Source File | Process File |
|-------------|----------------------|--------------|
| Trajectory capture | `scripts/memory/traj-capture.sh` | process-query.json, process-ingest.json |
| Distillation | `scripts/memory/distill.sh` + `rules/skill_format.json` | All three process files via hooks |
| Pattern matching | `scripts/memory/skill-pattern-match.sh` | Auto mode in distill.sh |
| Hot cache refresh | `scripts/memory/hot-cache-update.sh`, `load-hot-cache.sh` | process-query.json step_0.5, process-ingest.json |
| Recall extraction | `scripts/memory/recall.sh`, `rules/search_strategy.json` | process-query.json step_1 |
| Backlink updates | `scripts/auto-crosslink.sh`, `meta/backlinks.json` | All three via on_wiki_page_created_or_updated hook |

---

## Debugging & Manual Operations

### List Captured Trajectories
```bash
./scripts/memory/traj-capture.sh --list
# Output: [!] Trajectories: 15 recorded in raw/trajectories/
#         Recent trajectories:
#           TRJ-20260708-1130-a4f2c1d3 → outcome: success
#           ...
```

### Check Undistilled Queue
```bash
./scripts/memory/distill.sh --check-undistilled
# Output: [!] 3 undistilled trajectories remain
#         raw/trajectories/TRJ-... → not yet distilled
```

### Distill Specific Trajectory Manually
```bash
./scripts/memory/distill.sh --trajectory "raw/trajectories/TRJ-20260708-1130-a4f2c1d3/"
# Output: [✓] SKILL created: batch-ingest-workflow-skill.md → wiki/skills/batch-ingest-workflow-skill.md
```

### Auto-Distill All Pending
```bash
./scripts/memory/distill.sh --auto
# Runs pattern scan first, then distills all undistilled trajectories sequentially
```

---

## Summary

Memory hooks in Loomana:

1. **Capture:** `traj-capture.sh` records agent actions as structured trajectories (packet.json + extracted.md) — triggered on nontrivial operations via process file hooks
2. **Distill:** `distill.sh` converts trajectories into wiki skills/cases with frontmatter, procedure steps, context metadata — auto-triggered after capture via on_capture_complete hook
3. **Pattern matching:** `skill-pattern-match.sh` groups related trajectories before distillation for coherent skill creation
4. **Index integration:** New skills/cases automatically appended to wiki/index.md for discoverability

All hooks are non-blocking (failures don't stop main process). Duplicate detection and idempotency checks prevent redundant artifacts. The capture → distill loop runs automatically through memory_hooks definitions in process files — no manual intervention required.

For hook architecture details: read `scripts/memory/hooks-spec.md` and process-query.json/process-ingest.json/process-lint.json `memory_hooks` sections.