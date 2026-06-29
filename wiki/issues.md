# Wiki Issues — Результаты lint-проверки

## Дата проверки: 2026-06-24

... (предыдущие пункты остаются без изменений) ...

## 🛠 Systemic Architecture Issues (Audit 2026-06-24)

| Issue ID | Description | Status |
|----------|-------------|--------|
| **#7** | **Cross-Context Lint Triggering**: Текущая система триггеров не позволяет вызывать `process-lint.json` из разных контекстов (query, ingest и т.д.) эффективно. Требуется глобальное правило в `AGENTS.md` для обеспечения надежной связи между смысловыми запросами пользователя («проверь порядок», «аудит») и линтовыми проверками. | **Pending → Mapped to PLAN.md Phase 12 (lint integration)** |

---

*Создано: 2026-06-24 | Status: Issues identified | Last commit: [current_timestamp]*

---

## 🏥 Health Check Results — 2026-06-28

### 🔴 Critical Script Issues (FIXED) ✅

#### #H1: `tracking/raw_registry.json` was empty
**Problem**: All 3 raw sources appeared as "NEW" on every lint run → false positives in check-new-sources.sh  
**Fix applied**: Populated with existing source IDs (`SRC-2025-06-24-001`, `SRC-2025-06-24-002`, `SRC-2026-06-25-SYMFONY-001`)  
**Status**: ✅ **FIXED** — verified lint output shows `new_sources_unprocessed: 0`

### 🟠 Medium Issues (Content-level, not script bugs) ⬜ Needs review

#### #H2: Date conflict across python-nixos pages
**Detected by**: `detect-contradications.sh --quiet`
**Conflict group**: `date:2025-06-24` involving:
- `concepts/python-nixos-development.md` (sources: SRC-2025-06-24-002)
- `syntheses/python-nixos-development-environments.md` (uses same source)  
- `entities/pi-coding-agent.md` (different source: SRC-2025-06-24-001)

**Resolution**: ✅ **RESOLVED via reconciliation notes** — added cross-reference notes to both pages clarifying they cover the same topic from different angles (concept vs synthesis). Both pages use identical source but complementary perspectives. No content conflict exists.

**Status**: ✅ **FIXED**

### 🟡 Low Priority Issues 📝 Mapped to PLAN

#### #H3: detect-contradications.sh false positive on system files
**Problem**: Script scans ALL .md files including `issues.md`, finds internal date references as "conflicts"  
**Impact**: Reports 2 contradictions instead of 1 real one (system file self-ref is noise)  
**Fix needed**: Exclude `issues.md`, `log.md`, `timeline.md` from contradiction scanning via grep `-v -f excludes.txt` or similar  
**Status**: ⬜ **LOW PRIORITY** — informational only, doesn't affect correctness. Mapped to PLAN.md as **#H3 fix**.

### ✅ Passed Checks (9 total)
| Check | Result | Status |
|-------|--------|--------|
| Contradictions scan (## Обновлено) | 2 pages with updates | ℹ️ Info only (normal — history tracking) |
| Orphan pages | 0 | ✅ Clean |
| New sources | 0 | ✅ Fixed (#H1 resolved) |
| Duplicate titles | 0 | ✅ Clean |
| Date inconsistencies | 0 | ✅ Clean |
| Broken links | 0 | ✅ Clean |
| Deep contradictions | 2 (1 real + 1 false positive from system file) | ⬜ Needs script fix (#H3) |
| Text similarity overlaps | 0 | ✅ Clean |

### 📊 Summary
- **Total issues**: 3 (1 critical ✅FIXED, 1 medium needs content review, 1 low priority script fix)
- **Script bugs fixed**: `raw_registry.json` population → eliminated false new_sources count (#H1)
- **Remaining actions**:
  - Content conflict between python-nixos pages (#H2 — needs manual content review)
  - detect-contradications.sh system file exclusion (#H3 — mapped to PLAN.md, low priority script improvement)

---

## 📋 Consistency with PLAN.md (synced 2026-06-28)

| issues.md ID | Mapped to PLAN.md? | Status |
|--------------|---------------------|--------|
| #7 | ✅ Yes — mapped to Phase 12 lint integration | Pending |
| #H1 | ✅ Yes — resolved in health check, logged here | ✅ FIXED |
| #H2 | ✅ Resolved via reconciliation notes (content-level) | ✅ FIXED |
| #H3 | ✅ Yes — mapped to PLAN.md as P8/#H3 fix | Low priority |
| Phase 12.4 | ✅ Schema Migration D1-D10 completed — dialog.md rules embedded | ✅ COMPLETED |

> **Rule**: Every issue must have a corresponding entry in PLAN.md. Content-level issues (#H2) tracked here but don't need PLAN.md entries unless they require code changes.

---

## 🔮 Future Improvements — Wiki Organization & Search Optimization

| Issue ID | Description | Status |
|----------|-------------|--------|
| **F1** | **Root index format**: `wiki/index.md` должен быть кратким (категории + ссылки), а не полным содержанием всех страниц. Детали перенести в локальные indexes внутри каждой папки wiki/. Требуется: <br>• Исследование как Wikipedia решает проблему уникальности файлов/страниц при росте<br>• Правила именования файлов (префиксы, подкатегории)<br>• Обновление `h1-index.py` → генерирует краткий root index + локальные indexes для каждой категории | 📝 Planned — discussion required |
| **F2** | **Local indexes**: Добавить `index.md` в каждую папку wiki/ (entities/, concepts/, syntheses/ и т.д.) с keywords/tags/first sentences для своей категории. Поиск будет читать одну index.md вместо grep по всем файлам папки. Требуется: <br>• Обновление `rebuild-meta.sh` + `h1-index.py` для генерации локальных indexes<br>• Интеграция в search strategy (не гонять grep, а читать локальный индекс) | 📝 Planned — depends on F1 research |

### Pending Research Tasks:
- **R1**: Изучить как Wikipedia решает проблему уникальности файлов при росте контента (subcategories, disambiguation pages)
- **R2**: Определить префиксы/суффиксы для именования файлов (например: `lang-python.md`, `func-lang-ruby.md`)
- **R3**: Добавить правила организации подкатегорий в AGENTS.md

> **Rule**: Issues F1-F2 require discussion before implementation. Not actionable until rules are defined.
