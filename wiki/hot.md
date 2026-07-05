---
tags: [cache, system]
date: 2026-07-04
category: cache
sources: []
related: []
---
# Wiki Hot Cache — Last Updated: 2026-07-04

## Active Project (WORK_MODE: project)
- **Project**: Loomana wiki — Phase 14+15 compaction + routing fix
- **Status**: IN PROGRESS 🟥
- **Focus node**: process-query.json → process-ingest.json mandatory transition
- **Related wiki pages**: `process-query.json`, `AGENTS.md`
- **Completed actions**: 
  - step_2.7 added: mandatory gateway for web_search → user_confirm → process-ingest.json
  - All direct wiki-write actions replaced with PROPOSE_*_TO_USER + transition_after_confirm
  - Guardrails added to steps 2, 2.5, 2.6, 3
- **Next steps**: Verify AGENTS.md global rule exists; test query flow end-to-end

## Active Session Context
- **Topic**: Fix process-query.json routing — all wiki-write must go through process-ingest.json
- **User query intent**: Audit + fix all points where process-query creates/updates wiki pages directly
- **Pages read**: `process-query.json`, `AGENTS.md`
- **Key findings**: 
  - Found 7+ direct wiki-write actions bypassing ingest flow
  - All replaced with proposals → user_confirm → transition to process-ingest.json
  - Added step_2.7 mandatory gateway for web_search sources

## System State
### Active Threads
- Phase 14: Compact Rules + AGENTS.md → IN PROGRESS 🟥
- **NEW**: Phase 15: process-query → process-ingest routing fix — IN PROGRESS 🟥
- Issue #39: Context bloat → AGENTS.md compaction pending

### Recent Changes
- **2026-07-05**: process-query.json routing fix — all wiki-write actions routed through process-ingest.json via step_2.7 gateway
- **2026-07-03**: Wiki health check — resolved all 7 orphan pages via crosslinks, fixed contradictions in natural-memory.md and python-nixos-development.md
- **2026-07-01**: Phase 23 (Unified Pass Architecture) fully completed — unified-pass.sh replaces 3 separate script walks

- `2026-07-05 15:00` — **System change**: Updated web_ingest_flow logic to distinguish three scenarios (update_existing / topic_expansion / new_independent_topic). Auto-ingest now covers both scenario 1 AND scenario 2; user_confirm only required for first page of scenario 3.
## Session Context — 2026-07-04 Tag Audit
**Status**: ✅ Complete. All entity/concept pages now have ≥3 domain-specific tags per tag-guidelines.json. Generic type-tags removed from 2 pages. Next: Phase 15.1 (aliases for discoverability).

## Session Context — 2026-07-04 Final State
**Status**: ✅ Tag audit complete. All entity/concept pages have ≥3 domain tags. Orphan page archived to raw/. Hot cache updated.
**Next**: Phase 15.1 (aliases for discoverability) + contradiction resolution (soft, optional).

## Session Context — 2026-07-05 Search Contract Fix
**Status**: ✅ Search strategy fixed in process-query.json — replaced pseudo-actions with wiki-search.sh --dynamic commands. English-only enforced across all instructions.
**Changes applied**: AGENTS.md#Search Contract added, RULES.md language rule added, 3 Cyrillic constraints → English, 6 pseudo-actions → structured steps.
**Next**: Phase 14 (AGENTS.md compaction) + Phase 15 (Tagging System).

## Recent Changes — 2026-07-05
- **twig-templating.md** updated: added official twig.symfony.com features (Fast/Secure/Flexible, PHP comparison, ecosystem)
- **index.md** rebuilt via rebuild-meta.sh --index-only
