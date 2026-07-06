# Issues — Wiki Audit Tracker

---

## 🔴 Open / In Progress

### Issue #5/#9: Orphan Pages + Auto-Crosslink Logic
**Проблема**: `auto-crosslink.sh` работает только на текстовом совпадении имени, не учитывает semantic relationships.
**Fix:** ✅ 37 → 5 orphan pages; multi-level scoring integrated into ingest process.
**Remaining**: Merge/clarify `concepts/python-nixos-development.md` vs `syntheses/python-nixos-development-environments.md`.

### Issue #11: Trap Handlers для Cleanup
**Проблема:** Часть скриптов не использует `trap EXIT/cleanup`.
**Status:** ✅ `wiki-search.sh`, `link-validator.sh`, `auto-crosslink.sh`. ⬜ Осталось: `rebuild-meta.sh`, `check-new-sources.sh`, `text-similarity.sh`, `lint.sh`.

### Issue #18: Hardcoded /tmp/ Overlap File
**Fix:** ✅ `process-ingest.json` updated with `mktemp`.
**Remaining:** Добавить trap cleanup для $TMP_OVERLAP.

### Issue #27: Broken Link Handling — Agent Escalation Rules
**Проблема:** Agent escalation rules отсутствуют после DR-EX1 и step 0.75 в process-query.json.
**Fix:** ✅ External link standard (DR-EX1), lightweight awareness via WM, raw_source_link_repair in step_1.
**Remaining:**
- [ ] Agent decision thresholds: autonomously fix case/path mismatches; escalate fuzzy < 50
- [ ] Document escalation rules in process-query.json → broken_link_awareness

### Issue #28: Page Templates Co-evolution
**Проблема:** AGENTS.md содержит секции Template Editing Policy и Template Co-evolution Process, но фактическая работа не завершена.
**Status:** ⬜ Open — requires discussion + user approval.

### Issue #22: DEBUG Prints in Production Code
**Проблема:** `scripts/performance/similarity_index.py` — `# DEBUG:` print statements в production.
**Fix:** Удалить или обернуть в `if __debug__`.

### Issue #23: Redundant Wiki Walks
**Проблема:** После каждого ingest запускаются 3 независимых полных walk'а по wiki → latency при 1000+ страницах.

### Issue #24 / #45: Manual JSON Construction — Unicode Break
**Проблема:** ~15 мест в 8 скриптах генерируют JSON через `echo`/`printf`. Если данные содержат `"`, `\n`, unicode — JSON ломается.
**Затронутые:** `classify-source.sh`, `auto-crosslink.sh`, `link-validator.sh`, `rebuild-meta.sh`.
**Fix:** Replace all manual JSON output with `jq -n --arg ...` or Python `json.dumps()`.

### Issue #25: `check_id` Numbering Inconsistency
**Проблема:** `lint.sh` comments пишут `Check 4/9` для check_id=3, `Check 5/9` для check_id=5. Нумерация не совпадает с AGENTS.md и process-lint.json.

### Issue #8: Syntheses Special Handling
**Проблема:** `syntheses/` — аналитические синтезы, не должны обрабатываться как обычные страницы wiki.
**Fix:** ✅ DR-4 в AGENTS.md; syntheses_rule в process-ingest.json step 3a; compounding_decision_logic differentiate fact collection vs new logical inference.
**Remaining:** Добавить rule → `syntheses not processed like regular wiki pages`.

### Issue #46: Inconsistent `set -euo pipefail`
**Проблема:** Из 30 скриптов только 16 используют полный `set -euo pipefail`. Остальные либо без `-e`, либо `set +e`.
**Затронутые:** ❌ Без `-e`: `batch-ingest.sh`, `check-structural.sh`, `classify-source.sh`, `detect-contradications.sh`, `lint.sh`, `raw-correct.sh`, `rebuild-source-manifest.sh`.
⚠️ Явный `set +e` только в `detect-contradications.sh:23`.
**Риск:** Silent failures — команды падают, но exit code не propagated.

### Issue #47: Triple Walk in `rebuild-meta.sh`
**Проблема:** Три независимых `os.walk(wiki_dir)` вызова → O(3n) disk I/O вместо O(n). Lines 99, 187, 358.
**Риск:** +30% latency при каждом rebuild.
**Fix:** Объединить в один `os.walk()` как в `unified-pass.sh`.

### Issue #48: N+1 Python3 Calls Pattern
**Проблема:** Десятки отдельных subprocess вызовов в циклах → fork overhead × 10-40 на скрипт.
**Затронутые:** `lint.sh` (8+), `classify-source.sh`, `text-similarity.sh` (9+).
**Риск:** +2-5s overhead per run. Each python3 fork ≈ 0.2-0.3s.
**Fix:** Один `python3 << PYEOF` → все данные извлечь из одного dict → return structured output.

---

*Last update: 2026-07-06 | Open issues: #5/#9, #11, #18, #27, #28, #22, #23, #24+#45, #25, #8, #46, #47, #48.*
