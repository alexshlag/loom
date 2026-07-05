# Issues — Wiki Audit Tracker

---

## 🔴 Open / In Progress

### Issue #5/#9: Orphan Pages + Auto-Crosslink Logic 🆕 PARTIAL FIX
**Проблема**: `auto-crosslink.sh` работает только на текстовом совпадении имени, не учитывает semantic relationships.
**Fix applied:** ✅ 37 → 5 orphan pages; multi-level scoring integrated into ingest process.

**Remaining**:
- [ ] Merge/clarify `concepts/python-nixos-development.md` vs `syntheses/python-nixos-development-environments.md`

### Issue #11: Trap Handlers для Cleanup 🆕 PARTIAL
**Проблема**: Часть скриптов не использует `trap EXIT/cleanup`.
**Статус:** ✅ `wiki-search.sh`, `link-validator.sh`, `auto-crosslink.sh` используют `mktemp + trap`. ⬜ Осталось: `rebuild-meta.sh`, `check-new-sources.sh`, `text-similarity.sh`, `lint.sh`.

### Issue #12: Unit Tests для Скриптов 🆕 BROKEN
**Проблема**: Единственный тест `tests/text-similarity.bats` — broken (typo в `$BATS_TEST_DIRTEXT`). Остальные скрипты не покрыты.

### Issue #18: Hardcoded /tmp/ Overlap File 🆕 PARTIAL FIX
**Fix applied:** ✅ `process-ingest.json` updated with `mktemp`.
**Remaining**: Добавить trap cleanup для $TMP_OVERLAP.

### Issue #27: Broken Link Handling — Agent Escalation Rules 🆕 IN PROGRESS
**Проблема**: Agent escalation rules отсутствуют после DR-EX1 и step 0.75 в process-query.json.

**Fix applied:** ✅ External link standard (DR-EX1), lightweight awareness via WM, raw_source_link_repair in step_1.

**Remaining**:
- [ ] Agent decision thresholds: autonomously fix case/path mismatches; escalate fuzzy < 50
- [ ] Document escalation rules in process-query.json → broken_link_awareness

### Issue #28: Page Templates Co-evolution 🆕 INCOMPLETE
**Проблема**: AGENTS.md содержит секции Template Editing Policy и Template Co-evolution Process, но фактическая работа не завершена.
**Статус:** ⬜ Open — требуется discussion + user approval для推进.

### Issue #22: DEBUG Prints in Production Code 🆕 MEDIUM
**Проблема**: `scripts/performance/similarity_index.py:196-198,272` — `# DEBUG:` print statements в production.
**Fix**: Удалить или обернуть в `if __debug__`.

### Issue #23: Redundant Wiki Walks 🆕 MEDIUM
**Проблема**: После каждого ingest запускаются 3 независимых полных walk'а по wiki → latency проблема при 1000+ страницах.

### Issue #24: Manual JSON Construction 🆕 MEDIUM
**Проблема**: `lint.sh` и `link-validator.sh` генерируют JSON вручную через `echo`/`printf`. Если данные содержат `"`, `\n`, unicode — JSON сломается.
**Fix**: Использовать `jq` или Python для всех JSON output.

### Issue #25: `check_id` Numbering Inconsistency 🆕 LOW
**Проблема**: `lint.sh` комментарии пишут `Check 4/9` для check_id=3, `Check 5/9` для check_id=5. Нумерация не совпадает с AGENTS.md и process-lint.json.

### Issue #8: Syntheses Special Handling 🆕 PARTIAL FIX
**Проблема**: `syntheses/` — аналитические синтезы, не должны обрабатываться как обычные страницы wiki.

**Fix applied:** ✅ DR-4 в AGENTS.md; syntheses_rule в process-ingest.json step 3a; compounding_decision_logic differentiate fact collection vs new logical inference.

**Remaining**: Добавить rule → `syntheses not processed like regular wiki pages`.

### Issue #29/30: Delta Tracking & Batch Ingest ✅ RESOLVED
**Решение:** `scripts/rebuild-source-manifest.sh` + `scripts/batch-ingest.sh` — оба работают, интегрированы.

### Issue #31: Media Files Pipeline Missing 🆕 LOW
**Проблема**: Нет специфицированного pipeline для media files (OCR, metadata extraction).
**Решение:** ✅ DECISION MADE — `wiki/assets/images/[slug].[ext]` + descriptions + optional `.media-manifest.json`.

### Issue #39: Context Bloat & Architecture Optimization 🆕 P0
**Проблема**: AGENTS.md содержит технические спецификации, которые лучше вынести в `rules/`.
**Решение**: Миграция git-конвенций, language policy, memory architecture → отдельные JSON файлы.
**Статус:** ⬜ Open — требует создания директории и миграции блоков.
**Связано**: Архитектурное решение по разделению "Манифеста" и "Справочников".

---

## ✅ Resolved Today (2026-07-05)

### Issue #39: Context Bloat & Architecture Optimization 🟢 COMPLETED (Phase 14.5)
**Решение**: RULES.md (-57%), process files (-75%) extracted from AGENTS.md; schema_refs validated; system tested.
**Files affected**: AGENTS.md, RULES.md, process-query.json, process-lint.json, process-ingest.json
**Status**: ✅ All schema_refs valid, scripts executable, contradiction_resolution.json restored

### Issue #42: Tagging System — RESOLVED (Phase 15)
Created rules/tag-guidelines.json with policy, patterns by category, aliases_system, cross-reference enforcement. Lint validation check added.
**Status**: ✅ Guidelines created; audit remediation (36/38 pages) completed

### Issue #43: Cascade Priority & Contradiction Resolution Flow — RESOLVED (Phase 15.y)
Created rules/contradiction_resolution.json with full cascade logic. All schema_refs updated.
**Status**: ✅ contradiction_resolution.json created; no more broken refs to search_strategy.json#cascade_priority

### Issue #44: RULES.md:10 Audit Failures — RESOLVED (Phase 15.x)
Consolidated compounding_decision_logic, created rules/path-guard-check.json, added Lint→Ingest bridge.
**Status**: ✅ All 4 conditions satisfied; system tested and working

---

## ✅ Resolved Recently
**Fix:** Consolidated compounding_decision_logic, created rules/path-guard-check.json, added Lint→Ingest bridge. All 4 conditions from RULES.md:10 satisfied.

### Issues #37-41: Schema References & Process Workflow Anomalies — FIXED
All broken schema_refs fixed, duplicate step_id removed, stale references updated.

### Issue #42: Tagging System — RESOLVED (Phase 15)
Created rules/tag-guidelines.json with policy, patterns by category, aliases_system, cross-reference enforcement. Added lint validation check.

### Issue #43: Cascade Priority & Contradiction Resolution Flow — RESOLVED
Created rules/contradiction_resolution.json with full cascade logic. Updated all schema_refs.

---

*Last update: 2026-07-05 | Live: #5/#9, #11, #12, #18, #27, #28, #22, #23, #24, #25, #8, #39. Resolved today: #42, #43.*
