` Auto-distill undistilled trajectories (find & create skill/case pages)``# Memory Hooks Spec — Async Background Processing for Wiki Operations
` Auto-distill undistilled trajectories (find & create skill/case pages)``
` Auto-distill undistilled trajectories (find & create skill/case pages)``**Phase**: Phase 16.1, Task #5: Process file refactoring (extract memory ops into hooks)  
` Auto-distill undistilled trajectories (find & create skill/case pages)``**Target Files**: `process-query.json`, `process-ingest.json`, `process-lint.json`
` Auto-distill undistilled trajectories (find & create skill/case pages)``
` Auto-distill undistilled trajectories (find & create skill/case pages)``---
` Auto-distill undistilled trajectories (find & create skill/case pages)``
` Auto-distill undistilled trajectories (find & create skill/case pages)``## Problem
` Auto-distill undistilled trajectories (find & create skill/case pages)``
` Auto-distill undistilled trajectories (find & create skill/case pages)``Memory operations (working_memory writes, hot.md updates, backlink maintenance) are inline in process steps → context bloat and tight coupling between content processing and memory management.
` Auto-distill undistilled trajectories (find & create skill/case pages)``
` Auto-distill undistilled trajectories (find & create skill/case pages)``## Solution: Hook-Based Async Processing
` Auto-distill undistilled trajectories (find & create skill/case pages)``
` Auto-distill undistilled trajectories (find & create skill/case pages)``Each process file gains a `memory_hooks` section. When triggered, hooks emit events that the memory subsystem handles asynchronously — without blocking the main process flow.
` Auto-distill undistilled trajectories (find & create skill/case pages)``
` Auto-distill undistilled trajectories (find & create skill/case pages)``### Architecture
` Auto-distill undistilled trajectories (find & create skill/case pages)``
` Auto-distill undistilled trajectories (find & create skill/case pages)`````
` Auto-distill undistilled trajectories (find & create skill/case pages)``┌─────────────┐     ┌──────────┐     ┌──────────────────────┐
` Auto-distill undistilled trajectories (find & create skill/case pages)``│ Query        │     │ Ingest   │     │ Lint                  │
` Auto-distill undistilled trajectories (find & create skill/case pages)``│ Process       │◄──►| Process  │◄──►| Process               │
` Auto-distill undistilled trajectories (find & create skill/case pages)``└──────┬───────┘     └───┬──────┘     └──────────┬───────────┘
` Auto-distill undistilled trajectories (find & create skill/case pages)``       │                │                        │
` Auto-distill undistilled trajectories (find & create skill/case pages)``       ▼                ▼                        ▼
` Auto-distill undistilled trajectories (find & create skill/case pages)``   Memory Hooks      Memory Hooks             Memory Hooks
` Auto-distill undistilled trajectories (find & create skill/case pages)``       │                │                        │
` Auto-distill undistilled trajectories (find & create skill/case pages)``       ▼                ▼                        ▼
` Auto-distill undistilled trajectories (find & create skill/case pages)``  memory/ subsystem handles async operations:
` Auto-distill undistilled trajectories (find & create skill/case pages)``  - working_memory.json updates
` Auto-distill undistilled trajectories (find & create skill/case pages)``  - hot.md snapshot maintenance  
` Auto-distill undistilled trajectories (find & create skill/case pages)``  - trajectory capture & distillation
` Auto-distill undistilled trajectories (find & create skill/case pages)``  - backlink/index updates
` Auto-distill undistilled trajectories (find & create skill/case pages)`````
` Auto-distill undistilled trajectories (find & create skill/case pages)``
` Auto-distill undistilled trajectories (find & create skill/case pages)``### Hook Definitions by Process
` Auto-distill undistilled trajectories (find & create skill/case pages)``
` Auto-distill undistilled trajectories (find & create skill/case pages)``#### Query Hooks (`process-query.json`)
` Auto-distill undistilled trajectories (find & create skill/case pages)``
` Auto-distill undistilled trajectories (find & create skill/case pages)``| Trigger | Action | Schema Ref |
` Auto-distill undistilled trajectories (find & create skill/case pages)``|---------|--------|------------|
` Auto-distill undistilled trajectories (find & create skill/case pages)``| `on_compaction_done` | Write WM focus_node + next_steps_todo, write session context to hot.md | — |
` Auto-distill undistilled trajectories (find & create skill/case pages)``| `on_search_complete` | Capture trajectory if nontrivial (compounding_flagged OR complexity ≥ medium) | `scripts/memory/traj-capture.sh` |
` Auto-distill undistilled trajectories (find & create skill/case pages)``| `on_wiki_page_created_or_updated` | Update backlinks and index via auto-crosslink | `scripts/auto-crosslink.sh` |
` Auto-distill undistilled trajectories (find & create skill/case pages)``
` Auto-distill undistilled trajectories (find & create skill/case pages)``#### Ingest Hooks (`process-ingest.json`)
` Auto-distill undistilled trajectories (find & create skill/case pages)``
` Auto-distill undistilled trajectories (find & create skill/case pages)``| Trigger | Action | Schema Ref |
` Auto-distill undistilled trajectories (find & create skill/case pages)``|---------|--------|------------|
` Auto-distill undistilled trajectories (find & create skill/case pages)``| `on_source_ingested` | Register in source manifest/rebuild tracking | `scripts/rebuild-source-manifest.sh` |
` Auto-distill undistilled trajectories (find & create skill/case pages)``| `on_page_update_completed` | Check hot cache freshness, trigger rebuild if stale | `scripts/memory/hot-cache-update.sh ` |
` Auto-distill undistilled trajectories (find & create skill/case pages)``| `on_new_page_created` | Auto-crosslink new page with existing wiki | `scripts/auto-crosslink.sh` |
` Auto-distill undistilled trajectories (find & create skill/case pages)``| `on_ingest_complete` | Capture trajectory for nontrivial ingest operations | `scripts/memory/traj-capture.sh` |
` Auto-distill undistilled trajectories (find & create skill/case pages)``| `on_distillation_ready` | Check pending distillations queue | `scripts/memory/distill.sh --check-undistilled` |
` Auto-distill undistilled trajectories (find & create skill/case pages)``
` Auto-distill undistilled trajectories (find & create skill/case pages)``#### Lint Hooks (`process-lint.json`)
` Auto-distill undistilled trajectories (find & create skill/case pages)``
` Auto-distill undistilled trajectories (find & create skill/case pages)``| Trigger | Action | Schema Ref |
` Auto-distill undistilled trajectories (find & create skill/case pages)``|---------|--------|------------|
` Auto-distill undistilled trajectories (find & create skill/case pages)``| `post_lint_check` | Check pending trajectory distillations | `scripts/memory/distill.sh --check-undistilled` |
` Auto-distill undistilled trajectories (find & create skill/case pages)``| `on_hot_cache_stale_detected` | Force hot cache rebuild if needed | `scripts/memory/hot-cache-update.sh --rebuild` |
` Auto-distill undistilled trajectories (find & create skill/case pages)``| `on_orphan_pages_found` | Update backlinks after merge/delete operations | `scripts/auto-crosslink.sh` |
` Auto-distill undistilled trajectories (find & create skill/case pages)``
` Auto-distill undistilled trajectories (find & create skill/case pages)``### Integration Rules
` Auto-distill undistilled trajectories (find & create skill/case pages)``
` Auto-distill undistilled trajectories (find & create skill/case pages)``1. **Hooks are non-blocking**: Memory subsystem processes hooks asynchronously — main process never waits for memory ops to complete.
` Auto-distill undistilled trajectories (find & create skill/case pages)``2. **No inline memory logic**: Steps like "write_to_working_memory" exist only as hook definitions, not inline step actions.
` Auto-distill undistilled trajectories (find & create skill/case pages)``3. **Fallback safety**: If a hook command fails (e.g., `|| true`), the main process continues unaffected.
` Auto-distill undistilled trajectories (find & create skill/case pages)``4. **Schema references**: Each hook action points to its canonical source file via `schema_ref`.
` Auto-distill undistilled trajectories (find & create skill/case pages)``
` Auto-distill undistilled trajectories (find & create skill/case pages)``### Success Criteria
` Auto-distill undistilled trajectories (find & create skill/case pages)``
` Auto-distill undistilled trajectories (find & create skill/case pages)``1. ✅ All three process files have `memory_hooks` section  
` Auto-distill undistilled trajectories (find & create skill/case pages)``2. ✅ Inline memory operations replaced with async hooks  
` Auto-distill undistilled trajectories (find & create skill/case pages)``3. ✅ Memory subsystem scripts exist and are callable from hooks  
` Auto-distill undistilled trajectories (find & create skill/case pages)``4. ✅ No breaking changes to existing step logic  
