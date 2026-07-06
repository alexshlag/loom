# Memory Hooks Spec — Async Background Processing for Wiki Operations

**Phase**: Phase 16.1, Task #5: Process file refactoring (extract memory ops into hooks)  
**Target Files**: `process-query.json`, `process-ingest.json`, `process-lint.json`

---

## Problem

Memory operations (working_memory writes, hot.md updates, backlink maintenance) are inline in process steps → context bloat and tight coupling between content processing and memory management.

## Solution: Hook-Based Async Processing

Each process file gains a `memory_hooks` section. When triggered, hooks emit events that the memory subsystem handles asynchronously — without blocking the main process flow.

### Architecture

```
┌─────────────┐     ┌──────────┐     ┌──────────────────────┐
│ Query        │     │ Ingest   │     │ Lint                  │
│ Process       │◄──►| Process  │◄──►| Process               │
└──────┬───────┘     └───┬──────┘     └──────────┬───────────┘
       │                │                        │
       ▼                ▼                        ▼
   Memory Hooks      Memory Hooks             Memory Hooks
       │                │                        │
       ▼                ▼                        ▼
  memory/ subsystem handles async operations:
  - working_memory.json updates
  - hot.md snapshot maintenance  
  - trajectory capture & distillation
  - backlink/index updates
```

### Hook Definitions by Process

#### Query Hooks (`process-query.json`)

| Trigger | Action | Schema Ref |
|---------|--------|------------|
| `on_compaction_done` | Write WM focus_node + next_steps_todo, write session context to hot.md | — |
| `on_search_complete` | Capture trajectory if nontrivial (compounding_flagged OR complexity ≥ medium) | `scripts/memory/traj-capture.sh` |
| `on_wiki_page_created_or_updated` | Update backlinks and index via auto-crosslink | `scripts/auto-crosslink.sh` |

#### Ingest Hooks (`process-ingest.json`)

| Trigger | Action | Schema Ref |
|---------|--------|------------|
| `on_source_ingested` | Register in source manifest/rebuild tracking | `scripts/rebuild-source-manifest.sh` |
| `on_page_update_completed` | Check hot cache freshness, trigger rebuild if stale | `scripts/memory/hot-cache-update.sh --check-only` |
| `on_new_page_created` | Auto-crosslink new page with existing wiki | `scripts/auto-crosslink.sh` |
| `on_ingest_complete` | Capture trajectory for nontrivial ingest operations | `scripts/memory/traj-capture.sh` |
| `on_distillation_ready` | Check pending distillations queue | `scripts/memory/distill.sh --check-undistilled` |

#### Lint Hooks (`process-lint.json`)

| Trigger | Action | Schema Ref |
|---------|--------|------------|
| `post_lint_check` | Check pending trajectory distillations | `scripts/memory/distill.sh --check-undistilled` |
| `on_hot_cache_stale_detected` | Force hot cache rebuild if needed | `scripts/memory/hot-cache-update.sh --rebuild` |
| `on_orphan_pages_found` | Update backlinks after merge/delete operations | `scripts/auto-crosslink.sh` |

### Integration Rules

1. **Hooks are non-blocking**: Memory subsystem processes hooks asynchronously — main process never waits for memory ops to complete.
2. **No inline memory logic**: Steps like "write_to_working_memory" exist only as hook definitions, not inline step actions.
3. **Fallback safety**: If a hook command fails (e.g., `|| true`), the main process continues unaffected.
4. **Schema references**: Each hook action points to its canonical source file via `schema_ref`.

### Success Criteria

1. ✅ All three process files have `memory_hooks` section  
2. ✅ Inline memory operations replaced with async hooks  
3. ✅ Memory subsystem scripts exist and are callable from hooks  
4. ✅ No breaking changes to existing step logic  
