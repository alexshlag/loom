# Issues — Wiki Audit Tracker

---

## 🚨 Live Issues (требуют решения)

### Issue #39: Context Bloat & Architecture Optimization (HIGH) 🆕
**Проблема**: `AGENTS.md` содержит слишком много технических деталей (правила Git, политики языков, архитектура памяти), что ведет к раздуванию контекста и снижению эффективности агента.
**Решение**: Вынести технические спецификации в отдельную директорию `rules/` (например, `rules/protected_zones.json`, `rules/git_conventions.json` и т.д.). `AGENTS.md` должен остаться высокоуровневым манифестом с ссылками на эти файлы.
**Статус:** ⬜ Open — требует создания директории и миграции блоков.
**Связано**: Архитектурное решение по разделению "Манифеста" и "Справочников".

**Severity**: **CRITICAL** — тестовое покрытие отсутствует.

### Issue #5/#9: Orphan Pages + Auto-Crosslink Logic ⚠️ PARTIAL FIX
**Проблема**: `auto-crosslink.sh` работает только на текстовом совпадении имени, не учитывает semantic relationships и shared-source clusters.

**Fix applied (2026-06-28)**: ✅ `orphan-pages.sh` fixed — 37 → 5 orphan pages; auto-crosslink rewritten с multi-level scoring; integrated into ingest process.

**Remaining**:
- [ ] Merge/clarify `concepts/python-nixos-development.md` vs `syntheses/python-nixos-development-environments.md` — redundant content
- [x] Exclude system files (log.md, timeline.md) from normal search logic ✅ done

👉 **Canonical**: `scripts/orphan-pages.sh`, `scripts/auto-crosslink.sh`, `decision-rules.md`, `process-ingest.json`

### Issue #11: Trap Handlers для Cleanup 🔽 PARTIALLY DONE
**Проблема**: Часть скриптов не использует `trap EXIT/cleanup`. При аварийном выходе временные файлы остаются.

**Статус:** ✅ Частично — `wiki-search.sh`, `link-validator.sh`, `auto-crosslink.sh` используют `mktemp + trap`. ⬜ Осталось: `rebuild-meta.sh`, `check-new-sources.sh`, `text-similarity.sh`, `lint.sh`.

### Issue #12: Unit Tests для Скриптов ⚠️ BROKEN
**Проблема**: Единственный тест `tests/text-similarity.bats` — broken (typo в `$BATS_TEST_DIRTEXT`). Остальные скрипты не покрыты.

**Severity:** 🔴 **Broken** — требуется починить существующий тест и добавить новые.

### Issue #18: Hardcoded /tmp/ Overlap File (HIGH) ⚠️ PARTIAL FIX
**Проблема**: Race condition между параллельными инстансами при использовании `/tmp/`. Нет cleanup при краше. Нарушение RULES.md (use mktemp, not /tmp/).

**Fix applied:** ✅ `process-ingest.json` updated: `mktemp` instead of hardcoded `/tmp/overlap_result.json`.

**Remaining**:
- [ ] Добавить trap cleanup для $TMP_OVERLAP в agent workflow (или скрипт сам cleanups)
- [ ] Проверить другие места где используется /tmp/ в скриптах

### Issue #27: Broken Link Handling — Agent Escalation Rules 🆕 IN PROGRESS
**Проблема**: `link-validator.sh --full` обнаруживает broken links, но agent escalation rules отсутствуют.

**Fix applied:** ✅ DR-EX1 added to AGENTS.md (external link standard); step 0.75 in process-query.json (lightweight awareness via working_memory); raw_source_link_repair в step_1; updated post-operation validation (only new files check).

**Remaining**:
- [ ] Agent decision thresholds: autonomously fix case/path mismatches; escalate fuzzy < 50 or ambiguous intent
- [ ] Document escalation rules in process-query.json → broken_link_awareness

👉 **Schema ref**: `process-query.json#broken_link_awareness`, `process-ingest.json#raw_source_link_repair`

### Issue #28: Page Templates Co-evolution — INCOMPLETE 🆕
**Проблема**: AGENTS.md содержит секции Template Editing Policy и Template Co-evolution Process, но фактическая работа над шаблонами страниц (user-approved structural improvements) не завершена.

**Статус:** ⬜ Open — требуется discussion + user approval для推进
**Schema ref**: `AGENTS.md#template_co_evolution`, `process-ingest.json` (логирование в log.md)

### Issue #22: DEBUG Prints in Production Code (MEDIUM) 🆕
**Проблема**: `scripts/performance/similarity_index.py:196-198,272` — `# DEBUG: ...` print statements оставлены в production.

**Fix**: Удалить или обернуть в `if __debug__`.

### Issue #23: Redundant Wiki Walks (MEDIUM) 🆕
**Проблема**: После каждого ingest запускаются `rebuild-meta.sh` + `link-validator.sh` + `auto-crosslink.sh` — 3 независимых полных walk'а по wiki. Для 1000+ страниц latency станет проблемой.

**Fix**: Объединить в единый скрипт или передавать results между Script'ами (unified-pass architecture Phase 23).

### Issue #24: Manual JSON Construction (MEDIUM) 🆕
**Проблема**: `lint.sh:127-145` и `link-validator.sh:63-64` генерируют JSON вручную через `echo`/`printf` + `sed` escaping. Если данные содержат `"`, `\n`, или unicode — JSON будет сломан.

**Fix**: Использовать `jq` или Python для всех JSON output.

### Issue #25: `check_id` Numbering Inconsistency (LOW) 🆕
**Проблема**: `lint.sh` комментарии пишут `Check 4/9` для check_id=3, `Check 5/9` для check_id=5. Нумерация не совпадает с AGENTS.md и process-lint.json.

### Issue #33: AGENTS.md Optimization ✅ RESOLVED (2026-07-02)
**Цель**: Уменьшение объема контекста и упрощение структуры манифеста.
**Действия**:
- Удаление дубликатов блоков Schema Reference и Schema Inheritance.
- Удаление технически детализированного блока Non-blocking Lint (перенос в документацию скриптов).
- Очистка структуры для улучшения фокусировки LLM на правилах поведения.
**Результат**: Сокращение объема AGENTS.md, повышение читаемости и эффективности обработки инструкций.

### Issue #8: Syntheses Special Handling ⚠️ PARTIAL FIX
**Проблема**: `syntheses/` — аналитические синтезы, не должны обрабатываться как обычные страницы wiki.

**Fix applied:** ✅ DR-4 в AGENTS.md; syntheses_rule в process-ingest.json step 3a; compounding_decision_logic differentiate fact collection vs new logical inference.

**Remaining**: Добавить rule в AGENTS.md → `syntheses not processed like regular wiki pages`.

### Issue #31: Media Files Pipeline Missing 🆕
**Проблема**: В Loomana нет специфицированного pipeline для media files (OCR, metadata extraction).

**Решение:** ✅ DECISION MADE — `wiki/assets/images/[slug].[ext]` + `wiki/assets/descriptions/[slug].md` + optional `.media-manifest.json`.

**Remaining**:
- [ ] Скрипт `scripts/media-ingest.sh` — автоматизация OCR + metadata extraction
- [ ] Интеграция в ingest flow — trigger point (agent вызывает media pipeline при получении изображения)

👉 **Severity:** LOW — nice-to-have, не блокирует работу.

### Issue #13: scripts/README.md 🔽 LOW PRIORITY
**Проблема**: Нет единой документации по скриптам (usage examples, architecture overview, known limitations). Сложно новичку понять, как работают 15+ скриптов.

👉 **Статус:** ⬜ Deferred — nice-to-have для onboarding.

---


## ✅ Resolved Today/Recently

### Issues #1-3: External Sources + Novelty Threshold ✅ RESOLVED
**Решение:** User-requested или cron; тот же источник → внешние данные приоритетны; facts→update existing, new inference→flag for fixation.

### Issue #4: Authoritative Sources Criteria ✅ RESOLVED
**Решение:** DR-1/DR-2 из AGENTS.md — overlap neutral, correction evidence wins, attribution handled.

### Issues #6-7: Lint Parse Bug + Depth Limit ✅ RESOLVED
**Fixes:** `check-new-sources` parse bug fixed (`grep -c '^NEW:'`); raw sources depth limit with `--max N`.

### Issue #10: Error Logging — Unified Format ✅ FIXED
**Fix:** Created `scripts/utilities/common.sh` — unified `log_error()`, `safe_run()`; lint.sh uses safe_run for all script calls.

### Issue #17: Silent Error Swallowing ✅ FIXED (2026-06-30)
**Fixes:** `set -uo pipefail`; `log_error()` function; duplicate code removed; nomenclature fixed; utilities/common.sh created.

### Issue #19: Link Validator 500-File Limit ✅ FIXED
**Fix:** `head -500` → configurable `--max N` flag (default: 100); added `-maxdepth 5`.

### Issue #20: validate-path.sh Pattern Bypass ✅ FIXED
**Fix:** Prefix-only match; write-zone validation.

### Issue #37: Broken Schema References ✅ RESOLVED (2026-07-01)
**Fix:** 6 missing headings added to AGENTS.md; schema_ref → note в process-files.

### Issue #38: Process-Lint JSON Corruption ✅ RESOLVED (2026-07-01)
**Fix:** Trailing commas removed, all schema_ref fixed.

### Issue #32: Wiki/sources/ Structure Missing ✅ RESOLVED (Phase 29)
**Решение:** Создан `raw/corrected/` с архитектурой "Original → Corrected → Wiki".
- Immutable originals + corrected copies + manifests
- Delta tracking, hash-based deduplication, backflow for contradiction resolution

### Delta Tracking + Backflow ✅ COMPLETED (2026-07-01)
**Phase 29:** `scripts/rebuild-source-manifest.sh` created; raw-correct.sh exists; validate-path.sh updated; process-ingest.json Step 2 (step_2_delta_check) added; **backflow completed**: 3 sources now have corrected copies + manifests.

### Section Template System ✅ COMPLETED (2026-07-01)
**Phase 13.4:** `wiki/templates/<category>-template.json` — рекомендательные списки секций для agent-guided page creation.
- Step 2.5 в process-ingest.json: read template → select sections → add new ones if needed
- Agent-driven evolution: agent добавляет новые секции сам, validates JSON before write
- No-template scenario handled gracefully (system works without templates)
**Связано:** `process-ingest.json#step_2.5`

### Schema Migration — Dialog.md → AGENTS.md ✅ COMPLETED (2026-06-29)
**Status:** All rules embedded, dialog.md removed. D1-D8 completed.


---

*Last update: 2026-07-01 | Live: #16, #5/#9, #11, #12, #18, #27, #28, #22, #23, #24, #25, #26, #8, #31, #13. Resolved today: Delta Tracking + Backflow (Phase 29), Issue #32, Section Template System.*

