---
tags: [memory-hierarchy, trajectory-pipeline, auto-distillation, hook-system]
date: 2026-07-08
type: documentation
category: concept
aliases: []
sources: ["docs/memory-hooks.md"]
related: ["wiki/docs/loom-scripts-guide", "wiki/docs/loom-rules-reference", "wiki/concepts/natural-memory"]
---
# Memory Hooks & Trajectory Pipeline

# Memory Hooks & Trajectory Pipeline

Page covering Memory Hooks & Trajectory Pipeline — overview, usage patterns, and related resources.
## Overview

Memory hooks are the asynchronous background system powering Loomana's self-improvement. They decouple memory management from content processing, allowing the main workflow to continue without waiting for memory operations.

Architecture follows a three-layer model:

1. **Process Layer** — query/ingest/lint (main workflow)
2. **Memory Hooks** — async triggers per process step (`memory_hooks` in `process-*.json`)
3. **Memory Subsystem** — scripts handling capture, distill, backlinks, hot cache

### Key Principles

- **Non-blocking**: Hook failures use `|| true`, never stop the main process
- **No inline memory logic**: Steps reference hooks via schema_ref, not inline commands
- **Schema references**: Each hook points to canonical source via schema_ref pattern

## The Trajectory Pipeline: Capture → Distill → Wiki Skill

When the agent performs a non-trivial operation (complex query, multi-source ingest), it's distilled into reusable knowledge artifacts in three stages.

### Stage 1: Trajectory Capture (`traj-capture.sh`)

**Purpose:** Record agent actions as structured data for later analysis and reuse.

**Trigger conditions:** `on_search_complete` or `on_ingest_complete` fires when:
- `compounding_flagged = true` (answer synthesized from 2+ pages)
- OR task complexity ≥ medium

**Command format:**
```bash
./scripts/memory/traj-capture.sh \
    --prompt "user query" \
    --steps '[{"name":"read","tool_name":"read file.md"}]' \
    --outcome success | partial | failure \
    --complexity low | medium | high
```

**Output:** Creates `raw/trajectories/TRJ-{timestamp}-{id}/` with:
- `packet.json` — structured metadata (id, timestamp, prompt, tool_calls, outcome, complexity)
- `extracted.md` — human-readable summary of steps executed and errors encountered

**Filtering:** `--check-complexity --min medium` prevents low-value captures. Returns YES → capture; NO → skip silently.

### Stage 2: Distillation (`distill.sh`)

**Purpose:** Convert captured trajectories into structured wiki skills/cases with frontmatter, procedure steps, and context metadata.

**Trigger:** `on_capture_complete` hook fires immediately after capture (auto-distillation), OR manual:
```bash
# Single trajectory
./scripts/memory/distill.sh --trajectory raw/trajectories/TRJ-20260708-1130-a4f2c1d3

# All undistilled
./scripts/memory/distill.sh --auto

# Check pending without distilling
./scripts/memory/distill.sh --check-undistilled
```

**Distillation logic:**
| Condition | Result Type | Example Path |
|-----------|-------------|--------------|
| ≥2 tool calls | `skill` | `{slug}-skill.md` |
| <2 tool calls | `case` | `{slug}-case.md` |

Duplicate detection prevents overwrites — matching slug gets a counter suffix.

### Stage 3: Pattern Matching & Prioritization (`skill-pattern-match.sh`)

Groups similar trajectories by shared keywords/entities so that clustered skills are created from coherent groups rather than isolated captures:
```bash
./scripts/memory/skill-pattern-match.sh --mode report
```

### Stage 4: Index Integration

After skill/case creation, `distill.sh` appends the new file to `wiki/index.md`:
```bash
grep -q "$generated_file" "wiki/index.md" || \
    echo "- [[$generated_file]] → $(basename "$generated_file" .md)" >> "wiki/index.md"
```

## Hook Triggers by Process File

### Query Hooks

| Trigger | Action | When |
|---------|--------|------|
| `on_search_complete` | Capture trajectory if nontrivial | After step_1 search; compounding_flagged OR complexity ≥ medium |
| `on_wiki_page_created_or_updated` | Update backlinks and index | After page write via auto-crosslink.sh |
| `on_capture_complete` | Auto-distill captured trajectory | Immediately after traj-capture.sh (Phase 20.2) |

### Ingest Hooks

| Trigger | Action | When |
|---------|--------|------|
| `on_source_ingested` | Register in source manifest | After validate-path + delta-tracking passes |
| `on_page_update_completed` | Check hot cache freshness | After page update |
| `on_new_page_created` | Auto-crosslink new page | After step_8a/b completes |
| `on_ingest_complete` | Capture trajectory for nontrivial ingest | After all steps if complexity ≥ medium |
| `on_distillation_ready` | Check pending distillations queue | Periodic via distill.sh --check-undistilled |

### Lint Hooks

| Trigger | Action | When |
|---------|--------|------|
| `post_lint_check` | Check pending trajectory distillations | After all lint checks complete |
| `on_hot_cache_stale_detected` | Force hot cache rebuild | If hot-cache-update.sh detects stale data |
| `on_orphan_pages_found` | Update backlinks after merge/delete ops | When orphan pages are detected and fixed |

## Auto-Distillation (Phase 20.2)

Before Phase 20.2, hooks only **checked** for undistilled trajectories but never created new skills. Now auto-distillation triggers immediately after capture.

### Idempotency Guarantees

1. **Duplicate detection:** `check_duplicate_skill()` scans existing skills by frontmatter tags and file existence — matching slug is skipped
2. **Already-distilled check:** `grep -r "$traj_id" wiki/skills/ wiki/cases/` — if trajectory ID appears in any skill/case, skip silently
3. **Auto-mode batch scan:** `--auto` runs pattern scan first, then distills all undistilled trajectories sequentially

## Other Memory Subsystem Actions

### Hot Cache Management

Refreshes `wiki/hot.md` for next-session bootstrap:
```bash
./scripts/memory/hot-cache-update.sh  || ./scripts/load-hot-cache.sh
# After context compaction — restore from backup
./scripts/load-hot-cache.sh || true
```

### PRF-Enhanced Recall (`recall.sh`)

Extracts keywords with TF-IDF scoring + stopwords filtering before wiki search:
```bash
./scripts/memory/recall.sh "query text"
# Falls back to grep if recall returns nothing
grep -m 30 'keyword' wiki/index.md
```

### Broken Link Tracking (`sync-broken-links-to-wm.sh`)

Syncs lint-detected broken links into working memory for cross-session continuity:
```bash
./scripts/memory/sync-broken-links-to-wm.sh
```

## Schema References

| Hook Action | Canonical Source | Process Files |
|-------------|-----------------|---------------|
| Trajectory capture | `scripts/memory/traj-capture.sh` | process-query.json, process-ingest.json |
| Distillation | `distill.sh`, `rules/skill_format.json` | All three via hooks |
| Pattern matching | `skill-pattern-match.sh` | Auto mode in distill.sh |
| Hot cache refresh | `hot-cache-update.sh`, `load-hot-cache.sh` | process-query.json, process-ingest.json |
| Recall extraction | `recall.sh`, `rules/search_strategy.json` | process-query.json step_1 |
| Backlink updates | `auto-crosslink.sh`, `meta/backlinks.json` | All three via on_wiki_page_created_or_updated hook |

## Debugging & Manual Operations

```bash
# List captured trajectories
./scripts/memory/traj-capture.sh --list

# Check undistilled queue
./scripts/memory/distill.sh --check-undistilled

# Distill specific trajectory manually
./scripts/memory/distill.sh --trajectory "raw/trajectories/TRJ-.../"

# Auto-distill all pending (with pattern scan first)
./scripts/memory/distill.sh --auto
```

## Summary

Memory hooks in Loomana:

1. **Capture:** `traj-capture.sh` records agent actions as structured trajectories — triggered on nontrivial operations via process file hooks
2. **Distill:** `distill.sh` converts trajectories into wiki skills/cases — auto-triggered after capture via `on_capture_complete` hook
3. **Pattern matching:** `skill-pattern-match.sh` groups related trajectories before distillation for coherent skill creation
4. **Index integration:** New skills/cases automatically appended to `wiki/index.md`

All hooks are non-blocking (failures don't stop main process). Duplicate detection and idempotency checks prevent redundant artifacts. The capture → distill loop runs automatically through memory_hooks definitions in process files — no manual intervention required.

For architecture details: read `scripts/memory/hooks-spec.md`.
