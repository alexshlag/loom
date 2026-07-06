---
tags: [cache, system]
date: 2026-07-06
category: note
sources: []
related: []
---
# Wiki Hot Cache — Last Updated: 2026-07-06

## Active Project (WORK_MODE: project)
- **Project**: Loomana wiki architecture optimization + knowledge management
- **Status**: 🟢 ACTIVE SESSION — Phase 16.1 recall engine + hot cache optimization

## Active Session Context
- **Focus node**: Phase 16.1 Tasks #3+#4 COMPLETED — PRF-enhanced recall (recall.sh) + hot cache optimization (hot-cache-update.sh check-only mode)

### Pending Tasks
- **Issue #28** — page templates co-evolution user approval mechanism (priority: medium)
- ~~**Issue #27**~~ ✅ RESOLVED (commit 60963fd, `rules/broken_link_handling.json`)

## Recent Changes (Phase 16.1)
- **recall-engine** | PRF-enhanced recall engine (`scripts/memory/recall.sh`): Stage 1 links-first ranked paths → Stage 2 content expansion loads only top-K pages; replaced all wiki-search.sh calls in process-query.json
- **hot-cache-opt** | Hot cache optimization: `scripts/memory/hot-cache-update.sh` check-only mode compares timestamps before loading hot.md; added schema_ref to hot-cache-spec.md

## Recent Changes (dev mode)
- **git-conventions** | Fixed explicit pre-commit workflow: read rules → detect mode → stage → verify → format → memory sync; session_bootstrap.json step 3
- **session-bootstrap** | Added explicit session start sequence via rules/session_bootstrap.json
- **benchmark-rebuild** | Created scripts/benchmark-rebuild.sh for perf comparison single-pass vs triple-walk

## Recent Changes (wiki)
- **php-ingest** | Created wiki/entities/php.md — comprehensive PHP overview; crosslinks added to symfony, symfony-dependency-injection, hexagonal-architecture
- **agent-memory-management** | Ingest: 2 new pages on LLM agent memory techniques + comparison matrix for loomana applicability

## System State
### Active Threads
- Wiki maintenance and expansion (auto-fixes running on lint errors)
- Knowledge base growth via query responses and source ingestion
- Phase 16.1: recall.sh PRF engine integrated into process-query.json flow

- **Recent activity**: hot-cache-fix | Replaced agent instructions with enforce commands in process-query.json + process-ingest.json — auto-refresh.sh now triggered on query compaction (step_2.3) and ingest post_checks (step_9)
