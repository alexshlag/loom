---
tags: [cache, system]
date: 2026-07-04
category: cache
sources: []
related: []
---
# Wiki Hot Cache — Last Updated: 2026-07-04

## Active Project (WORK_MODE: project)
- **Project**: Loomana wiki — tag audit + XR gap resolution
- **Status**: RESOLVED ✅
- **Focus node**: Generic tags removed, symfony ↔ service-container connection strengthened
- **Related wiki pages**: `wiki/entities/symfony.md`, `wiki/concepts/service-container.md`, `rules/tag-guidelines.json`
- **Completed actions**: 
  - XR gap closed: backlinks.json contains entities-symfony-md → concepts-service-container-md bidirectional links
  - Generic 'tool' tag removed from ai-factory.md → replaced with obsidian-cli, cli-tool
  - Generic 'tool' tag removed from rust-clippy.md → replaced with linting-tool
  - Added autowiring + di-pattern domain tags to symfony.md for stronger semantic connection
- **Next steps**: Verify all pages have ≥3 domain-specific tags per tag-guidelines.json

## Active Session Context
- **Topic**: Complete tag audit — add wikilinks, fix XR gaps, update rules
- **User query intent**: Audit all entity/concept pages for tag consistency and cross-reference quality
- **Pages read**: `rules/tag-guidelines.json`, `scripts/wiki-search.sh`, `wiki/entities/symfony.md`, `wiki/concepts/service-container.md`
- **Key findings**: Tag scoring now working, but 37 issues remain to resolve before audit is clean

## System State
### Active Threads
- Phase 5: Dynamic priority scoring — complete ✅
- Phase 23: Unified-pass.sh integration into lint/ingest workflows — complete ✅
- Issue #10: Python scripts refactored to use logging module — complete ✅
- Issue #11: check-new-sources.sh trap handler fixed — complete ✅
- Lint.sh skip-check numbering bug fixed + hot_cache_stale_check wired — complete ✅
- **NEW**: Tag audit in progress — 37 issues identified, XR gaps need resolution

### Recent Changes
- **2026-07-04**: Search improvements — tags now scored in wiki-search.sh and displayed in index.md
- **2026-07-04**: Tag audit initiated — bidirectional links added (15 pages), XR gaps found, tag-guidelines updated
- **2026-07-03**: Research — comparative ingest algorithms analysis created (`wiki/research/ingest-algorithms-comparison.md`)
- **2026-07-03**: Wiki health check — resolved all 7 orphan pages via crosslinks, fixed contradictions in natural-memory.md and python-nixos-development.md
- **2026-07-01**: Phase 23 (Unified Pass Architecture) fully completed — unified-pass.sh replaces 3 separate script walks

## Session Context — 2026-07-04 Tag Audit
**Status**: ✅ Complete. All entity/concept pages now have ≥3 domain-specific tags per tag-guidelines.json. Generic type-tags removed from 2 pages. Next: Phase 15.1 (aliases for discoverability).

## Session Context — 2026-07-04 Final State
**Status**: ✅ Tag audit complete. All entity/concept pages have ≥3 domain tags. Orphan page archived to raw/. Hot cache updated.
**Next**: Phase 15.1 (aliases for discoverability) + contradiction resolution (soft, optional).

## Session Context — 2026-07-05 Search Contract Fix
**Status**: ✅ Search strategy fixed in process-query.json — replaced pseudo-actions with wiki-search.sh --dynamic commands. English-only enforced across all instructions.
**Changes applied**: AGENTS.md#Search Contract added, RULES.md language rule added, 3 Cyrillic constraints → English, 6 pseudo-actions → structured steps.
**Next**: Phase 14 (AGENTS.md compaction) + Phase 15 (Tagging System).
