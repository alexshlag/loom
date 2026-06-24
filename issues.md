# Issues — Полный аудит wiki (2026-06-24)

Создано: 2026-06-24 | Source: full lint pass + structure validation + link analysis

---

## 📊 Summary Table

| # | Issue | Category | Severity | Status |
|---|-------|----------|----------|--------|
| 1 | Broken relative paths in body text (`../`, `../../`) | Link convention violation | High | ❌ Open |
| 2 | Missing internal wiki-links in body text | Compounding principle violation | Medium | ❌ Open |
| 3 | Date consistency split (2025 vs 2026) | Frontmatter consistency | Low-Medium | ❌ Open |
| 4 | Template section mismatches | Page format compliance | Medium | ❌ Open |
| 5 | meta/registry.json sources accuracy | Meta file integrity | Medium | ❌ Open |
| 6 | Backlinks registry incomplete | Meta file freshness | High | ❌ Open |

---

## Issue 1: Broken relative paths in body text (`../`, `../../`)

**Flow**: Lint Flow, check_id=7 (link_validation_with_auto_fix) — link convention violation
**Status**: ❌ **Открыто** — 4 страницы с не-вики-относительными путями

**Описание:** AGENTS.md §Link Conventions запрещает `./paths`, `../relative_paths`. Найденные нарушения:

| File | Line | Violation | Fix |
|------|------|-----------|-----|
| `entities/andrej-karpathy.md` | 22 | `[Synthesis: ...](../syntheses/python-nixos-development-environments.md)` | → `[...](syntheses/python-nixos-development-environments.md)` |
| `concepts/llm-wiki-pattern.md` | 55 | `[Synthesis: RAG vs LLM](../../syntheses/rag-vs-llm-wiki-pattern.md)` | → `[...](syntheses/rag-vs-llm-wiki-pattern.md)` |
| `syntheses/python-nixos-development-environments.md` | 70 | `[Python Development Env](../../concepts/python-nixos-development.md)` | → `[...](concepts/python-nixos-development.md)` |
| `syntheses/rag-vs-llm-wiki-pattern.md` | 38 | `[LLM Wiki Pattern Concept](../../concepts/llm-wiki-pattern.md)` | → `[...](concepts/llm-wiki-pattern.md)` |

**Fix:** Rewrite all links to wiki-relative format from `wiki_root`.

---

## Issue 2: Missing internal wiki-links in body text (compounding principle violation)

**Flow**: Compounding Workflow — pages should cross-reference each other
**Status**: ❌ **Открыто** — 5 из 8 страниц не имеют внутренних ссылок в теле текста

| Page | Has body links? | Expected related pages (from frontmatter `related:` + concept map) |
|------|-----------------|---------------------------------------------------------------------|
| `entities/ai-factory.md` | ❌ NO | `concepts/ai-factory-vs-pi.md`, `entities/pi-coding-agent.md` |
| `entities/pi-coding-agent.md` | ❌ NO | `concepts/ai-factory-vs-pi.md`, `entities/andrej-karpathy.md` |
| `concepts/ai-factory-vs-pi.md` | ❌ NO | Links to both entity pages (already have them in diagram) |
| `concepts/python-nixos-development.md` | ❌ NO | `syntheses/python-nixos-development-environments.md`, `entities/pi-coding-agent.md` |
| `syntheses/*` (both) | ⚠️ Partial | Have some links but not all expected cross-references |

**Описание:** Pages имеют frontmatter `related:` поля, но в теле текста нет ссылок. Это нарушает принцип compounding knowledge base — wiki не образует граф знаний, а только список изолированных страниц.

**Fix:** Add internal wiki-relative links to body text of each page pointing to related entities/concepts/syntheses.

---

## Issue 3: Date consistency split between 2025 and 2026

**Flow**: Lint Flow, check_id=6 (date_consistency_check)
**Status**: ❌ **Открыто** — 3 страницы с устаревшей датой

| Page | Current date | Issue | Fix suggestion |
|------|-------------|-------|----------------|
| `entities/pi-coding-agent.md` | 2025-06-24 | Не обновлялась после рефакторинга | Обновить до 2026-06-24 |
| `concepts/python-nixos-development.md` | 2025-06-24 | Та же проблема | Обновить до 2026-06-24 |
| `syntheses/python-nixos-development-environments.md` | 2025-06-24 | Та же проблема | Обновить до 2026-06-24 |

**Решение:** Если страницы актуальны — проставить текущую дату. Если они исторически зафиксированы на конкретной дате — добавить секцию `## Обновлено [date]`.

---

## Issue 4: Template section mismatches

**Flow**: Lint Flow, check_id=5 (mechanical_linting) — page format compliance
**Status**: ❌ **Открыто** — некоторые страницы не соответствуют шаблонам из AGENTS.md

### Entity Pages ✅ (все OK)
Все entity-страницы имеют: `## Ключевые характеристики`, `## Связи`, `## Источники`.

### Concept Pages ⚠️ (частично OK)
| Page | Определение | Принципы работы | Контекст | Примеры |
|------|------------|-----------------|----------|---------|
| `llm-wiki-pattern.md` | ✅ | ✅ | ✅ | ❌ |
| `python-nixos-development.md` | ✅ | ✅ | ✅ | ❌ |
| `ai-factory-vs-pi.md` | ✅ | ❌ (category distinction, не traditional concept) | ❌ | N/A |

### Synthesis Pages ⚠️ (частично OK)
| Page | Контекст | Анализ | Инсайты и выводы |
|------|---------|--------|-----------------|
| `python-nixos-development-environments.md` | ✅ | ✅ | ❌ |
| `rag-vs-llm-wiki-pattern.md` | ✅ | ✅ | ❌ |

**Fix:** Добавить недостающие секции к concept и synthesis страницам.

---

## Issue 5: meta/registry.json sources accuracy — null/empty entries

**Flow**: Lint Flow, registry validation
**Status**: ❌ **Открыто** — некоторые страницы имеют `sources: []` или `null` в meta-файле

**Описание:** Скрипт `rebuild-meta.sh` использует regex-парсер для извлечения YAML frontmatter. Страницы с нестандартным форматом источников (например, массивами wiki-relative путей) получают `null` вместо массива строк.

**Примеры affected pages:**
- `concepts/ai-factory-vs-pi.md`: sources → `[wiki/entities/ai-factory.md, wiki/entities/pi-coding-agent.md]` (registry shows `null`)
- `syntheses/python-nixos-development-environments.md`: sources → array with both wiki and raw paths (registry shows `null`)

**Fix:** Обновить парсер rebuild-meta.sh или вручную исправить registry.json для affected entries.

---

## Issue 6: Backlinks registry incomplete / stale

**Flow**: Lint Flow, check_id=7 (link_validation_with_auto_fix) — backlinks accuracy
**Status**: ❌ **Открыто** — registry не учитывает все фактические ссылки из body text

### Найденные пропуски в meta/backlinks.json:

| Page | Expected backlinks (from index + body text) | Registry entries | Missing |
|------|---------------------------------------------|------------------|---------|
| `entities/ai-factory.md` | index.md, concept page reference to it | 1 entry (index only) | Concept's link not counted |
| `concepts/ai-factory-vs-pi.md` | index.md, references from ai-factory entity | 1 entry (index only) | Entity page links missing |

**Fix:** Перезапустить rebuild-meta.sh с исправленным парсером или вручную добавить недостающие entries.

---

## 🛠 Action Items — Приоритетный порядок исправления

### 🔴 High priority (link convention violations, compounding principle)
1. **Issue 1**: Rewrite `../` and `../../` links to wiki-relative format в 4 страницах
2. **Issue 6**: Update meta/backlinks.json to include all body-text references

### 🟡 Medium priority (structure, completeness)
3. **Issue 5**: Fix registry sources accuracy — manual repair or parser update
4. **Issue 2**: Add internal wiki-links to body text of orphan pages (5 pages)
5. **Issue 4**: Add missing template sections (examples, insights) to concept/synthesis pages

### 🟢 Low priority (cosmetic consistency)
6. **Issue 3**: Update dates on 3 old pages or add "Обновлено" sections

---

## 📋 Historical Issues (Fixed in Previous Commits)

| Issue | Status | Notes |
|-------|--------|-------|
| log_registration missed | ✅ Fixed | Added to wiki/log.md |
| index_update missed | ✅ Fixed | AI Factory added to Сущности/Ресурсы |
| meta_rebuild not executed | ✅ Fixed | Run post-hoc, registry updated |
| Fetch truncation rule | ✅ Added | AGENTS.md v3 §Fetch Content Truncation Handling |
| Discussion_with_user surface | ⚠️ Partially done | Concept page created but user didn't choose additional pages |

---

## 📈 Lint Health Score (Before Fixes)

- ✅ Frontmatter presence: **8/8** (100%)
- ✅ No broken links to non-existent targets
- ❌ Link convention violations: 4 instances of `../` paths
- ⚠️ Compounding principle: 5 pages missing internal body-links
- ⚠️ Date consistency: split 2025/2026 across 8 pages
- ❌ Template compliance: concept/synthesis pages incomplete
- ❌ Meta integrity: registry.json has null sources, stale backlinks

---

## 🔄 Execution Plan

1. **Issue 1 fix** → sed -i to rewrite all `../` and `../../` links in body text
2. **Issue 6 fix** → run rebuild-meta.sh after Issue 1 is fixed (fresh scan)
3. **Issue 5 fix** → manual repair of registry.json affected entries OR update parser
4. **Issue 2 fix** → add wiki-relative links to body text of 5 orphan pages
5. **Issue 4 fix** → append missing sections to concept/synthesis pages
6. **Issue 3 fix** → batch-update dates on 3 old pages

---

*Created: 2026-06-24 | Last updated: pending fixes execution*
