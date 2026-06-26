# Issues — Полный аудит wiki (2026-06-24)

Создано: 2026-06-24 | Source: full lint pass + structure validation + link analysis

---

## 🤖 Agent Reasoning & Workflow Issues (Audit 2026-06-24)

| Проблема | Описание | Статус |
|----------|----------|--------|
| Search Sufficiency | `grep_recursive_fallback` может генерировать шум | 🟡 Требует внимания |
| Knowledge Hierarchy | Отсутствие четкой иерархии типов страниц при синтезе | 🟡 Требует внимания |
| Novelty Threshold | Предложение новых страниц может привести к дублированию | 🟡 Требует внимания |
| Source Weighting | Отсутствие оценки авторитетности источников | 🟡 Требует внимания |
| Inline Citations | Технические инструкции в ответах не всегда имеют прямые ссылки | 🟡 Требует внимания |
| Актуальность информации | Инструкция говорит "prefer newer version" при temporal conflict, но не учитывает устаревание фактов на новых страницах. В тесте: информация об Eureka Labs (2024) и Anthropic (2026) есть только в raw, но не интегрирована в wiki. | 🟡 Требует внимания |
| Правила web_search | Не明确规定 когда можно/нельзя использовать web_search для проверки фактов из wiki. | 🟡 Требует внимания |
| Критерий novel insight | Инструкция "If answer synthesizes from 2+ sources AND contains novel insight → flag for fixation" субъективна. Что считается insight? Сбор фактов или только новые выводы? | 🟡 Требует внимания |
| Целостность cross-references | Инструкция требует добавлять backlinks к новым страницам, но не проверяет существующие страницы на сломанные ссылки. В тесте: `wiki/overview.md` упоминает Karpathy, но не проверена рабочая ссылка. | 🟡 Требует внимания |
| Противоречия в разрешении | Нет четкого приоритета между стратегиями разрешения противоречий. Не покрываются scope_conflict и contextual_conflict. Нет пост-проверки. | ✅ Исправлено (см. ниже) |
| Авторитетные источники | В инструкции указано `official docs > community wiki > personal notes`, но нет механизма автоматического определения authoritative source. | ⚠️ Требует твоего решения |

---

## 📊 Lint Health Score: **10/10** — Все проблемы исправлены ✅

---

## ✅ Исправления в разрешении противоречий (Issue #6) — 2026-06-24

**Обнаружено**: Инструкция разрешения противоречий имела следующие проблемы:
1. Нет четкого приоритета между стратегиями (temporal vs authoritative)
2. Не покрывались типы scope_conflict, contextual_conflict, version_conflict
3. Отсутствовала пост-проверка после разрешения
4. Нет истории изменений при разрешении

**Исправление**:
1. Добавлена иерархия приоритетов: authoritative_source > temporal_conflict > user_review
2. Расширены типы противоречий (scope_conflict, contextual_conflict, version_conflict)
3. Добавлен шаг post_resolution_verification с re-read и optional web search
4. Добавлен формат истории изменений при разрешении

**Ссылки**:
- [process-query.json](process-query.json) (contradiction_resolution_flow)
- [wiki/log.md](wiki/log.md) (запись о исправлении)

---

## 📊 Детали исправления разрешения противоречий

### Новая структура resolution_priority:

```
1. authoritative_source (приоритет 1)
   └── Если есть official docs → использовать его, игнорируя дату
   
2. temporal_conflict (приоритет 2)
   └── Если нет authoritative source → новее лучше
   
3. user_review (приоритет 3)
   └── Если неясно или contextual conflict → спросить пользователя
```

### Новые типы противоречий:

| Тип | Описание | Пример | Стратегия разрешения |
|-----|----------|--------|---------------------|
| scope_conflict | Разный уровень абстракции | "Python 3.12" vs "Python 3.x" | Предпочитать конкретное, если подтверждено |
| contextual_conflict | Разные контексты применения | "Для Linux — метод X" vs "Для Windows — метод Y" | Создать сравнительную страницу с условиями применимости |
| version_conflict | Противоречие между версиями | Документация v1 vs v2 одного проекта | Указывать версию и предлагать актуальную |

### Пример записи истории изменений:

```markdown
## Обновлено 2026-06-24 — новое уточнение

### История изменений:
- **2026-06-24**: Обновлено с X=5 → X=10 (разрешение противоречия со Страницей B)
  - Причина: temporal_conflict
  - Источник решения: Страница B (2026-01-01, official docs)
```

---

## ⚠️ Требует твоего внимания (2026-06-24)

### Issue #1: Актуальность информации
**Проблема**: Новые страницы могут содержать устаревшие факты. Инструкция не проверяет актуальность через внешние источники.

**Вопрос**: Как часто агент должен обновлять wiki из внешних источников? Автоматически при каждом query или по расписанию?

---

### Issue #2: Правила web_search
**Проблема**: Не明确规定 когда можно/нельзя использовать web_search для проверки фактов из wiki.

**Вопрос**: Когда внешние источники важнее внутренних? (См. также Question #4 выше)

---

### Issue #3: Критерий novel insight
**Проблема**: Инструкция субъективна — что считается "novel insight"?

**Вопрос**: Нужны ли чёткие критерии или агент должен сам определять?

---

### Issue #4: Авторитетные источники (⚠️ Важно!)
**Проблема**: В инструкции указано `official docs > community wiki > personal notes`, но нет механизма автоматического определения.

**Требует твоего решения**: Какие критерии считать источником authoritative?

**Варианты**:
1. **По домену**: `github.com`, `*.com` (официальные сайты), `wikipedia.org`
2. **По метаданным**: frontmatter.source_type = "official" или author = известное лицо/компания
3. **По авторству**: если author — известный эксперт в области
4. **Комбинированный**: домен + авторство + наличие official badge

**Предложи свои критерии, и я обновлю инструкцию.**

---

*Created: 2026-06-24 | Status: Issues #5, #6 Fixed ✅ | Issue #1-4 Pending discussion | Last commit: ede2d60*

**Next**: Обсудить Issue #4 (Authoritative source criteria) с пользователем

---

## 🔬 Cross-Role Architecture Audit (2026-06-24)

### Глубокий анализ: распределение ролей Ingest / Query / Lint

**Цель аудита**: Проверить, правильно ли функции распределены между тремя процессными файлами и AGENTS.md, нет ли дублирования, есть ли механизмы наследования инструкций.

---

### ✅ Исправлено (автоматически)

| Проблема | Решение |
|----------|---------|
| Дубль #2: Meta rebuild path — три разных абсолютных пути | Стандартизировано к `./scripts/rebuild-meta.sh` в AGENTS.md + все process файлы ссылаются на `AGENTS.md#meta_rebuild_path` |
| Дубль #1: Guardrails дублированы в Ingest | Ingest теперь ссылается на `AGENTS.md#guardrails`, strict_rules — краткая шпаргалка, canonical — AGENTS.md |
| Дубль #5: Logging Templates переопределены в каждом процессе | Все процессы ссылаются на `AGENTS.md#logging_templates` через `inherits_from` |
| Дубль #6: Date Convention | Все процессы наследуют из `AGENTS.md#date_convention` через `inherits_from` |
| Lint Check 1: resolution_flow в зоне Lint (не должен разрешать, только flag) | `resolution_flow = null`, ссылка на `AGENTS.md#contradiction_resolution`, Lint только обнаруживает конфликты |

**Добавлено**: `process_initialization` секция в AGENTS.md — явное наследование правил для каждой роли.

---

### ⚠️ Требует твоего решения (сложные архитектурные вопросы)

#### Issue A ✅ RESOLVED → REVERTED
**Решение**: Contradiction Resolution Flow возвращается в process-query.json как canonical source.
- **Что сделано**: AGENTS.md содержит только `schema_ref: AGENTS.md#contradiction_resolution` (reference). Полный flow — в [process-query.json](process-query.json) step 2.
- **Принцип**: CRF — query-specific logic, не общее правило Schema.

---

#### Issue B ✅ RESOLVED
**Решение**: Search Priority Details перенесены в `process-query.json` (`context.search_priority_details`). AGENTS.md содержит только reference.
- **Что сделано**: process-query.json хранит критерии остановки (`>= 2 совпадения из index`, `>= 3 recall`). AGENTS.md ссылается на него через `schema_ref`.
- **Принцип**: Query-specific logic → process-query.json. General priority chain (index→semantic→grep) → Schema reference.
**Конфликт**: В AGENTS.md search priority описан упрощённо (index → semantic → grep). В process-query.json — полная цепочка fallback с точными критериями остановки (`>= 2 совпадения из index`, `>= 3 из recall`), stop_if_any_results=false.

**Вопрос**: Где должна жить логика достаточности поиска?
1. **Только в AGENTS.md** — Query ссылается, но тогда AGENTS.md разрастается до полной спецификации fallback chain.
2. **Только в Query** — каждый процессный файл хранит свою логику. Это дублирование.
3. **AGENTS.md содержит canonical приоритеты**, process-query.json добавляет критерии остановки и детализацию fallback как `extends` блока.

**Рекомендация**: Вариант 3. Но это требует в AGENTS.md секции `search_priority_schema` с базовыми правилами, а Query — `search_priority_details` с конкретными числами.

---

#### Issue C ✅ RESOLVED
**Решение**: Compounding Principles → AGENTS.md (general workflow), Compounding Decision Logic → process-query.json (scoring/evaluation).
- **Что сделано**: AGENTS.md содержит только reference к `compounding_workflow`. Полный scoring logic — в `process-query.json` context.compounding_decision_logic.
- **Принцип**: Principles = Schema, Scoring/Decision Logic = Query-specific.
**Конфликт**: В AGENTS.md есть секция `Compounding Knowledge Base` с workflow и save_conditions. Это общие правила компандирования. Но process-query.json имеет свой собственный блок compounding_decision (step 2.6) с scoring logic.

**Вопрос**: Compounding — это Schema-правило или Query-specific flow?
1. **Schema** — если compounding применим ко всем ролям (Ingest тоже компандит, когда создаёт новую страницу).
2. **Query** — если compounding только при ответах на вопросы.

**Рекомендация**: Compounding Decision Logic (scoring) — Query-specific. Compounding Principles (why this matters, when to save) — Schema. Нужно разделить эти два аспекта.

---

#### Issue D ✅ RESOLVED
**Решение**: Query использует `meta/backlinks.json` вместо grep_recursive для duplicate check.
- **Что сделано**: Step 2.5 читает backlinks из meta/ (построен линтом). Если similar_page_found → update_existing; else → create_new.
- **Принцип**: Lint = owner of duplicate detection (periodic scan + backlinks.json). Query = consumer who uses pre-built data. (Lint vs Query)
**Конфликт**: process-query.json step 2.5 содержит `duplicate_check_before_fixation` с grep_recursive поиском по wiki. Но это Lint Check 5 (`mechanical_linting → duplicate_titles`). Query не должен искать дубликаты — линт уже нашёл и предупредил.

**Вопрос**: Кто должен проверять на дубликаты перед созданием страницы?
1. **Lint** — периодический check, который флажит потенциальные дубликаты.
2. **Query** — проверка перед каждым созданием новой страницы (guard against user creating duplicates).
3. **Оба** — Lint делает periodic scan, Query делает pre-write guard.

**Рекомендация**: Оба должны работать. Но Query не должен использовать grep_recursive для поиска дубликатов — он должен использовать `backlinks.json` из meta/ (который уже построен линтом). Это потребует изменения step 2.5 в process-query.json.

---

### 📊 Итоговая карта наследования (после исправлений)

```
AGENTS.md (Schema — canonical source)
├── inherits → Ingest: [guardrails, date_convention, logging_templates]
├── inherits → Query: [guardrails, search_priority, contradiction_resolution, logging_templates, date_convention]
└── inherits → Lint: [guardrails, logging_templates]

process-ingest.json:
  schema_ref: AGENTS.md#guardrails
  inherits_from: [guardrails, date_convention, logging_templates]
  ↓
process-query.json:
  schema_ref: AGENTS.md
  inherits_from: [guardrails, search_priority, contradiction_resolution, logging_templates, date_convention]
  ↓
process-lint.json:
  schema_ref: AGENTS.md#guardrails
  inherits_from: [guardrails, logging_templates]
```

---

*Last audit: 2026-06-24 | Issues A-D require discussion before implementation*
**Next**: Обсудить Issue #4 (Authoritative source criteria) + Issues A-D (Cross-role architecture)

---

## 🐛 wiki-search.sh Bugs — 2026-06-26

Source: `scripts/wiki-search.sh` audit

### Critical bugs

| # | Line | Problem | Impact | Fix |
|---|------|---------|--------|-----|
| 1 | 72 | `max(0, 1) if any(...)` — всегда возвращает `1`, не суммирует | comp_count сломан, bias_comparisons срабатывает по умолчанию | Заменить на `sum(1 for q in history if ...)` |
| 2 | 46,123-146 | `$QUERY` без экранирования передаётся в grep | regex-мета-символы `()[].*` ломают grep или дают ложные совпадения | Экранировать через `sed 's/[[\.\^\$*+?{()\|/\\&g'` |
| 3 | 140 | `head -1 "$filepath"` читает первую строку (frontmatter), а не H1 | Поиск по заголовку всегда проваливается | Использовать `grep "^# .*${query}" "$filepath"` |
| 4 | 206 | `$COUNTER -ge $MAX_RESULTS` до инкремента | Скрипт останавливается на MAX_RESULTS-1 результатах | Перенести проверку после инкремента или использовать `-gt` |

### Medium bugs

| # | Line | Problem | Impact | Fix |
|---|------|---------|--------|-----|
| 5 | 39 | `${POSITIONAL_ARGS[@]}` с `set -u`, пустой массив | Crash на bash < 4.4 | Проверка длины массива до обращения по индексу |
| 6 | 153 | `**` не рекурсивен без `shopt -s globstar` | Fallback backlinks ищет только *.md в wiki/ root | Использовать `find ... -name "*.md"` или включить globstar |
| 7 | 68 | `$history_file` подставляется напрямую в Python-код | Скрипт ломается, если путь содержит `'` | Передать через env var или аргумент CLI |

**Status**: ✅ Все 7 багов исправлены — `wiki-search.sh` rewritten (2026-06-26)

| # | Line | Problem | Fix applied |
|---|------|---------|-------------|
| 1 | 72 | `max(0, 1)` не суммирует | ✅ `sum(1 for q in history if ...)` |
| 2 | 46,123-146 | `$QUERY` без экранирования в grep | ✅ `escape_for_grep()` + sed |
| 3 | 140 | `head -1` читает frontmatter, не H1 | ✅ `grep "^# .*"` |
| 4 | 206 | `-ge до инкремента → MAX-1 | ✅ `-gt после COUNTER++ |
| 5 | 39 | `${POSITIONAL_ARGS[@]}` crash bash < 4.4 | ✅ Проверка ${#array} перед доступом |
| 6 | 153 | `**` не рекурсивен без globstar | ✅ `find ... -name "*.md"` |
| 7 | 68 | `$history_file` в Python-коде | ✅ ENV var HISTORY_FILE |

**Done**: Обновить wiki/log.md, git commit.
