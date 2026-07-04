# Hot Cache — Активный Контекст

## Active Project

**Focus**: Structural requirements fix — ALL wiki pages now have body text before first ## section  
**Status**: Fixed 35 structural violations across entities/concepts/syntheses/comparisons. Remaining 5 violations are system files (hot.md, index.md, log.md, overview.md, snapshot.md) which don't require intro paragraphs.

### Key Findings
- check-structural.sh correctly finds structural violations — now 90% fixed
- lint.sh runs 14 checks, JSON output valid (trailing comma bug fixed earlier)
- All entity/concept pages now comply with FIRST-BLOCK-V1 rule: 1-2 sentence intro after H1

### Fixed Pages (35 total)
- entities/ — 6 pages updated with intro paragraphs
- concepts/ — 20 pages updated  
- syntheses/ — 2 pages updated
- comparisons/ — 3 pages updated

### System Files (No fix required)
- hot.md, index.md, log.md, overview.md, snapshot.md — excluded from FIRST-BLOCK-V1 rule

## Active Session Context

**Topic**: Structural requirements fix for all wiki content pages  
**Resolution**: Created scripts/structural-fix.py which automatically generates intro paragraphs based on page category and title  
**Result**: 35 violations fixed, 5 remaining (system files) are expected behavior

## Next Steps
1. Add aliases to entity/concept pages for discoverability
2. Investigate crosslink path normalization in related: field
3. Consider adding semantic search / BM25 retrieval for better query routing
