# AGENTS.md — Wiki Schema & Conventions

## 📋 Overview

Данный документ определяет структуру, конвенции и рабочие процессы wiki. Он служит единственным источником истины о том, как агент должен оперировать при:
- Ингесте новых источников
- Ответе на вопросы через базу знаний
- Поддержании и health-checkwiki

Schema **co-evolves** по мере работы с пользователем — обновляется вместе с опытом.

---

## 🛠 Code Conventions (Development)

Для работы над логикой, скриптами и инфраструктурой проекта действуют отдельные правила: [RULES.md](../RULES.md) — системный регламент разработки кода. Используется временно, на период написания и отладки скриптов.

---

## 🏗 Architecture Layers

### 1. Raw Sources (`raw/`)
* Immutable коллекция оригинальных документов, статей, изображений, данных
* Агент читает из них, но не модифицирует напрямую
* Write-доступ ограничен через `scripts/validate-path.sh` guardrails
* Все изменения только через: capture → integrate flow (никогда прямые правки)

### 2. The Wiki (`wiki/`)
* Каталог LLM-generated markdown-файлов, организованная по типам
* Агент владеет этим слоем полностью — создаёт страницы, обновляет их, поддерживает cross-references
* Пользователь читает; агент пишет и поддерживает

```json
{
  "structure": {
    "entities/": "конкретные идентифицируемые объекты (люди, компании, технологии)",
    "concepts/": "абстрактные идеи, принципы, методологии",
    "comparisons/": "сравнительный анализ сущностей и концептов",
    "syntheses/": "глубокий анализ, объединяющий несколько источников/страниц",
    "notes/": "личные заметки, транскрипты встреч, наблюдения",
    "meetings/": "встречи с решениями",
    "projects/": "проекты со статусом и вехами",
    "bibliography/": "книги, статьи, исследования",
    "resources/": "инструменты, плагины, библиотеки",
    "snapshot.md": "одностраничный срез актуальных фактов из всех страниц wiki (см. ниже)"
  }
}
```

### 3. Schema (this document)
* Определяет структуру wiki, конвенции и рабочие процессы
* Делает агента дисциплинированным хранителем wiki, а не общим чат-ботом
* Co-evolves между человеком и агентом по оригинальной идее Karpathy

### 4. Context Bridge (`working_memory.json`)
* Файл-мост между сессиями — сохраняет фокус, open_pages, dead_ends, next_steps_todo
* Агент читает при старте сессии → перезаписывает при завершении
* **Clear & Rewrite Rule**: Never append to JSON files. Always read the entire file → modify in memory → write back the complete document.
  - Это предотвращает дубликаты ключей, которые возникают когда agent пишет поверх старого содержимого без очистки.
  - Пример: если `focus_node` меняет значение — agent должен полностью перезаписать файл, а не просто добавить новый ключ поверх.
* Не дублирует wiki — хранит только метаданные сессии (не сами страницы)

**Формат**:
```json
{
  "last_updated": "YYYY-MM-DDTHH:MM:SS+TZ",
  "current_mode": "query | ingest | discussion | project | lint",
  "focus_node": "[page_name] — что агент делает прямо сейчас",
  "open_pages": [
    {"path": "wiki/entities/pi-coding-agent.md", "status": "reading" | "updating"}
  ],
  "dead_ends": [
    {"approach": "grep по всем wiki", "reason": "слишком много шума, index.md работает лучше"}
  ],
  "query_summary": {
    "intent": "Что искал пользователь",
    "pages_read": ["список прочитанных страниц"],
    "key_findings": ["3-5 пунктов"]
  },
  "next_steps_todo": [
    {"task": "Создать synthesis по RAG vs LLM Wiki Pattern", "priority": "high"}
  ]
}
```

---

## 📄 Page Templates

Форматы страниц описаны в процессных файлах:
- **Entity**: `process-ingest.json#entity_template`
- **Concept**: `process-ingest.json#concept_template`
- **Comparison/Synthesis**: `process-query.json#synthesis_flow`

**Frontmatter required fields enforced by**: `lint.sh check_id=5` (missing_frontmatter).

---

### Wiki Snapshot (`wiki/snapshot.md`)

```json
{
  "format": {
    "title": "# Wiki Snapshot — Активные проекты",
    "description": "Одностраничный файл для проектного контекста — перечень активных проектов пользователя и связанных с ними wiki-страниц.",
    "structure": {
      "header": "# Wiki Snapshot — Активные проекты",
      "sections": [
        {"name": "## Active Projects", "type": "project_list"},
        {"name": "### [Название проекта]", "properties": ["status: active/completed/on-hold", "context: brief project goal and current status", "related_pages: links to Entity/Concept pages"]},
        {"name": "---\\n*Last updated: YYYY-MM-DD*", "type": "footer"}
      ]
    },
    "load_conditions": {
      "read_when": "WORK_MODE is project and snapshot contains entry for this project",
      "never_read": ["oneoff questions", "deep-dive study (query/discussion modes)"]
    },
    "update_rules": [
      {"action": "create", "trigger": "user declares new project"},
      {"action": "update", "trigger": "every ingest/query that adds or changes related wiki pages"},
      {"action": "archive", "trigger": "project completed — entry moved to wiki/projects/, removed from snapshot.md"}
    ],
    "rule": "agent never loads snapshot.md if user is not working on a project. session starts with index.md + overview.md."
  }
}
```

---

## 🔖 Git Conventions

- **Commit format**: `<type> | <scope>: <description>` (type: ingest/query/lint/schema/fix; description lowercase)
- **Allowed**: `git status --short`, `git add wiki/`, `git rm --cached`
- **Prohibited**: `git add *` (system junk), `git commit -a` (no staged commits)

> Full guardrails enforced by `.git/hooks/pre-commit` + `scripts/validate-path.sh`.

---

## 🧠 User Work Modes (Schema-уровень)

Эти режимы определяют, как агент управляет контекстом при различных типах пользовательских запросов.

### Как агент определяет [WORK_MODE: project]

Агент **не ждёт явного маркера** — он сам определяет режим по контексту задачи. Три пути:

| Способ | Когда срабатывает | Пример |
|--------|------------------|--------|
| **Прямая инструкция пользователя** | Пользователь явно говорит «работаю над проектом» или ставит маркер | `[WORK_MODE: project]` в запросе |
| **Контекст задачи** | Агент понимает по формулировке, что это итеративная работа | «Мигрирую auth на JWT → какие схемы token rotation?» |
| **Уточняющий вопрос** | Агент не уверен → спрашивает пользователя | «Это одноразовый вопрос или часть проекта?» |

### Управление признаками режима:
1. Если агент определяет проект (итеративная работа с wiki как источником контекста):
   - Ставит `current_mode = "project"` в `working_memory.json`
   - Обновляет `wiki/snapshot.md` — добавляет проект в Active Projects
   - Подгружает snapshot.md при следующих вызовах
2. Явный маркер `[WORK_MODE: project]` → принимает немедленно.
3. Неоднозначный контекст → уточняет у пользователя.

**Правило**: агент сам управляет режимом работы — гибкий механизм, основанный на контексте, прямой инструкции или уточнении.

---

### 1. Одноразовый вопрос-справка
- **Контекст**: короткий факт, определение, сравнение двух терминов.
- **Политика**: Compaction=true после ответа. Dismiss всех прочитанных страниц (кроме snapshot).
- **Новая сессия**: false — контекст не переносится, агент начинает с snapshot.md

### 2. Deep-dive изучение темы
- **Контекст**: несколько итераций вопрос→ответ→уточнение→новый вопрос.
- **Политика**: Compaction=false (режим discussion). Удерживать все предыдущие вопросы/ответы.
- **Новая сессия**: true — предыдущий контекст переносится в working_memory.json

### 3. Дискуссия / обсуждение
- **Контекст**: пользователь строит аргументацию, агент участвует в debate.
- **Политика**: Удерживать всё до topic-switch маркера. Никакая компактификация.
- **Новая сессия**: true — весь контекст дискуссии переносится в working_memory.json

### 4. Работа над проектом
- **Контекст**: итеративная разработка, wiki — источник контекста (решения по архитектуре).
- **Политика**: Partial compaction — выгружать tool results, держать project state.
- **Новая сессия**: true — проектный контекст переносится через working_memory.json

### 5. Синтез / создание новой страницы wiki по query-результату
- **Контекст**: ответ на вопрос содержит novel insight → агент предлагает сохранить как новую страницу.
- **Политика**: Compaction=false до момента fixation страницы в wiki.
- **Новая сессия**: false — контекст не переносится, агент начинает с snapshot.md

**Технические вызовы (Ingest / Lint)**:
- Вызов из Ingest: FLUSH_RAWS после извлечения, читать только страницы для обновления.
- Вызов из Lint: агент НЕ читает wiki напрямую — только отчёт из bash/Python скрипта.

---

## 🧠 Memory Architecture Contract (системные правила)

Эти контракты определяют, как агент управляет памятью и читает файлы через bash.

### CONTEXT_BUBBLE & GREP CONTRACT
- **CONTEXT_BUBBLE**: не более 3 активных страниц в контексте одновременно.
- **GREP CONTRACT**: используем только разрешённые паттерны bash (см. `process-query.json#grep_contract`).
> Canonical: `process-query.json#context_bubble` + `process-query.json#grep_contract`.

---

## 🔧 Error Handling Protocol

При обнаружении любой ошибки, противоречия или dead end — **не зависать**, а следовать шагам:

### 4-step loop

1. **Detect & Log** `[!]` → Записать в `log.md` с типом `[error]`, описанием и контекстом
2. **Analyze** → Краткий анализ: что пошло не так, почему инструкция сломалась (не просто «ошибка», а корень проблемы)
3. **Resolve** → Выбрать стратегию:
   - `local-fix`: проблема локальная (путь, ссылка, логика) → исправить самостоятельно
   - `schema-patch`: противоречие в Schema/AGENTS.md → предложить патч пользователю на review
   - `source-conflict`: два источника говорят противоположное → отметить как `CONFLICT` на странице и продолжить
   - `dead-end`: подход не работает (например, grep дал шум) → документировать причину, сменить стратегию
4. **Continue** → Двигаться дальше по task, не застревая на сломанной инструкции

### Примеры применения

| Ситуация | Действие |
|----------|----------|
| `git add *` заблокирован guardrails | `[!] Log: protected zone blocked` → `local-fix: switch to git add wiki/` |
| fetch_content вернул обрезанный markdown | `[!] Log: truncation detected` → `local-fix: fallback web_search + get_search_content` |
| Новая команда несовместима с текущей Schema | `[!] Log: schema conflict` → `schema-patch: предложить патч AGENTS.md` |
| Grep дал >100 совпадений без смысла | `[!] Log: grep noise` → `dead-end: switch to index.md` |

### Правило

> **Ошибка ≠ стоп.** Каждый error — сигнал к действию, а не причина зависать. Агент фиксирует, анализирует, решает и двигается дальше.

---

## 🔄 Process Roles

Каждая роль — отдельный процессный файл в корневой директории.
AGENTS.md содержит только описание ролей и ссылки на их workflow details.

| Роль | Файл | Описание |
|------|------|----------|
| Ingest | [process-ingest.json](process-ingest.json) | Ингест новых источников: capture → integrate |
| Query | [process-query.json](process-query.json) | Ответы на вопросы через базу знаний, синтез, compounding |
| Lint | [process-lint.json](process-lint.json) | Периодическая проверка здоровья wiki — **non-blocking** через `scripts/lint.sh` |

Каждая роль наследует общие правила из AGENTS.md (guardrails, date_convention, logging_templates).
Полный workflow каждой роли — в соответствующем файле.

### Phase 3: Non-blocking Lint
- **Entry point**: `scripts/lint.sh` — единый скрипт для всех lint-checks
- **Не блокирует agent turn**: запускается отдельно (можно по cron)
- **Output**: stdout = JSON отчёт, stderr = human-readable summary
- **Process-lint.json** ссылается на этот скрипт вместо inline выполнения отдельных проверок
- **Schema ref**: `AGENTS.md#non-blocking-lint`

## 🔗 Link Conventions & Auto-Fix

- **Format**: `[text](wiki-relative-path.md)` (no `../`, no `./`)
- **Post-operation validation**: after create/rename/delete → call `./scripts/link-validator.sh --full`
- **Auto-fix flow**: validate → fix broken links → rebuild meta

> Full workflow: `process-ingest.json#post_operation_link_validation`. Broken link JSON output from validator.

---

## ⚙️ Execution Modes

- **Default**: silent (compact responses)
- **Verbose trigger**: `"давай проверим"`, `"verbose mode"` → returns to silent after 3 turns
- **Logging templates**: defined per-process in process-ingest.json / process-query.json / process-lint.json

---

## 🛡 Rules & Guardrails

### Fetch Content Truncation Handling

```json
{
  "fetch_content_truncation": {
    "condition": "response_markdown_contains '[Content truncated...]' or output is visibly cut off mid-sentence",
    "primary_action": "fallback to web_search(query) + get_search_content(responseId) for complete coverage",
    "secondary_action": "repair base path when copying raw sources — use hierarchical structure: raw/<source_type>/<owner_or_domain>/<repo_name>@<branch_or_version>/",
    "logging_verbose_template": [
      "[!] Fetch truncation detected in X.md, length ~{N} chars",
      "[✓] Fallback activated: web_search + get_search_content called"
    ]
  }
}
```

### Protected Zones

```json
{
  "protected_zones": {
    "raw/**": {"rule": "immutable", "access": "read-only via links"},
    "meta/**": {"rule": "auto-generated", "files": ["registry.json", "backlinks.json"], "rebuild_command": "./scripts/rebuild-meta.sh"}
  },
  "never_do": [
    "directly_edit_protected_zones",
    "skip_capture_flow_for_raw_sources",
    "manually_modify_meta_files"
  ]
}
```

---

## 🔍 Search Strategy

> Canonical flow: `index_lookup → semantic_search → wiki-search.sh` — полный алгоритм в `process-query.json#search_priority_details`.

---

**Schema Reference**: `AGENTS.md#compounding_workflow` → Full workflow defined in [process-query.json](process-query.json). Compounding decision logic is query-specific.
---





## 📅 Date Convention Rule

- Frontmatter `date` = **current system date** (never derive from source filename / git commit dates)
- Log entries: `## [YYYY-MM-DD] action | description`
- Timestamps in JSON: ISO-8601 `YYYY-MM-DDTHH:MM:SS+TZ`

> Enforced by: `lint.sh check_id=6` (date_consistency_check).

---

## 🔄 Schema Inheritance

Process files inherit from AGENTS.md via `schema_ref` (never duplicate rules).

### Canonical References
| Reference | Path |
|-----------|------|
| Meta rebuild | `./scripts/rebuild-meta.sh` |
| Search priority | `process-query.json#search_priority_details` |
| Lint script | `./scripts/lint.sh` |
| Contradiction resolution | `process-query.json#contradiction_resolution_flow → authoritative > temporal > user_review` |

> Rule: never duplicate AGENTS.md rules in process files. Always add `schema_ref` for canonical source.

---

## 🔧 Auto-Rebuild Metadata

`./scripts/rebuild-meta.sh` → rebuilds all meta files (`registry.json` + `backlinks.json` + `index.md`)

`--index-only` flag → rebuilds only `wiki/index.md` (H1 headers + first sentences per category)

**Trigger points**: After any wiki edit in Ingest / Query / Lint processes.

> Full integration flow: `process-ingest.json#step_3a` (full), `process-query.json#post_check`, `process-lint.json#check_id_7`

---

## 📄 Auto-update Index

`./scripts/rebuild-meta.sh --index-only` → rebuilds `wiki/index.md` (H1 headers + first sentences per category)

**Trigger**: Ingest process after create_page/update_existing. Lint after link_validation.

> Logic details: script parses wiki/**/*.md, groups by subdirectory, sorts alphabetically.

---

## 🔄 Non-blocking Lint (Phase 3)

`scripts/lint.sh` — автономный скрипт lint-аудита, который не блокирует agent turn.

### Когда вызывается

| Процесс | Триггер |
|---------|----------|
| **Самостоятельно** | `./scripts/lint.sh [--quiet] [--skip-checks ID1,ID2]` — можно запустить отдельно или по cron |
| **Process-lint** | Вместо inline lint → вызывать `./scripts/lint.sh --quiet` |

### Как использовать
```bash
# Полная проверка (stdout = JSON отчёт, stderr = human-readable)
cd /path/to/loomana && ./scripts/lint.sh

# Тихий режим (только JSON на stdout, без вывода в stderr)
cd /path/to/loomana && ./scripts/lint.sh --quiet

# Пропуск конкретных проверок
cd /path/to/loomana && ./scripts/lint.sh --skip-checks 3,5
```

### Output формат (JSON на stdout)
```json
{
  "timestamp": "YYYY-MM-DDTHH:MM:SS",
  "wiki_dir": "wiki/",
  "checks_run": 7,
  "issues_found": {
    "contradictions": 0,
    "orphan_pages": 3,
    "new_sources_unprocessed": 5,
    "duplicate_titles": 0,
    "date_inconsistencies": 0,
    "broken_links": 2
  },
  "total_issues": 10,
  "status": "ISSUES_FOUND"
}
```

### Checks выполняемые скриптом
| Check ID | Название | Скрипт | Результат |
|----------|----------|--------|-----------|
| 1 | Contradictions | Soft scan `## Обновлено` | Agent review required |
| 2 | Orphan pages | `orphan-pages.sh` | List of orphans |
| 3 | New sources | `check-new-sources.sh` | Unprocessed packages list |
| 4 | Knowledge gaps | — | Skipped (soft check) |
| 5 | Duplicate titles | `duplicate-titles.sh` | Count of duplicates |
| 6 | Date consistency | `date-consistency.sh` | Inconsistencies count |
| 7 | Broken links | `link-validator.sh --full` | JSON of broken links |

### Почему это важно
- **Не блокирует agent turn**: lint работает отдельно, не требует inline выполнения
- **Масштабируемость**: можно запускать по cron (например, каждые 4 часа)
- **Single entry point**: все проверки в одном скрипте → простой вызов из любого процесса
- **JSON output для machine parsing**: stdout = структурированный отчёт, stderr = человеко-читаемый

### Cron example (optional)
```bash
# crontab -e — автоматический lint каждые N часов
0 */4 * * * cd /path/to/loomana && ./scripts/lint.sh --quiet >> logs/lint.log 2>&1
```

---

*Schema Version: 8 | Last Updated: 2026-06-26 | Author Pattern: Andrej Karpathy (LLM Wiki)*

---

## 🎯 Dynamic Priority + Relevance Scoring (Phase 5)

`scripts/wiki-search.sh --dynamic "query"` — динамический порядок категорий по query intent.

**Query Intent Analysis**:
- Entity keywords → `entities/`, `concepts/`, `syntheses/` priority
- Comparison keywords (`vs`, `compared to`) → `comparisons/`, `syntheses/`, `concept/` priority  
- Concept keywords → `concepts/`, `syntheses/`, `entities/` priority
- Fallback: static priority (syntheses→concepts→entities)

**Relevance Scoring**:
1. Position weight: query in H1 = +3, body = +1 per occurrence
2. Frequency weight: total occurrences × 1
3. Backlink weight: mentions in other wiki pages × 5
4. Category bonus: earlier priority category gets +10×(max_priority - index)

**Usage**: `./scripts/wiki-search.sh --dynamic "query"` — results sorted by combined score descending.

> Full workflow: `AGENTS.md#smart_search_priority` → extended with dynamic intent analysis.
