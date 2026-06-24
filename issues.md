# Issues — Лint-аудит wiki (2026-06-24)

Создано: 2026-06-24 | Source: full lint pass across all wiki pages

---

## 📊 Summary Table

| Check | Result | Severity |
|-------|--------|----------|
| Frontmatter (required fields) | ✅ All 8 content pages have tags, date, sources | PASS |
| Orphan pages (zero backlinks) | ✅ All pages have ≥2 backlinks | PASS |
| Duplicate titles within category | ✅ No duplicates found | PASS |
| Missing frontmatter sections | ❌ Structure mismatch: some concepts/syntheses missing template sections | Medium |
| Date consistency | ⚠️ Split between 2025-06-24 and 2026-06-24 | Low-Medium |
| Backlinks registry freshness | ✅ meta/backlinks.json updated (1 page) | PASS |
| Registry sources accuracy | ❌ Some null/empty entries in meta/registry.json | Medium |
| Index links resolution | ✅ All 8 wiki-relative links resolve correctly | PASS |
| Body text wiki-links | ✅ No broken body-text links found | PASS |

---

## Issue 1: Structure mismatch — missing template sections

**Flow**: Lint Flow, check_id=5 (mechanical_linting) — page format compliance
**Status**: ⚠️ Detected — some pages deviate from templates

**Описание:** Согласно шаблону в AGENTS.md, страницы должны иметь определённые секции:
- **Entity Pages**: `## Ключевые характеристики`, `## Связи`, `## Источники` ✅ (all 3 entities have these)
- **Concept Pages**: `## Определение`, `## Принципы работы`, `## Контекст и применение`, `## Примеры`
  - `llm-wiki-pattern.md`: def✅ principles✅ context✅ examples❌
  - `python-nixos-development.md`: def✅ principles✅ context✅ examples❌
  - `ai-factory-vs-pi.md`: def✅ principles❌ context❌ — **category distinction, not traditional concept** (acceptable deviation)
- **Synthesis Pages**: `## Контекст`, `## Анализ`, `## Инсайты и выводы`
  - Both syntheses have: context✅ analysis✅ insights❌

---

## Issue 2: Date consistency split between 2025 and 2026

**Flow**: Lint Flow, check_id=6 (date_consistency_check)
**Status**: ⚠️ Detected — mixed dates across pages

**Описание:**
- **2025-06-24**: `entities/pi-coding-agent.md`, `concepts/python-nixos-development.md`, `syntheses/python-nixos-development-environments.md`
- **2026-06-24**: `entities/ai-factory.md`, `entities/andrej-karpathy.md`, `concepts/llm-wiki-pattern.md`, `concepts/ai-factory-vs-pi.md`, `syntheses/rag-vs-llm-wiki-pattern.md`

**Решение:** 2025-06-24 — дата первоначального создания (при инициализации wiki). 2026-06-24 — текущая. Страницы с датой 2025 не обновлялись после рефакторинга. Это нормальная историческая разность, но стоит либо:
1. Обновить дату до `2026-06-24` (если страницы актуальны)
2. Добавить секцию "## Обновлено 2026-06-24" к старым страницам

---

## Issue 3: meta/registry.json sources accuracy

**Flow**: Lint Flow, check_id=1 (contradictions) + registry validation
**Status**: ❌ Some entries have `sources: []` or `null` instead of proper arrays

**Описание:** После rebuild-meta.sh некоторые страницы имеют пустые или null источники в meta/registry.json. Это связано с тем, что regex-парсер не смог извлечь массивы sources из YAML frontmatter (особенно если format отличается от ожидаемого).

---

## 🛠 Action Items

1. [ ] Добавить `## Примеры` к concept pages (llm-wiki-pattern, python-nixos-development)
2. [ ] Добавить `## Инсайты и выводы` к syntheses (или убрать из requirements если не обязательны)
3. [ ] Решить проблему с датой: обновить 3 страницы до 2026 или добавить секцию "Обновлено"
4. [ ] Исправить meta/registry.json — sources должны быть массивами строк, не null

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

## 📈 Lint Health Score

- ✅ Frontmatter presence: **8/8** (100%)
- ✅ Backlinks per page: **≥2** (no orphans)
- ✅ Duplicate titles: **0 found**
- ⚠️ Date consistency: **3 pages with 2025, 5 with 2026** — split detected
- ❌ Structure compliance: needs manual verification against template
- ❌ Registry sources accuracy: some null/empty entries

