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
- **Focus node**: Tag consistency across entity/concept pages, shared domain tags for crosslinks
- **Related wiki pages**: `wiki/entities/symfony.md`, `wiki/concepts/service-container.md`, `rules/tag-guidelines.json`
- **Key findings**: 
  - Added 15 bidirectional wikilinks (entities ↔ concepts)
  - Found XR gap: symfony.md → service-container.md lacks shared domain tags
  - TAG-P6 updated: non-English tag violation detected across 15 pages
  - Total issues found: 37 (1 empty, 15 non-EN, 21 generic, 1 XR gap)
- **Next steps**: Fix XR gaps, convert non-English tags to English equivalents, remove generic type tags

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
