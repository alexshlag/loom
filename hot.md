# Hot Cache — Активный Контекст

## Active Project

**Focus**: Context Management System — Persistent vs Transient Rules  
**Status**: Implemented Phase 31 context management architecture

### Key Findings
- Created `rules/context-scopes.json` with scope definitions for all wiki rules
- Added `context_scope: transient` to process-ingest/query/lint.json files
- Updated AGENTS.md with Context Management section (Phase 31)

### What Was Fixed
1. **Persistent Rules**: Memory contract, execution contract, error handling — always remembered
2. **Transient Rules**: Process-specific steps — read only during process, forget after completion  
3. **Hybrid Rules**: Page templates, link conventions — remember but read from source when needed

## Active Session Context

**Topic**: Context bloat reduction via persistent/transient rule separation  
**Resolution**: Created rules/context-scopes.json and added context_scope metadata to process files  
**Result**: Agent now knows which rules to keep in memory vs which to forget after process completes

## Next Steps
1. Test context management system — verify agent behavior with persistent/transient rules
2. Add aliases to entity/concept pages for discoverability
3. Investigate broken crosslink paths in related: field (~68 invalid references)
