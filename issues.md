# Issues — Wiki Audit Tracker

---

## 🚨 Live Issues (требуют решения)

### Issue #5/#9: Orphan Pages + Auto-Crosslink Logic ⚠️ PARTIAL FIX
**Проблема**: `auto-crosslink.sh` работает только на текстовом совпадении имени, не учитывает semantic relationships и shared-source clusters.

**Fix applied (2026-06-28)**:
1. ✅ `orphan-pages.sh` fixed — 37 → 5 orphan pages (только системные)
2. ✅ `auto-crosslink.sh` rewritten с multi-level scoring (H1 + shared sources + frontmatter)
3. ✅ Integrated into ingest process: step_3a, step_3b, step_3d

**Remaining**:
- [ ] Merge/clarify `concepts/python-nixos-development.md` vs `syntheses/python-nixos-development-environments.md` — redundant content
- [ ] Exclude system files (log.md, timeline.md) from normal search logic

👉 **Canonical**: `scripts/orphan-pages.sh`, `scripts/auto-crosslink.sh`, `AGENTS.md#decision_rules`, `process-ingest.json`

### Issue #10: Error Logging — Unified Format 🔽 LOW PRIORITY
**Проблема**: Нет единого формата логирования ошибок между скриптами.
- Каждый скрипт пишет в свой stderr / отдельный log file
- Нет `log_error()` функции с timestamp + level + message
- Python скрипты используют `print` вместо `logging`

**Статус:** ⬜ Deferred — не блокирует работу, но улучшает maintainability

### Issue #11: Trap Handlers для Cleanup 🔽 LOW PRIORITY  
**Проблема**: Ни один скрипт не использует `trap EXIT/cleanup`.
- При аварийном выходе временные файлы остаются
- Нет rollback при ошибке записи JSON в meta/

**Статус:** ⬜ Deferred — nice-to-have для production readiness

### Issue #12: Unit Tests для Скриптов 🔽 LOW PRIORITY
**Проблема**: Ни один скрипт не покрыт unit/integration тестами.
- `scripts/test-*.sh` и `test_*.py` отсутствуют
- Без тестов невозможно regression-proof при будущих изменениях

**Статус:** ⬜ Deferred — backlog, приоритет ниже безопасности

### Issue #13: scripts/README.md 🔽 LOW PRIORITY
**Проблема**: Нет единой документации по скриптам.
- Usage examples, architecture overview, known limitations отсутствуют
- Сложно новичку понять, как работают 15+ скриптов

**Статус:** ⬜ Deferred — nice-to-have для onboarding

---

### Issue #8: Syntheses Special Handling ⚠️ PARTIAL FIX
**Проблема**: `syntheses/` — аналитические синтезы, не должны обрабатываться как обычные страницы wiki.

**Fix applied (2026-06-28)**:
1. ✅ DR-4 в AGENTS.md — syntheses treated as special category
2. ✅ syntheses_rule в process-ingest.json step 3a — no auto-create without novel inference
3. ✅ compounding_decision_logic differentiate fact collection vs new logical inference

**Remaining**: Добавить rule в AGENTS.md → `syntheses not processed like regular wiki pages` (drafted, needs user approval)

---

## ✅ Resolved

### Issues #1-3: External Sources + Novelty Threshold
| Issue | Решение |
|-------|---------|
| Как часто обновлять? | User-requested или cron (`check-new-sources.sh`) |
| web_search приоритет? | Тот же источник → внешние данные; разные → AGENTS.md#decision_rules |
| Novelty threshold | Факты → update existing. Новый вывод → flag for fixation. |

### Issue #4: Authoritative Sources Criteria ✅ RESOLVED
**Решение**: DR-1/DR-2 из AGENTS.md — overlap neutral, correction evidence wins, attribution handled.

### Issues #6-7: Lint Parse Bug + Depth Limit ✅ RESOLVED
| Fix | Details |
|-----|---------|
| `check-new-sources` parse bug | `grep -c '^NEW:'` вместо парсинга дат из ID |
| Raw sources depth limit | `--max N` flag (default: 10) in `lint.sh` |

### Other Resolved ✅
- Contradiction Resolution Flow → cascade-based (code > live > docs), scope/contextual/version types added
- Cross-Role Architecture → guardrails/logging/date inherited from AGENTS.md, query-specific flows in process files
- wiki-search.sh Bugs → all 7 fixed (regex, grep H1, globstar, etc.)
- Search Error Handling → timeout/API error handling, rebuild skip >100 pages, disk permission checks

---

*Last update: 2026-06-28 | Live: python-nixos redundancy + syntheses rule. Resolved: #1-4, #6-7, architecture fixes.*
