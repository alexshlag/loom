---
tags: [cache, system]
date: 2026-07-04
category: cache
sources: []
related: []
---
# Wiki Hot Cache — Last Updated: 2026-07-04

## Active Project (WORK_MODE: project)
- **Project**: wiki search improvements — tag scoring + index display
- **Focus node**: tags now used in search (wiki-search.sh score +1 per match) and displayed in index.md
- **Related wiki pages**: `scripts/wiki-search.sh`, `scripts/rebuild-meta.sh`
- **Key findings**: 
  - Tags now scored: +1 per tag that matches any query word → affects ranking
  - Index.md now shows tags as `[tag] [tag] [tag]` after page summary (max 3)
  - Combined A + C implementation complete

## Active Session Context
- **Topic**: Improve wiki search with tags — user requested variants A & C
- **User query intent**: Add tag scoring to wiki-search.sh and show tags in index.md rebuild
- **Pages read**: `scripts/wiki-search.sh`, `scripts/rebuild-meta.sh`, `wiki/index.md`
- **Key findings**: Tags were dead data (not used in search or index). Now fixed: A) score +1 per tag match, C) tags displayed after summary

## System State
### Active Threads
- Phase 23 Step 3: unified-pass.sh integration into lint/ingest workflows (COMPLETED)
- Issue #10: Python scripts refactored to use logging module (COMPLETED)
- Issue #11: check-new-sources.sh trap handler fixed (COMPLETED)
- Lint.sh skip-check numbering bug fixed + hot_cache_stale_check wired (COMPLETED)
- **NEW**: Tags scoring implemented — wiki-search.sh (+1 per tag match), index.md shows tags

### Recent Changes
- **2026-07-04**: Search improvements — tags now scored in wiki-search.sh and displayed in index.md
- **2026-07-03**: Research — comparative ingest algorithms analysis created (`wiki/research/ingest-algorithms-comparison.md`)
- **2026-07-03**: Wiki health check — resolved all 7 orphan pages via crosslinks, fixed contradictions in natural-memory.md and python-nixos-development.md
- **2026-07-01**: Phase 23 (Unified Pass Architecture) fully completed — unified-pass.sh replaces 3 separate script walks
