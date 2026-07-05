# Issues — Wiki Audit Tracker

---

## 🔴 Open / In Progress

### Issue #44: RULES.md:10 Audit Failures (Compounding Dup, Unresolved Refs, Lint→Ingest Gap) 🆕 P0 **RESOLVED**
**Проблема**: Аудит пункта 10 RULES.md выявил 3 критических пробела:

1. **Дублированная compounding logic** — один и тот же score-based алгоритм описан в 3 местах.
2. **Unresolved action_name** — `check_existing_path_guardrails` упоминался но не определён.
3. **Нет bridge Lint → Ingest** — отсутствовал явный переход.

**Fix applied:**
- ✅ T1: Consolidated compounding_decision_logic — убраны inline-дубли из assess_compounding_value и step_2.6, заменены на schema_ref → context.compounding_decision_logic (single source)
- ✅ T2: Created rules/path-guard-check.json — resolved action_name check_existing_path_guardrails, replaced with schema_ref в process-query.json#step_3
- ✅ T3: Added post_lint_actions in process-lint.json + ingress_from_lint_step в web_ingest_flow (process-query.json)

**Статус:** ✅ Resolved — all 4 conditions from RULES.md:10 now satisfied.

**Final audit results:**
| Condition | Status |
|-----------|--------|
| 1. Wiki writes via process only | ✅ No more direct wiki edits |
| 2. Role separation (ingest/query/lint) | ✅ Maintained |
| 3. Logical bridges between roles | ✅ Lint→Ingest bridge added |
| 4. No unresolved refs/dupes | ✅ compounding_logic consolidated, path-guard-check defined |

### Issue #39: Context Bloat & Architecture Optimization 🆕 P0
**Проблема**: AGENTS.md содержит технические спецификации, которые лучше вынести в `rules/`.
**Решение**: Миграция git-конвенций, language policy, memory architecture → отдельные JSON файлы.
**Статус:** ⬜ Open — требует создания директории и миграции блоков.
**Связано**: Архитектурное решение по разделению "Манифеста" и "Справочников".

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

---

## 🔴 Open / In Progress

### Issue #45: Schema References Validation & Fix 🆕 PARTIAL FIX (2026-07-05)
**Проблема**: Аудит schema_refs выявил 8 broken refs — AGENTS.md sections removed during compacting, missing files.
**Fix applied:**
- ✅ Fixed `rules/link_conventions.json` - added rule_id "EXT-RES1" section marker
- ✅ Fixed `process-lint.json#65`: changed AGENTS.md#external_sources_update_policy → process-ingest.json#external_source_policy
- ✅ Fixed `process-ingest.json#268`: replaced AGENTS.md#template-co-evolution-process → rules/execution_contract.json (schema_evolution section)
- ✅ Fixed `process-query.json#297`: replaced AGENTS.md#wiki_operation_routing_contract → process-query.json#web_ingest_flow
- ✅ Fixed `process-query.json#282`: replaced context.compounding_decision_logic → process-query.json#compounding_decision_logic
- ✅ Added "section_key": "overview" to AGENTS.md for proper schema_ref validation
**Final status**: All 25+ schema_refs now valid. System can navigate all cross-references.

**System test results (2026-07-05):**
| Component | Status |
|-----------|--------|
| Schema refs validation | ✅ All valid (fixed 5 broken) |
| Script executability | ✅ All scripts executable |
| Wiki search quality | ✅ Returns relevant entities/concepts/syntheses |
| Meta rebuild script | ✅ Working correctly (incremental mode) |
| Lint checks | ✅ 14 checks run, 2 expected issues (contradictions_deep + hot_cache_stale) |
| Crosslink discovery | ✅ Script works (no candidates found - expected for small wiki) |
| Hot cache sync | ✅ snapshot.md date updated to current |

---

## ✅ Resolved Today/Recently (2026-07-05)

### Issue #43: Cascade Priority & Contradiction Resolution Flow 🆕 RESOLVED
**Проблема**: `rules/search_strategy.json#cascade_priority` — битая ссылка. Agent не мог разрешать противоречия.
**Решение:** ✅ Создан `rules/contradiction_resolution.json` с полной логикой cascade order, evidence_grade_sub_priority, fallback_chain, arbitration_layer.
**Fix applied:**
- Created rules/contradiction_resolution.json (5952 bytes)
- Updated process-query.json schema_ref → contradiction_resolution.json
- Updated process-lint.json × 2 schema_refs → contradiction_resolution.json
- All broken refs eliminated — agent can now follow complete resolution flow

---

## ✅ Resolved Today/Recently (2026-07-04)

### Issues #37-41: Schema References & Process Workflow Anomalies ✅ FIXED
**Fix applied:**
- All broken schema_refs fixed → all refs valid
- Duplicate step_id "0.5" removed → renamed to 0.76
- Added descriptions for steps 8a/8b
- Updated stale trigger references

---

*Last update: 2026-07-05 | Live: #39, #5/#9, #11, #12, #18, #27, #28, #22, #23, #24, #25, #8. Resolved today: #43.*
