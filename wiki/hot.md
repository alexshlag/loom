---
tags: [cache, system]
date: 2026-07-09
category: note
sources: []
related: []
---
# Wiki Hot Cache — Last Updated: 2026-07-09

## Active Project (WORK_MODE: project)
- **Project**: Loomana context management refactor + git sync unification + routing rules
- **Status**: 🟢 SESSION 2 COMPLETE — All refactoring applied, pushed to origin

## Session 2 Summary (2026-07-09)
### Completed
1. ✅ Cluster A merge: 4 context budget files → 1 (362→32 lines). Deleted `context-management-instructions.md`, `source_transient_ingest.json`. Removed `context_budget_rules` block from session_context_rules.json.
2. ✅ Fixed 3 cross-reference integrity issues (EXT-RES1, compaction anchor, missing `rules/` prefix)
3. ✅ Russian text removed from 4 rule files
4. ✅ pre-commit flow unified: `git_conventions.json` step 0 = memory_sync. RULES.md §8.1/§11 deduplicated to schema_ref.
5. ✅ Resource page routing: app templates/configs → `wiki/resources/` (not `wiki/templates/`). RESOURCE-PAGE-V1 added.
6. ✅ `parent_entity_identification` heuristic: 4 rules for correct tag[0]/file prefix assignment.

### Key Changes
- `rules/context_budget.json` — 32-line compact replacement for 362 lines across 4 files
- `rules/git_conventions.json#pre_commit_workflow` — step 0 = memory_sync, steps 1-5 = git ops
- `rules/tag-guidelines.json#parent_entity_identification` — 4 heuristics for parent entity detection
- `rules/structural_requirements.json#RESOURCE-PAGE-V1` — resource page structure
- `process-ingest.json` — template routing + resource step_7 conditional

### Next Day Focus
- [ ] Test parent_entity_identification in real ingest scenario
- [ ] Review 3 contradiction-flagged soft-check pages from previous session
- [ ] Consider Cluster A follow-up: merge context-budget.md wiki page with new rule

## Session 1 Summary (2026-07-09)
### Completed
1. ✅ Full health audit — 4 wrong docs-*.md deleted from templates/, all broken wikilinks fixed
2. ✅ Fixed `wiki-walk.py` backlinks parser: now extracts both `[text](url)` and `[[wikilink]]` Obsidian format
3. ✅ Fixed `orphan-pages.sh` key normalization to match backlink target format (19→59→1→0 orphans)
4. ✅ Populated empty Documentation section in index.md (14 doc pages added)
5. ✅ Full wiki rebuild — all tags/aliases/categories refreshed from source files
6. ✅ Tag ordering compliance: primary entity name moved to tag[0] for all 12 entity profiles

### Key Changes
- `scripts/wiki-walk.py` — Obsidian wikilink parser + correct wiki path cleanup (no more `wiki-docs-` prefix)
- `scripts/orphan-pages.sh` — proper key matching with backlinks.json format
- `wiki/entities/*.md` — 12 entity pages: primary name now tag[0] per rule `tag_ordering_for_entity_docs`
- `wiki/index.md` — fully rebuilt, all categories populated correctly (templates excluded)

## System State
### Active Threads
- ✅ Context budget compactified, pre-commit flow unified, resource routing added
- 🔄 Knowledge expansion — ready for next ingest/query cycle
