---
tags: [cache, system]
date: 2026-07-04
category: cache
sources: []
related: []
---
# Wiki Hot Cache — Last Updated: 2026-07-04

## Active Project (WORK_MODE: project)
- **Project**: Ingest algorithms comparative research
- **Focus node**: Comparative analysis of ingest algorithms from pi-llm-wiki and claude-obsidian, article created (`wiki/research/ingest-algorithms-comparison.md`)
- **Related wiki pages**: `wiki/concepts/natural-memory.md`, `wiki/entities/symfony.md`, `wiki/entities/api-platform.md`
- **Key findings**: 
  - wiki-lock.sh (advisory locking) — critical for parallel safety
  - Background synthesis + deterministic commit — high reliability improvement
  - Real-time contradiction callouts — prevents silent overwrites
  - Mode-aware routing and address assignment — future-proofing
- **Next steps_todo**: 
  - Implement wiki-lock.sh (Phase 1: Critical) — flock-based advisory locks per-file
  - Add real-time contradiction callouts to process-ingest.json#step_3_analysis
  - Create scripts/ingest-worker.sh with background synthesis (Phase 2: High)

## Active Session Context
- **Topic**: Ingest algorithms comparative research — analyzing pi-llm-wiki and claude-obsidian approaches
- **Pages read**: `wiki/research/ingest-algorithms-comparison.md` (created), `wiki/concepts/natural-memory.md`, `wiki/entities/symfony.md`, `wiki/entities/api-platform.md`
- **Key findings**: Same as above — key architectural improvements for wiki

## System State
### Active Threads
- Phase 23 Step 3: unified-pass.sh integration into lint/ingest workflows (COMPLETED)
- Issue #10: Python scripts refactored to use logging module (COMPLETED)
- Issue #11: check-new-sources.sh trap handler fixed (COMPLETED)
- Lint.sh skip-check numbering bug fixed + hot_cache_stale_check wired (COMPLETED)

### Recent Changes
- **2026-07-03**: Research — comparative ingest algorithms analysis created (`wiki/research/ingest-algorithms-comparison.md`)
- **2026-07-03**: Wiki health check — resolved all 7 orphan pages via crosslinks, fixed contradictions in natural-memory.md and python-nixos-development.md
- **2026-07-01**: Phase 23 (Unified Pass Architecture) fully completed — unified-pass.sh replaces 3 separate script walks
