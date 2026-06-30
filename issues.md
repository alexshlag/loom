# Issues — Wiki Audit Tracker

# Issues — Wiki Audit Tracker

---

## 🚨 Live Issues (требуют решения)

### Issue #29: Delta Tracking — Placement & Implementation 🆕
**Проблема**: В claude-obsidian delta tracking лежит в `.raw/.manifest.json`, но в Loomana:
1. `raw/**` protected для writes (validate-path.sh + pre-commit hook)
2. `meta/` занят для auto-generated файлов, rebuild через скрипт
3. Agent не может писать напрямую в protected zones

**Решение:** ✅ **DECISION MADE**
- `source-manifest.json` → разместить в `meta/source-manifest.json`
- Агент НЕ пишет напрямую — только через скрипт (pattern как `rebuild-meta.sh`)
- Скрипт: `scripts/rebuild-source-manifest.sh --add <path>` / `--scan` / `--check <path>`
- Совместимо с existing guardrails: validate-path.sh blocks direct write, script bypasses via internal logic

**Вопросы, которые остались открытыми**:
- [ ] Скрипт: `--add`, `--scan`, `--check` — API design (подробности при имплементации)
- [ ] Интеграция в ingest flow — trigger point (agent вызывает скрипт после каждого source read)

**Severity**: HIGH — предотвращает waste of tokens на re-ingest

### Issue #30: Batch Ingest Workflow Missing 🆕
**Проблема**: В Loomana каждый источник обрабатывается изолированно. Нет cross-reference между новыми источниками и bulk-update index/hot/log.

**Вопросы**:
- [ ] Как разделить интеллект (агент) vs автоматизация (скрипт)?
- [ ] Нужен ли `scripts/batch-ingest.sh` для автоматизированной части?
- [ ] Или достаточно правила в AGENTS.md + agent's memory context?

**Severity**: MEDIUM — улучшает cross-references и снижает количество мелких писаний

### Issue #31: Media Files Pipeline Missing 🆕
**Проблема**: В Loomana нет специфицированного pipeline для media files:
- Описание изображения → markdown + OCR
- Копия оригинала в vault
- Структура `.raw/images/` vs `_attachments/`

**Решение:** ✅ **DECISION MADE**
- `wiki/assets/images/[slug].[ext]` — копия оригинала изображения (agent-owned, write allowed)
- `wiki/assets/descriptions/[slug].md` — markdown с OCR + metadata + описанием
- `wiki/assets/.media-manifest.json` — optional tracking хешей изображений
- Agent владеет wiki/, никаких guardrails, никаких скриптов-обёрток
- Визуально логично: assets/ = медиа-контент (как в Obsidian)

**Вопросы, которые остались открытыми**:
- [ ] Скрипт `scripts/media-ingest.sh` — автоматизация OCR + metadata extraction
- [ ] Интеграция в ingest flow — trigger point (agent вызывает media pipeline при получении изображения)

**Severity**: LOW — nice-to-have, не блокирует работу

### Issue #32: Wiki/sources/ Structure Missing 🆕
**Проблема**: В Loomana нет отдельной зоны для sources. Факты из разных источников смешаны.

**Вопросы**:
- [ ] Нужна ли `wiki/sources/` папка?
- [ ] Или достаточно frontmatter `sources: []` в каждой странице?

**Severity**: MEDIUM — улучшает audit trail и conflict resolution

### Issue #16: Broken Unit Tests (CRITICAL) 🆕
**Проблема**: Единственный тест `tests/text-similarity.bats:6` содержит typo — `$BATS_TEST_DIRTEXT` вместо `$BATS_TEST_DIRNAME`. Все тесты падают.
- `assert` function не импортирована — bats использует другой синтаксис

**Severity**: **CRITICAL** — тестовое покрытие = 0%.

### Issue #17: Silent Error Swallowing (HIGH) ✅ FIXED
**Проблема**: `lint.sh` оборачивает всё в `|| true` — ошибки под-скриптов тихо глотались.
- `orphan-pages.sh`, `check-new-sources.sh`, `duplicate-titles.sh`, `date-consistency.sh`, `link-validator.sh` — все `|| true`
- Если любой скрипт упадёт с segfault / exception, lint покажет 0 проблем

**Пример**:
```bash
ORPHANS_OUTPUT=$(./scripts/orphan-pages.sh ... 2>&1 || true)
```

**Fix applied (2026-06-30)**:
1. ✅ `set -e` → заменён на `set -uo pipefail` — больше automatic exit при ошибках
2. ✅ Добавлена `log_error()` функция для unified error logging в stderr
3. ✅ Исправлён duplicate code в check-new-sources (дважды дублировался блок с '^NEW:')
4. ✅ Нумерация checks исправлена: 1-7 primary + 8-9 extended
5. ✅ Created `scripts/utilities/common.sh` — unified safe_run() with expected exit codes
6. ✅ lint.sh теперь использует safe_run для всех inner-script вызовов
7. ✅ Все скрипты вызываются с явным expected_codes: "0", "0 1", etc.
8. ✅ Ошибки логируются в stderr, но не блокируют flow

**Remaining**: 
- [ ] Убрать `|| true` у всех скриптов → заменить на safe_run() или explicit exit code handling
- [ ] Добавить error logging в `orphan-pages.sh`, `check-new-sources.sh`, `duplicate-titles.sh`, `date-consistency.sh`
- [ ] Перенести log_error из lint.sh в utilities/ для переиспользования

### Issue #18: Hardcoded /tmp/ Overlap File (HIGH) ⚠️ PARTIAL FIX
**Проблема**: `process-ingest.json:237` — `text-similarity.sh --scan-all > /tmp/overlap_result.json`
- Race condition между параллельными инстансами
- Нет cleanup при краше
- Нарушение RULES.md (use mktemp, not /tmp/)

**Fix applied (2026-06-30)**:
1. ✅ `process-ingest.json` updated: `mktemp` instead of hardcoded `/tmp/overlap_result.json`
2. ✅ Command now uses `$TMP_OVERLAP` variable pattern

**Remaining**: 
- [ ] Добавить trap cleanup для $TMP_OVERLAP в agent workflow (или скрипт сам cleanups)
- [ ] Проверить другие места где используется /tmp/ в скриптах

### Issue #19: Link Validator 500-File Limit (HIGH) ✅ FIXED
**Проблема**: `link-validator.sh:77` — `find ... | head -500`. Если в wiki >500 .md файлов, последние не проверяются.

**Fix applied (2026-06-30)**:
1. ✅ `head -500` → заменён на configurable `--max N` flag (default: 100)
2. ✅ Добавлен `-maxdepth 5` для предотвращения глубоких рекурсий
3. ✅ Обновлены обе точки: find_best_match() и main scan loop

### Issue #20: validate-path.sh Pattern Bypass (HIGH) ✅ FIXED
**Проблема**: `validate-path.sh:18` — substring match `*\"$PATTERN\"*`. `meta/` совпадает с `some-meta/file.md`, bypass защиту.

**Fix applied (2026-06-30)**:
1. ✅ Prefix-only match: `[[ \"$PATH_TO_CHECK\" == \"$PATTERN\"* ]]` — больше не будет false positive на `some-meta/`
2. ✅ Добавлена write-zone validation: путь должен начинаться с allowed zone (`raw/sources/`, `wiki/`) иначе блокируется
3. ✅ Теперь нельзя писать в任意ю зону кроме разрешённых

### Issue #5/#9: Orphan Pages + Auto-Crosslink Logic ⚠️ PARTIAL FIX
**Проблема**: `auto-crosslink.sh` работает только на текстовом совпадении имени, не учитывает semantic relationships и shared-source clusters.

**Fix applied (2026-06-28)**:
1. ✅ `orphan-pages.sh` fixed — 37 → 5 orphan pages (только системные)
2. ✅ `auto-crosslink.sh` rewritten с multi-level scoring (H1 + shared sources + frontmatter)
3. ✅ Integrated into ingest process: step_3a, step_3b, step_3d

**Remaining**:
- [ ] Merge/clarify `concepts/python-nixos-development.md` vs `syntheses/python-nixos-development-environments.md` — redundant content
- [x] Exclude system files (log.md, timeline.md) from normal search logic ✅ done

👉 **Canonical**: `scripts/orphan-pages.sh`, `scripts/auto-crosslink.sh`, `decision-rules.md`, `process-ingest.json`

### Issue #10: Error Logging — Unified Format 🔽 FIXED
**Проблема**: Нет единого формата логирования ошибок между скриптами.
- Каждый скрипт пишет в свой stderr / отдельный log file
- Нет `log_error()` функции с timestamp + level + message

**Fix applied (2026-06-30)**:
1. ✅ Created `scripts/utilities/common.sh` — unified `log_error()`, `log_warn()`, `safe_run()`
2. ✅ `lint.sh` now sources common.sh and uses safe_run for all script calls
3. ✅ All script exit codes properly handled (no more silent failures)
4. ✅ Format: `[!] [ERROR] Command exited with code X: message`

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
1. ✅ **Решено**: DR-EX1 added to AGENTS.md — external link standard с known sources list (NixOS Wiki, GitHub, etc.)
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
5. ✅ **Выполнено**: Home_Manager.md → https://wiki.nixos.org/wiki/Home_Manager (fixed in python-nixos-development-environments.md)
6. ⚠️ **ОТМЕНЕНО**: raw/github/lee-to/ai-factory@2.x был создан вручную, в обход capture flow — удалён. Скрипт raw-link-repair.py/sh не применим к этому случаю (было неправильное размещение).

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

### Issue #28: Page Templates Co-evolution — INCOMPLETE 🆕
**Проблема**: AGENTS.md содержит секции Template Editing Policy и Template Co-evolution Process, но фактическая работа над шаблонами страниц (user-approved structural improvements) не завершена.
- Agent может предлагать улучшения через `[schema-patch]` в log.md
- User должен review/approve → agent commit update
- Новые сценарии → discuss → add to schema
**Статус:** ⬜ Open — требуется discussion + user approval для推进
**Schema ref**: `AGENTS.md#template_co_evolution`, `process-ingest.json` (логирование в log.md)

---

## ✅ Resolved

### Issues #1-3: External Sources + Novelty Threshold
| Issue | Решение |
|-------|---------|
| Как часто обновлять? | User-requested или cron (`check-new-sources.sh`) |
| web_search приоритет? | Тот же источник → внешние данные; разные → `decision-rules.md` |
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

## ✅ Resolved Today (2026-06-30)

### Harness-Independent Session & Git Operations → COMPLETED
**Проблема**: Скрипты для session management и auto-commit существовали, но не были интегрированы в process-файлы.
**Fix applied**:
1. ✅ `git-auto-commit.sh` — ingest step 3a/3b + query result_fixation (6 точек вызова)
2. ✅ `load-hot-cache.sh` — query bootstrap (step 0.25)
3. ✅ `restore-hot-cache.sh` — query compaction post_action (step 2.3)
4. ✅ `check-wiki-changes.sh` — lint check_id "8"
5. ✅ Секция Harness-Independent удалена из AGENTS.md — правила живут в процессах
6. ✅ NEW_EXT_PLAN.md удалён как выполненный план
7. ✅ wiki/hot.md инициализирован (1477 байт)
**Schema ref**: `AGENTS.md#context_compaction_handling`, `process-query.json#step_0.25`, `process-ingest.json#step_3a`

### Natural Memory Translation → NEW CONCEPT CREATED
**Проблема**: Agent не переводил машино-читаемые даты в естественную форму.
**Fix applied**:
1. ✅ Правило добавлено в AGENTS.md → Memory Architecture Contract (NATURAL MEMORY TRANSLATION)
2. ✅ Living-doc создан: `wiki/concepts/natural-memory.md` — принципы, примеры, table date→human-term
3. ✅ Snapshot обновлён с новыми проектами и датой 2026-06-30
4. ✅ Log updated with today's entries

### Delta Tracking Placement → DECISION MADE (2026-06-30)
**Решение**: `source-manifest.json` живёт в `meta/`, агент пишет через скрипт, не напрямую.
1. ✅ **Placement resolved**: `meta/source-manifest.json` — alongside registry.json, backlinks.json
2. ✅ **Access pattern resolved**: agent calls `scripts/rebuild-source-manifest.sh`, never writes JSON directly
3. ✅ Matches existing meta pattern: rebuild-meta.sh → rebuild all; rebuild-source-manifest.sh → rebuild manifest only
4. ⬜ Implementation pending: script API design (`--add`, `--scan`, `--check`) и integration в ingest flow

---

*Last update: 2026-06-30 | Live: #16 (broken tests), #17 (silent errors), #20 (validate-path bypass). Resolved today: Harness-Independent Session & Git Operations, Natural Memory Translation.*
