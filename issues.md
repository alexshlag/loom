# Issues — Wiki Audit Tracker (2026-06-24)

---

## 🚨 Live Issues (требуют решения)

### Issue #4: Authoritative Sources Criteria ⚠️ Pending User Decision

**Проблема**: `official docs > community wiki > personal notes` — но нет механизма автоматического определения authoritative source.

**Критерии на обсуждение**:
1. **По домену**: `github.com/<org>/<repo>@<version>`, официальные сайты, wikipedia.org
2. **По метаданным**: frontmatter.source_type = "official" или автор = известный эксперт/компания
3. **Комбинированный**: домен + авторство + badge

👉 *Предложи критерии — обновлю инструкцию.*

---

## 🚨 Live Issues (требуют решения)

### Issue #5: Orphan Pages + Auto-Crosslink Logic Broken ⚠️ Pending
**Проблема**: 34 orphan pages — auto-crosslink не работает. Скрипт/агент должен автоматически добавлять backlinks при ingest/query.

**Решение**: 
1. `auto-crosslink.sh` → должен находить связанные entity/concept и добавлять ссылки
2. Для системных файлов (log.md, timeline.md) — отдельная логика: они не part of normal search
3. **Deep contradiction** в python-nixos: концепция vs синтез дублируют один источник. Это redundancy, не факт-конфликт. Нужен merge или clear distinction.

👉 *Action:* Добавить auto-crosslink logic в ingest process.

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

### Issue #8: syntheses/ Missing Special Handling Rule ⚠️ Pending
**Проблема**: `syntheses/` — не должен обрабатываться как обычные страницы wiki/. Это аналитические синтезы (deep analysis, new insights from 2+ sources), они требуют особого правила обработки:
- Не дублировать с concepts/ при shared source
- Синтезы создаются только если есть **новый логический вывод** (не просто сбор фактов)
- Auto-crosslink logic должна отличать synthesis от entity/concept при построении backlinks

**Решение**: Добавить правило в AGENTS.md → `syntheses` treated as special category, not processed like regular wiki pages.

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

*Last update: 2026-06-26 | Live issues: #4 only | All resolved items linked to canonical sources above.*