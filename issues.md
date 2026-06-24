# Issues — Полный аудит wiki (2026-06-24)

Создано: 2026-06-24 | Source: full lint pass + structure validation + link analysis

---

## 📊 Lint Health Score: **10/10** — Все проблемы исправлены ✅

| Проверка | Статус | Детали |
|----------|--------|--------|
| Frontmatter presence | ✅ PASS | 8/8 content pages have tags, date, sources |
| Orphan pages | ✅ PASS | All pages ≥2 backlinks |
| Duplicate titles | ✅ PASS | 0 duplicates in any category |
| Link convention violation | ✅ FIXED | Issue #1 — все `../`, `../../` → wiki-relative |
| Compounding principle | ✅ FIXED | Issue #2 — all pages have internal body-links |
| Date consistency | ✅ FIXED | Issue #3 — all dates updated to 2026-06-24 |
| Template compliance | ✅ FIXED | Issue #4 — examples/insights added to all missing sections |
| Registry sources accuracy | ✅ FIXED | Issue #5 — null entries repaired manually |
| Backlinks freshness | ✅ FIXED | Issue #6 — meta files rebuilt post-fixes |

---

## 📋 Resolved Issues Log

### Issue 1: Broken relative paths (`../`, `../../`) — ✅ FIXED
**Commit**: `3178794` | **Severity**: High
- Rewrote all non-wiki-relative links across 4 pages to wiki-root format
- Files fixed: entities/andrej-karpathy.md, concepts/llm-wiki-pattern.md, syntheses/* (2 files)

### Issue 2: Missing body-text internal links — ✅ FIXED
**Commit**: `ede2d60` | **Severity**: Medium
- Added wiki-relative links to ai-factory.md, pi-coding-agent.md, ai-factory-vs-pi.md
- All 8 content pages now have cross-references in body text

### Issue 3: Date consistency split — ✅ FIXED
**Commit**: `ba2ff56` | **Severity**: Low-Medium
- Updated dates on 3 old pages (entities/pi-coding-agent, concepts/python-nixos-development, syntheses/*environments) from 2025 to 2026

### Issue 4: Template section mismatches — ✅ FIXED
**Commit**: `ba2ff56` | **Severity**: Medium
- Added `## Примеры` to concept pages (llm-wiki-pattern, python-nixos-development)
- Added `## Инсайты и выводы` to synthesis pages (both)

### Issue 5: Registry null sources — ✅ FIXED
**Commit**: (manual repair, not tracked in git per .gitignore)
- Fixed concepts/ai-factory-vs-pi.md and syntheses/python-nixos-development-environments.md entries

### Issue 6: Stale backlinks registry — ✅ FIXED
**Post-commit action**: rebuild-meta.sh run after all link fixes applied
- Fresh meta/backlinks.json generated with accurate data

---

## 📈 Final Lint Health Score

- ✅ Frontmatter presence: **8/8** (100%)
- ✅ Backlinks per page: **≥2** (no orphans)  
- ✅ Duplicate titles: **0 found**
- ✅ Link conventions: **All wiki-relative, no `../` paths**
- ✅ Compounding principle: **All pages cross-reference each other**
- ✅ Date consistency: **All 2026-06-24** (or historically marked)
- ✅ Template compliance: **All required sections present**
- ✅ Meta integrity: **Registry sources accurate, backlinks fresh**

---

## 🔄 Future Maintenance

1. **Ingest Flow**: Always run steps 5-7 (log, index, meta_rebuild) in order
2. **Query Flow**: Follow priority search → synthesis → compounding → save-as-page
3. **Lint Flow**: Run periodic check for broken links, missing frontmatter, date inconsistencies
4. **Schema Evolution**: Update workflows based on usage patterns

---

*Created: 2026-06-24 | Status: All issues resolved ✅ | Last commit: ede2d60*
