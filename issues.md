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

### Issue #12: Unit Tests для Скриптов 🆕 RESOLVED (Phase 17)
**Проблема**: Единственный тест `tests/text-similarity.bats` — broken (typo в `$BATS_TEST_DIRTEXT`). Остальные скрипты не покрыты.
**Решение:** ✅ **DONE (2026-07-05)**: 8 Python test modules, 53+ tests created. All passing.

| File | Tests | Coverage |
|------|-------|----------|
| `test_process_ingest.py` | 27 | Ingest + Query basic structure, cross-process consistency |
| `test_process_integration.py` | 15 | Step ordering, schema refs, git conventions, scripts exist |
| `test_process_additional.py` | 6 | Branching logic, triggers, evaluation criteria |
| `test_process_commands.py` | 3 | Script existence verification |
| `test_process_query.py` | — | Query-specific tests |
| `test_process_lint.py` | — | Lint-specific tests |
| `test_integration_cross_references.py` | — | Cross-reference validation |

**Status:** ✅ All 53+ tests pass. Coverage: process-*.json structure, schema_refs, step ordering, script existence.
> **Next**: Script-level unit tests (lib.sh, link-validator.sh, auto-crosslink.sh) — separate issue.

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

---

### Issue #45: JSON Safety — Unicode Break in Manual Construction 🆕 P0 CRITICAL
**Проблема**: ~15 мест в 8 скриптах генерируют JSON через `echo "..."` или `printf '%s'`. Если данные содержат `"`, `\`, unicode — JSON ломается.
**Затронутые файлы:**
- `classify-source.sh:43,180,186,192` — `echo "{\"source":"$URL",...}`
- `auto-crosslink.sh:260` — `echo "{\"path":"$REL_PATH","score":$score,...}`
- `link-validator.sh:239,250,261,348,394` — `printf '{"file":"%s",...}'`
- `rebuild-meta.sh` — несколько мест
**Риск:** Silent data corruption on unicode paths/URLs. Can break downstream JSON parsers.
**Fix:** Replace all manual JSON output with `jq -n --arg ...` or Python `json.dumps()`. Issue #24 is the same root cause.
**Priority:** 🔴 P0 — structural data integrity

### Issue #46: Inconsistent `set -euo pipefail` 🆕 P1 HIGH
**Проблема**: Из 30 скриптов только 16 используют полный `set -euo pipefail`. Остальные либо без `-e`, либо `set +e`.
**Затронутые:**
- ❌ Без `-e`: `batch-ingest.sh`, `check-structural.sh`, `classify-source.sh`, `detect-contradications.sh`, `lint.sh`, `raw-correct.sh`, `rebuild-source-manifest.sh`
- ⚠️ Явный `set +e` только в `detect-contradications.sh:23` — единственный скрипт с отключённым errexit
**Риск:** Silent failures — команды падают, но exit code не propagated. В `lint.sh` это критично.
**Fix:** Добавить `set -euo pipefail` ко всем скриптам; где нужен `set +e` — добавить комментарий почему.

### Issue #47: Triple Walk in `rebuild-meta.sh` 🆕 P2 MEDIUM
**Проблема**: Три независимых `os.walk(wiki_dir)` вызова → O(3n) disk I/O вместо O(n).
- Line 99, 187, 358 — три полных обхода wiki/
**Риск:** +30% latency при каждом rebuild. На 1000+ страницах становится заметным.
**Fix:** Объединить в один `os.walk()` как в `unified-pass.sh`. Собрать все нужные данные за один проход.

### Issue #48: N+1 Python3 Calls Pattern 🆕 P2 MEDIUM
**Проблема**: Десятки отдельных subprocess вызовов в циклах. Fork overhead × 10-40 на один скрипт.
**Затронутые:**
- `lint.sh:59,119,134-136,152,164-167,194-197,275` — 8+ отдельных python3 вызовов
- `classify-source.sh:88,127` — отдельный python3 для каждого domain check
- `text-similarity.sh:95,136,171,253,261,278,438,455,468` — 9+ вызовов
**Риск:** +2-5s overhead per run. Each python3 fork ≈ 0.2-0.3s.
**Fix:** Один `python3 << PYEOF` → все данные извлечь из одного dict → return structured output.

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

*Last update: 2026-07-06 | Live: #5/#9, #11, #18, #27, #28, #22, #23, #45(P0), #46(P1), #47(P2), #48(P2). Resolved: #12 (Phase 17 tests created), #42, #43.*
