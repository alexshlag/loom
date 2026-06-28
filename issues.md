# Issues — Wiki Audit Tracker

---

## 🚨 Live Issues (требуют решения)

### Issue #21 / P8: Heredoc Injection in wiki-search.sh ✅ RESOLVED
**Проблема**: `wiki-search.sh:314,445` — unquoted heredoc (`<< PYEOF`) позволял shell expand `$QUERY` перед передачей Python → command injection.
**Fix (2026-06-28)**:
1. ✅ Оба heredoc заменены на `'PYEOF'` (квантованные)
2. ✅ Query передан через env var (`export SEARCH_QUERY`) вместо inline expansion
3. ✅ `save_query_to_history` также переведён на env var passing (`HISTORY_QUERY`, `HISTORY_RESULTS_COUNT`)
4. ✅ Добавлен `import os` во second heredoc для чтения env vars
**Результат**: `$(echo pwned)` не выполняется, выводится как literal string.

### Issue #H3: detect-contradications False Positives ✅ RESOLVED
**Проблема**: `_detect_contradictions.py` сканировал все `.md` в wiki/, включая system files (`issues.md`, `log.md`) → false positives.
**Fix (2026-06-28)**: Добавлен `EXCLUDED_FILES` set + проверка `if fname in EXCLUDED_FILES: continue`. Исключены: log.md, issues.md, timeline.md, overview.md, snapshot.md, index.md, GIT-STATUS-LOG.md, working_memory.json.
**Результат**: Только legitimate contradictions (python-nixos date conflict) возвращаются.

### Issue #16: Broken Unit Tests (CRITICAL) 🆕
**Проблема**: Единственный тест `tests/text-similarity.bats:6` содержит typo — `$BATS_TEST_DIRTEXT` вместо `$BATS_TEST_DIRNAME`. Все тесты падают.
- `assert` function не импортирована — bats использует другой синтаксис

**Severity**: **CRITICAL** — тестовое покрытие = 0%.

### Issue #17: Silent Error Swallowing (HIGH) 🆕
**Проблема**: `lint.sh` оборачивает всё в `|| true` — ошибки под-скриптов тихо глотаются.
- `orphan-pages.sh`, `check-new-sources.sh`, `duplicate-titles.sh`, `date-consistency.sh`, `link-validator.sh` — все `|| true`
- Если любой скрипт упадёт с segfault / exception, lint покажет 0 проблем

**Пример**:
```bash
ORPHANS_OUTPUT=$(./scripts/orphan-pages.sh ... 2>&1 || true)
```

**Fix**: Разделять exit code: `|| true` только если ошибка non-fatal. Логировать реальные ошибки.

### Issue #18: Hardcoded /tmp/ Overlap File (HIGH) 🆕
**Проблема**: `process-ingest.json:237` — `text-similarity.sh --scan-all > /tmp/overlap_result.json`
- Race condition между параллельными инстансами
- Нет cleanup при краше
- Нарушение RULES.md (use mktemp, not /tmp/)

**Fix**: Использовать `mktemp` + trap cleanup.

### Issue #19: Link Validator 500-File Limit (HIGH) 🆕
**Проблема**: `link-validator.sh:77` — `find ... | head -500`. Если в wiki >500 .md файлов, последние не проверяются.

**Fix**: Убрать `head -500` или сделать configurable limit.

### Issue #20: validate-path.sh Pattern Bypass (HIGH) 🆕
**Проблема**: `validate-path.sh:18` — substring match `*"$PATTERN"*`. `meta/` совпадает с `some-meta/file.md`, bypass защиту.

**Fix**: Использовать точное совпадение префикса: `[[ "$PATH_TO_CHECK" == "$PATTERN"* ]]`.

### Issue #5/#9: Orphan Pages + Auto-Crosslink Logic ⚠️ PARTIAL FIX
**Проблема**: `auto-crosslink.sh` работает только на текстовом совпадении имени, не учитывает semantic relationships и shared-source clusters.

**Fix applied (2026-06-28)**:
1. ✅ `orphan-pages.sh` fixed — 37 → 5 orphan pages (только системные)
2. ✅ `auto-crosslink.sh` rewritten с multi-level scoring (H1 + shared sources + frontmatter)
3. ✅ Integrated into ingest process: step_3a, step_3b, step_3d

**Remaining**:
- [ ] Merge/clarify `concepts/python-nixos-development.md` vs `syntheses/python-nixos-development-environments.md` — redundant content
- [x] Exclude system files (log.md, timeline.md) from normal search logic ✅ done

👉 **Canonical**: `scripts/orphan-pages.sh`, `scripts/auto-crosslink.sh`, `AGENTS.md#decision_rules`, `process-ingest.json`

### Issue #10: Error Logging — Unified Format 🔽 LOW PRIORITY
**Проблема**: Нет единого формата логирования ошибок между скриптами.
- Каждый скрипт пишет в свой stderr / отдельный log file
- Нет `log_error()` функции с timestamp + level + message
- Python скрипты используют `print` вместо `logging`

**Статус:** ⬜ Deferred — не блокирует работу, но улучшает maintainability

### Issue #11: Trap Handlers для Cleanup 🔽 PARTIALLY DONE
**Проблема**: Часть скриптов не использует `trap EXIT/cleanup`.
- При аварийном выходе временные файлы остаются
- Нет rollback при ошибке записи JSON в meta/

**Частично исправлено**: `wiki-search.sh`, `link-validator.sh`, `auto-crosslink.sh` используют `mktemp + trap`.
**Осталось**: `rebuild-meta.sh`, `check-new-sources.sh`, `text-similarity.sh`, `lint.sh`.

**Статус:** ⬜ Частично — требуется для всех скриптов

### Issue #12: Unit Tests для Скриптов ⚠️ BROKEN
**Проблема**: Единственный тест `tests/text-similarity.bats`:
- Typo `$BATS_TEST_DIRTEXT` → не работает
- `assert` не импортирован — bats использует другой синтаксис (например, `[ "$x" = "$y" ]`)
- Остальные скрипты не покрыты

**Статус:** 🔴 **Broken** — требуется починить существующий тест и добавить новые

### Issue #13: scripts/README.md 🔽 LOW PRIORITY
**Проблема**: Нет единой документации по скриптам.
- Usage examples, architecture overview, known limitations отсутствуют
- Сложно новичку понять, как работают 15+ скриптов

**Статус:** ⬜ Deferred — nice-to-have для onboarding



### Issue #22: DEBUG Prints in Production Code (MEDIUM) 🆕
**Проблема**: `scripts/performance/similarity_index.py:196-198,272` — `# DEBUG: ...` print statements оставлены в production.

**Fix**: Удалить или обернуть в `if __debug__`.

### Issue #23: Redundant Wiki Walks (MEDIUM) 🆕
**Проблема**: После каждого ingest запускаются `rebuild-meta.sh` + `link-validator.sh` + `auto-crosslink.sh` — 3 независимых полных walk"а по wiki. Для 1000+ страниц latency станет проблемой.

**Fix**: Объединить в единый скрипт `rebuild-and-validate.sh` или передавать results между Script'ами.

### Issue #24: Manual JSON Construction (MEDIUM) 🆕
**Проблема**: `lint.sh:127-145` и `link-validator.sh:63-64` генерируют JSON вручную через `echo`/`printf` + `sed` escaping. Если данные содержат `"`, `\n`, или unicode — JSON будет сломан.

**Fix**: Использовать `jq` или Python для всех JSON output.

### Issue #25: `check_id` Numbering Inconsistency (LOW) 🆕
**Проблема**: `lint.sh` комментарии пишут `Check 4/9` для check_id=3, `Check 5/9` для check_id=5. Нумерация не совпадает с AGENTS.md и process-lint.json.

### Issue #26: Stale AGENTS.md Footer (LOW) 🆕
**Проблема**: `AGENTS.md:545` — `Schema Version: 9 | Last Updated: 2026-06-26`. Текущая дата 2026-06-28.
**Typo**: строка 556 `concept/` → должно быть `concepts/`.

---

### Issue #27: Broken Link Handling — Agent Escalation Rules 🆕 IN PROGRESS
**Проблема**: `link-validator.sh --full` обнаруживает broken links, но agent escalation rules отсутствуют:
1. Нет правила что делать с Home_Manager.md (fuzzy score 45 < threshold 80)
2. Raw sources содержат битые ссылки на upstream файлы (SKILL.md references) — не исправляются при ingest
3. Agent не знает когда auto-fix vs escalate to user

**Fix (2026-06-28)**:
1. ✅ Добавлен step `0.75` в `process-query.json#broken_link_awareness`: lightweight check via working_memory — НЕ запускает full scan, только читает known broken links из previous sessions.
   - external_wiki_pattern → suggest external URL
   - create_page_or_remove → offer options to user
   - no_match_found → log as TODO, notify user
2. ✅ Agent decision thresholds: autonomously fix case/path mismatches; escalate fuzzy < 50 or ambiguous intent
3. ✅ Добавлено `raw_source_link_repair` в `process-ingest.json#step_1 source_analysis`: при ingest сканирует markdown ссылки, заменяет битые на external URL / GitHub permlink
4. ✅ Обновлён step `6 post_operation_link_validation` в `process-ingest.json`: только new files check (не --full)
5. 🔽 Осталось: применить fix к существующей Home_Manager.md ссылке (replace with https://wiki.nixos.org/wiki/Home_Manager)
6. 🔽 Осталось: починить SKILL.md references в ai-factory configuration.md при следующем ingest

**Зона ответственности**:
| Режим | Что делает | Когда сканирует wiki |
|-------|-----------|----------------------|
| **query (step 0.75)** | Чтение из WM, lightweight awareness | ❌ НЕ сканирует |
| **lint** | Полный audit (`--full`) | ✅ Полная проверка |
| **post-ingest (step 6)** | Check new files only | ✅ Только новые файлы |

**Schema ref**: `process-query.json#broken_link_awareness`, `process-ingest.json#raw_source_link_repair`

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
- `grep -oP` portability → fixed (link-validator.sh) ✅
- `escape_for_grep` for regex injection protection → fixed (wiki-search.sh) ✅
- Context bubble → max 3 pages, working_memory bridge → implemented ✅
- `/tmp/` hardcoded paths in scripts → `mktemp` migration (wiki-search.sh, link-validator.sh, auto-crosslink.sh) — **in progress**

---

*Last update: 2026-06-28 | Live: P9-P26 from full audit (P8/#H3 resolved). Resolved: #1-4, #6-7, architecture fixes, P8 (#21), #H3. **Critical**: #15 atomic writes, #16 broken tests, #17 silent errors.*
