# Issues — Wiki Audit Tracker (2026-06-24)

---

## 🚨 Live Issues (требуют решения)

### Issue #5 + #9 (merged): Orphan Pages + Auto-Crosslink Logic ⚠️ PARTIAL FIX
**Проблема**: Было 34 orphan pages — auto-crosslink не работал.

**Fix applied (2026-06-28)**:
1. ✅ `orphan-pages.sh` — исправлен regex pattern: теперь корректно ищет `[text](path/to/file.md)`
   - **Результат**: 37 → 5 orphan pages (только системные файлы)
2. ✅ `auto-crosslink.sh` — полностью переписан с multi-level scoring
   - Level 1: H1 title + keyword (+3), Level 2: shared sources (+5), Level 3: frontmatter related (+4)
   - Output: JSON [{path, score, match_types}] sorted by score desc
3. ✅ Ingest process integration — auto-crosslink вызывается автоматически в:
   - **step 3a** (create new page): `auto-crosslink.sh <new_page> --include-root`
   - **step 3b** (update existing): `auto-crosslink.sh <existing_page> --include-root`
   - **step 3d** (cross_link_update): parsed results, auto-add backlinks for score >= 5
4. ✅ Syntheses special handling — DR-4 в AGENTS.md, syntheses_rule в step 3a

**Remaining work**:
- [x] Обработать deep contradiction в python-nixos: концепция vs синтез дублируют один источник — **redundancy, не факт-конфликт**. Нужно merge или clear distinction
  - `concepts/python-nixos-development.md` (concept) и `syntheses/python-nixos-development-environments.md` (synthesis) содержат идентичный контент о Python на NixOS
  - **Решение**: Clear distinction — concept = методология, synthesis = анализ применения. Добавить [[wiki/syntheses/...]] в related: концепта.
- [ ] Для системных файлов (log.md, timeline.md) — отдельная логика: exclude from normal search

👉 **Canonical**: `scripts/orphan-pages.sh`, `scripts/auto-crosslink.sh`, `AGENTS.md#decision_rules`, `process-ingest.json`

### Issue #8: Syntheses Special Handling ⚠️ PARTIAL FIX
**Решение (2026-06-28)**:
1. ✅ DR-4 в AGENTS.md — syntheses treated as special category, only create with explicit fixation flag
2. ✅ syntheses_rule в process-ingest.json step 3a — never auto-create synthesis without novel inference
3. ✅ compounding_decision_logic в process-query.json — differentiate fact collection vs new logical inference

**Remaining**: Добавить rule в AGENTS.md → `syntheses not processed like regular wiki pages` (drafted, needs user approval)

### Issue #6: Lint `check-new-sources` Parse Bug (2025 from ID) 🐛 FIXED
**Проблема**: `grep -oE '[0-9]+' | head -1` ловил `2025` из `SRC-2025-06-24-001`. Реальное количество = 3, показывал 2025.

**Fix**: `lint.sh стр. 63` → `grep -c '^NEW:'` вместо парсинга чисел.

👉 **Canonical**: `scripts/lint.sh#check_new_sources_fix`

### Issue #7: Raw Sources — Depth Limit Required 🐛 FIXED
**Проблема**: Без ограничения глубины исследования источников агент может «вытянуть весь интернет». Нужен лимит на количество новых sources per check.

**Fix applied**:
- `check-new-sources.sh` → добавлен `--max N` флаг (default: 10)
- При превышении — предупреждение о remaining packages
- Lint использует `--max 10` по умолчанию

👉 **Canonical**: `scripts/check-new-sources.sh`, `scripts/lint.sh`

### Issue #8: syntheses/ Missing Special Handling Rule ⚠️ PARTIAL FIX
**Проблема**: `syntheses/` — не должен обрабатываться как обычные страницы wiki/. Это аналитические синтезы (deep analysis, new insights from 2+ sources), они требуют особого правила обработки.

**Partial fix applied**:
- ✅ `auto-crosslink.sh` теперь может отличать synthesis от entity/concept через scoring (shared_source + conceptual_match)
- 📝 В AGENTS.md#decision_rules: DR-1/DR-2 уже определяют приоритеты для authoritative sources

**Remaining**: Добавить правило в AGENTS.md → `syntheses treated as special category, not processed like regular wiki pages`

👉 *Action:* Update Schema (AGENTS.md) + process-ingest.json to exclude syntheses from normal processing rules.

### Issue #9: Auto-Crosslink Logic Broken at Multiple Levels ⚠️ Pending
**Проблема**: `auto-crosslink.sh` и `process-ingest.json#step_3d` работают только на **текстовом совпадении имени сущности**. Это не учитывает:
1. **Document formatting rules**: страницы должны явно указывать связи (related/mentions) в frontmatter и тексте
2. **Semantic relationships**: одна страница про hexagonal architecture, другая про service container — обе относятся к Symfony, но слово «Symfony» отсутствует → backlink не добавляется
3. **Shared-source clusters**: pages using same raw source have implicit connections that aren't captured

**Решение (multi-level)**:
- Level 1: Добавить требование `related:` в frontmatter + explicit mentions в тексте
- Level 2: Graph-based crosslinks из existing metadata, shared-source analysis
- Level 3: Score potential links (shared source = +5, related +3, mention +1)

👉 *Action:* Rewrite auto-crosslink.sh для graph-based подхода. Add document rules to process-ingest.json.

---

## ✅ Resolved (краткие summaries)

### Issues #1-3: External Sources + Novelty Threshold (2026-06-26)
| Issue | Решение | Ссылка |
|-------|---------|--------|
| Как часто обновлять wiki? | User-requested или cron (`check-new-sources.sh`) | `AGENTS.md#External_Sources_Update_Policy` |
| web_search приоритет? | Тот же источник → внешние данные приоритетны; разные источники → Issue #4 | `process-query.json` (external sources logic) |
| Novelty threshold | Факты → update existing. Новый вывод → flag for fixation. Контекст → notes | `AGENTS.md#novel_insight_criteria` |

### Issue #4: Authoritative Sources Criteria ✅ RESOLVED (2026-06-28)
**Решение**: DR-1/DR-2 из AGENTS.md#decision_rules определяют приоритеты:
- **DR-1**: Script reports raw overlap → no automatic weight change
- **DR-2**: If B contains additions/deletions (correction) + evidence → B > A on corrected claim
- **DR-3**: Attribution conflict → A wins original; B gets reporter credit only

👉 **Canonical**: `AGENTS.md#decision_rules` | Status: ✅ Implemented

### Contradiction Resolution Flow (2026-06-24)
**Исправлено**: Добавлены приоритеты (`authoritative > temporal > user_review`), новые типы конфликтов (`scope`, `contextual`, `version`), post-resolution verification, история изменений.

👉 **Canonical source**: `process-query.json#contradiction_resolution_flow`

### Cross-Role Architecture (2026-06-24)
**Исправлено**:
- Guardrails / Logging Templates / Date Convention → единые в AGENTS.md, наследуются процессами
- Contradiction Resolution Flow → query-specific (process-query.json), не schema-level
- Search Priority Details → process-query.json с критериями остановки (>=2 index, >=3 recall)
- Compounding → Principles в Schema, Scoring Logic в Query

👉 **Canonical**: `AGENTS.md#schema_inheritance` + `process-query.json#context`

### wiki-search.sh Bugs (2026-06-26)
**Исправлено**: Все 7 багов (regex escaping, head -1 → grep H1, COUNTER increment order, globstar fallback, Python env vars).

👉 **Canonical**: `scripts/wiki-search.sh` (rewrite committed)

### Search Error Handling (2026-06-26)
**Исправлено**:
- web_search timeout/API → error_handling + user notification (`post_search_flow[4]`)
- rebuild-meta >10s on large wiki (>100 pages) → skip full, --index-only only (`web_ingest_flow[4]`)
- Write permission denied / disk full → HALT_AND_REPORT (`web_ingest_flow[1]`)

👉 **Canonical**: `process-query.json` (post_search_flow + web_ingest_flow error_handling blocks)

---

---

## 📋 Analysis & Planning

### Wiki Scalability Analysis (2026-06-28)
**Проведён аудит архитектуры wiki с точки зрения масштабирования до 1000+ страниц.**

#### Найдено проблем:
| Проблема | Сейчас | Будущее |
|----------|--------|---------|
| Поиск | `wiki_recall` + grep — O(n) | Замедлится линейно |
| Index rebuild | Сканирует всю wiki/ | Минуты вместо секунд |
| Link validation | Полное сканирование | Тяжёлое при росте |

#### Рекомендованные оптимизации:
1. **Локальные индексы** — `index.md` в каждой категории (entities/, concepts/ и т.д.)
2. **Отдельный search index** — `meta/search-index.json` с ключевыми словами и preview
3. **Оптимизация скриптов** — ripgrep вместо grep, инкрементальный rebuild
4. **Улучшенная категоризация** — подкатегории для больших разделов

#### Процесс-файлы:
- `process-query.json` (881 строк, ~38KB) — можно сократить на 30-40%
- `process-ingest.json` (354 строки, ~12KB)
- `process-lint.json` (214 строк, ~9KB)

**Приоритеты**: локальные index.md + search-index.json → даст линейное ускорение при росте.

👉 *Action: Реализовать в отдельный спринт, не сегодня.*

---

*Last update: 2026-06-28 | Live: python-nixos deep contradiction only | Resolved: #1-4, #6-7 | #5/#9 auto-crosslink integrated into ingest process | DR-4 added*