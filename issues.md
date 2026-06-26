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