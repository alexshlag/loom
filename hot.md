# Hot Cache — Активный Контекст

## Active Project

**Focus**: Lint.sh Check 14 integration + tag-audit fixes  
**Status**: Fixed trailing comma bug in lint.sh heredoc output → now valid JSON.

### Key Findings
- check-structural.sh correctly finds 40 violations across wiki pages
- lint.sh runs 14 checks, all passing structural validation
- Tag audit revealed 37 issues — fixed (≥3 domain tags per entity/concept)
- XR gaps: entities/symfony.md → concepts/service-container.md has no shared tags

### Next Steps
1. Add aliases to all entity/concept pages for discoverability
2. Investigate TAG-P6 (Cyrillic tags) across remaining concept pages
3. Consider adding semantic search / BM25 retrieval for better query routing

## Active Session Context

**Topic**: JSON parsing bug in lint.sh → structural_violator_paths trailing comma  
**Resolution**: Removed trailing comma after `${STRUCTURAL_VIOLATOR_JSON}` in heredoc template  
**Related files**: `scripts/lint.sh`, `scripts/check-structural.sh`, `/tmp/lint_structural.json`
