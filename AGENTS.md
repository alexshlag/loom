# Loomana: Wiki Schema, Agent Instructions & Conventions

## Что это такое

Это **LLM-powered personal knowledge base** — база знаний, которая растёт с каждым источником и вопросом. Полное имя проекта: `Loomana`; короткое название: `loom`.

_Идея: [Andrej Karpathy](https://karpathy.ai/). Референс: [LLM Wiki gist](https://gist.github.com/karpathy/ed8f284379605148297b7a8be01eb580)._

---

## 📋 Overview

Данный документ определяет структуру, конвенции и рабочие процессы wiki. Он служит единственным источником истины о том, как агент должен оперировать при:

- Ингесте новых источников
- Ответе на вопросы через базу знаний
- Поддержании и health-checkwiki

This Schema **co-evolves** по мере работы с пользователем, обновляется вместе с опытом.

---

## 🧠 Context Management — All Rules Transient (Phase 32)

### Why This Matters

AGENTS.md и process-файлы (`process-ingest.json`, `process-query.json`, `process-lint.json`) вместе занимают ~86KB. Это избыточный контекст сессии.

**Проблема**: Agent сохраняет в контексте все rules даже после завершения процесса → bloat memory.

**Решение**: ALL rules are Transient — read fresh from source before every action. No persistent memory needed because:
- `agent_read_instructions` in each process file mandates reading AGENTS.md before execution
- This guarantees context refresh at EVERY process start, regardless of when session began

### How It Works (v2.0)

```json
{
  "scope_definition": "rules/context-scopes.json",
  "policy": "ALL rules Transient — read fresh from source files on demand"
}
```

**Agent reads fresh from source files only when needed:**
- AGENTS.md → before EVERY process (auto-read via `agent_read_instructions` in process files)
- Process-specific rules → only during active process, forget after completion
- Hybrid rules (templates, link conventions) → read when actively working on that topic
- NEVER stores any rule content in persistent memory beyond the current turn

### Context Management Rules

1. **Session start**: DO NOT load any rules into persistent memory.
2. **Process start**: Agent MUST read AGENTS.md (per `agent_read_instructions` in process file), then read process-specific transient rules.
3. **Process complete**: Forget all transient rules unless user says "keep this".
4. **Read on demand**: For hybrid rules → read from source only when actively working on that topic.

### Schema Reference

- Full scope definitions: `rules/context-scopes.json` (v2.0)
- Auto-read mechanism in process files: `agent_read_instructions` field mandates AGENTS.md refresh

> Canonical: `AGENTS.md#context_management_phase_32` — agent must follow this rule to prevent context bloat.

### Current Scope Breakdown

**ALL rules are Transient:**
- ✅ Memory contract, execution contract, error handling → read fresh from AGENTS.md
- ✅ Git conventions, protected zones, silent output → read fresh when needed
- ✅ Page templates, link conventions, crosslinks → read on demand
- ✅ Process-specific rules → read only during active process

**Result**: Zero persistent context bloat — agent always reads latest version of every rule.

---

## 📍 Roadmap & Project Plan (Development Mode)

- **[PLAN.md](PLAN.md)** — дорожная карта проекта: статусы фаз, pending phases, integration fixes (IF-1..IF-4), теоретические вопросы. **Всегда читай перед началом работы** — определяет приоритеты и контекст.
- **[FEATURES_PLAN.md](FEATURES_PLAN.md)** — план реализации архитектурных улучшений на основе research (ingest algorithms comparison): advisory locking, background synthesis, contradiction flagging, mode-aware routing, address assignment.
- **[issues.md](issues.md)** — реестр багов и известных проблем. Описываем найденные баги, фиксируем исправления. **Читай issues.md при ingest/query/lint** — чтобы не дублировать известные проблемы и знать об ограничениях системы.

---

## 🛠 Code Conventions (Development)

На период написания и отладки скриптов действует системный регламент разработки кода: [RULES.md](RULES.md).

### Unified-Pass Architecture (Phase 23)

`scripts/unified-pass.sh` — **оркестратор**, а не monolithic merge трёх скриптов:

- **Shared walk**: один `find` по wiki с единым exclude-списком system files
- **Dispatch**: результаты walk передаются в 3 consumer-функции
- **Consumers**: `collect_metadata()` (из rebuild-meta.sh), `validate_links()` (из link-validator.sh), `discover_crosslinks()` (из auto-crosslink.sh)
- **Frontmatter parsing**: единый shared helper (Python) вместо 5 разных regex
- **Output**: каждый consumer может писать JSON в stdout и/или файлы
- **System file exclusion**: единый список, определяется в начале скрипта

> Цель: устранить 3 независимых полных walk поwiki при каждом ingest/lint.

### Memory Sync on Schema Changes (RULES.md#9)

When modifying system files (AGENTS.md, RULES.md, process-*.json, PLAN.md, FEATURES_PLAN.md):
1. `focus_node` = current development task name
2. `next_steps_todo` = remaining tasks from same phase (filter completed)
3. Update hot.md Active Project with Phase status + what was done

> See: [rules/session_context_rules.json](rules/session_context_rules.json) for write_algorithm.

---

## 🔖 Git Conventions

- **Commit format**: `<type> | <scope>: <description>` (type: feat|fix|refactor|schema|lint|ingest|query; description lowercase)
- **Allowed**: `git status --short`, `git add wiki/`, `git rm --cached`
- **Prohibited**: `git add *` (system junk), `git commit -a` (no staged commits)
- Коммит **по запросу пользователя**: `git add -A; git commit -m "<type> | <scope>: <description>"`
- `git add -A` — safe, ignores .gitignore automatically

> Full guardrails enforced by `.git/hooks/pre-commit` + `scripts/validate-path.sh`.

---

## 🔄 Process Roles

- Каждая роль — отдельный процессный файл в корневой директории.
- Каждая роль наследует общие правила из AGENTS.md.

**Полный workflow каждой роли** — в соответствующем файле:

| Роль   | Файл                                       | Описание                                                                        |
| ------ | ------------------------------------------ | ------------------------------------------------------------------------------- |
| Ingest | [process-ingest.json](process-ingest.json) | Ингест новых источников: capture → integrate                                    |
| Query  | [process-query.json](process-query.json)   | Ответы на вопросы через базу знаний, синтез, compounding                        |
| Lint   | [process-lint.json](process-lint.json)     | Периодическая проверка здоровья wiki — **non-blocking** через `scripts/lint.sh` |

---

### Batch Ingest Trigger

Когда агент получает ≥3 связанных источника или пользователь предоставляет несколько файлов: `scripts/batch-ingest.sh --scan` сканирует все файлы, извлекает H1/tags/keywords, группирует по shared entities. Результат → кластеризованный JSON для принятия решения пользователем.

---

## 🏗 Architecture Layers

### 1. Raw Sources (`raw/`)

- Immutable коллекция оригинальных документов, статей, изображений, данных
- Агент читает из них, но не модифицирует напрямую
- Write-доступ ограничен через `scripts/validate-path.sh` guardrails
- Все изменения только через: capture → integrate flow (никогда прямые правки)

### 2. The Wiki (`wiki/`)

- Каталог LLM-generated markdown-файлов, организованная по типам
- Агент владеет этим слоем полностью — создаёт страницы, обновляет их, поддерживает cross-references
- Пользователь читает; агент пишет и поддерживает

```json
{
  "structure": {
    "entities/": "конкретные идентифицируемые объекты (люди, компании, технологии)",
    "concepts/": "абстрактные идеи, принципы, методологии",
    ...
    # Полный список категорий → [rules/categories.json](rules/categories.json) — canonical source
    # Agent читает порядок и лейблы из JSON, не хардкодит
    "assets/images/": "копии оригиналов изображений (.png, .jpg, .jpeg, .gif)",
    "assets/descriptions/": "markdown-описания изображений: OCR + entities + metadata",
    "snapshot.md": "одностраничный срез актуальных фактов из всех страниц wiki (см. ниже)"
  }
}
```

> **Категории под wiki/** перечислены в [rules/categories.json](rules/categories.json). Agent всегда читает их оттуда — никогда не хардкодит.

#### Assets & Media Pipeline (`raw/assets/images/`, `raw/assets/descriptions/`)

Две связанные поддиректории для работы с изображениями:

| Поддиректория              | Назначение                                             | Формат         |
| -------------------------- | ------------------------------------------------------ | -------------- |
| `raw/assets/images/`       | Копии оригиналов изображений (.png, .jpg, .jpeg, .gif) | Бинарные файлы |
| `raw/assets/descriptions/` | Markdown-описания с OCR, entities и metadata           | `.md` файлы    |

**Workflow для ingest изображения:**

1. Изображение копируется в `raw/assets/images/` через capture flow
2. Агент извлекает: OCR текст, определяет entities на изображении, генерирует metadata
3. Описание сохраняется как `.md` в `raw/assets/descriptions/` с именем, соответствующим оригиналу изображения
4. Ссылка на изображение добавляется в wiki-страницу через wikilink: `![[raw/assets/images/filename.png]]`
5. Description file links back to the wiki page via frontmatter `related` field

**Conventions:**

- Имена файлов: snake_case с префиксом контекста (например, `diagram_architecture_overview.png`)
- Description файлы содержат: `[OCR text]`, `[entities detected]`, `[metadata: dimensions, format, date_ingested]`
- Agent auto-generates descriptions при ingest — не требует ручного заполнения

> Canonical: `AGENTS.md#media_pipeline`

### 3. Summary / FAQ Pages (`wiki/syntheses/`)

- Сводные страницы ответов на вопросы — синтез из ≥3 wiki источников, формирующих полное освещение конкретной темы
- **Приоритет в поиске**: syntheses/ → concepts/ → entities/ (FAQ-слое ищет в первую очередь)
- Агент управляет этим слоем автономно: создаёт, объединяет, разбивает, удаляет устаревшие страницы

**Creation Trigger**:
| Сценарий | Действие агента |
|----------|------------------|
| Ответ агрегирует из **≥3 wiki страниц** | ✅ Auto-create summary page в syntheses/, выстроить внутренние связи (crosslinks), добавить внешние источники через ingest flow |
| Ответ из интернета (web_search) | ⚠️ Предложить пользователю создать FAQ-страницу. Если согласен → full ingest + links |
| Ответ из 1-2 источников, без нового вывода | ❌ Не создавать summary — просто ответить, возможно добавить в existing entity/concept |

**Lifecycle Rules**:
| Событие | Действие |
|---------|----------|
| Два summary охватывают одну тему | Merge → одна страница, старые links обновлены на новую |
| Summary устарела (last_seen > 30 дней без запросов) | Decay: -50% popularity boost. Agent может объединить в более свежую страницу или удалить если дубль |
| Новый query → другой top_path для same topic | Update existing summary + last_seen = current, popularity_score++ |
| Summary page требует user approval (external sources) | ⚠️ Не создавать без explicit confirmation от пользователя |

**Frontmatter type for FAQ pages**:

```yaml
---
tags: [summary, faq, ...]
date: YYYY-MM-DD
type: faq_summary # ← явно маркировать как ответ на вопрос
sources: [...]
related: []
---
```

> Canonical: `AGENTS.md#summary_pages` — agent must set type=faq_summary для всех summary pages.

### 4. Schema (this document)

- Определяет структуру wiki, конвенции и рабочие процессы
- Делает агента дисциплинированным хранителем wiki, а не общим чат-ботом
- Co-evolves между человеком и агентом по оригинальной идее Karpathy

### 5. Context Bridge (`working_memory.json`)

- Файл-мост между сессиями — сохраняет фокус, open_pages, dead_ends, next_steps_todo
- Агент читает при старте сессии → перезаписывает при завершении
- **Clear & Rewrite Rule**: Never append to JSON files. Always read the entire file → modify in memory → write back the complete document.
  - Это предотвращает дубликаты ключей, которые возникают когда agent пишет поверх старого содержимого без очистки.
  - Пример: если `focus_node` меняет значение — agent должен полностью перезаписать файл, а не просто добавить новый ключ поверх.
- **Auto-cleanup Rule**: Перед каждым write() в working_memory.json agent обязан отфильтровать из массивов выполненные/устаревшие элементы. Никогда не append-ить к существующим массивам без очистки.
  - `next_steps_todo`: удалять задачи со статусом `completed` или которые больше не актуальны
  - `broken_links_resolved`: **не удалять** — это audit trail, добавляет новую запись сверху
  - `open_pages`, `dead_ends`: чистить после закрытия сессии (dismiss всех прочитанных)
  - Пример: если агент выполнил задачу "unified-pass.sh --full", он должен удалить её из `next_steps_todo` перед write()
- Не дублирует wiki — хранит только метаданные сессии (не сами страницы)

**Canonical rules source**: `rules/session_context_rules.json` определяет полный алгоритм работы с memory layers (working_memory.json, hot.md, log.md), save_triggers, и read_algorithm. Агент читает этот файл перед каждым действием с памятью.

> Schema ref: `AGENTS.md#context_bridge`. Canonical: `rules/session_context_rules.json`.

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

### 6. Agent Rules & Conventions (`rules/`)

- Директория технических спецификаций и «нишевых» инструкций, вынесенных из AGENTS.md для снижения контекстного бloat.
- Формат: **JSON предпочтителен** (машинно-читаемый), но допустимы `.md` файлы когда структура требует текстового описания.
- Содержит правила: `protected_zones.json`, `error_handling.json`, `execution_contract.json`, `link_conventions.json`, `search_strategy.json`, `tag-guidelines.json`, `session_context_rules.json` и другие.
- AGENTS.md содержит ссылки (`schema_ref`) на эти файлы вместо дублирования — агент читает правило только когда ему нужно его применение.

---

## 🔁 External Sources Update Policy (Issues #1-3 resolved)

### Issue #1: Как часто обновлять wiki из внешних источников?

**Решение**: Два режима обновления:

| Режим              | Триггер                                                          | Описание                                                                                              |
| ------------------ | ---------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| **User-requested** | Пользователь явно просит «обнови X» или «проверь актуальность Y» | Агент делает `web_search` → сравнивает с текущими данными → обновляет страницу если данные изменились |
| **Cron (default)** | Автоматически по расписанию                                      | Lint-скрипт запускает `check-new-sources.sh` + periodic refresh wiki-страниц без запроса пользователя |

**Правило**: Агент никогда не делает `web_search` для обновления wiki в обычном режиме. Только по явному запросу пользователя или cron.

### Issue #2: Когда `web_search` приоритетнее внутренних данных?

**Решение**:

| Сценарий                                                    | Приоритет                                                                    |
| ----------------------------------------------------------- | ---------------------------------------------------------------------------- |
| **Тот же источник** (тот же URL/домен) но данные изменились | ✅ Внешние данные приоритетны — обновить wiki                                |
| **Разные источники** противоречат друг другу                | ⚠️ Перейти к Issue #4 (Authoritative Source Criteria) — отдельное обсуждение |
| **Факты vs мнения**                                         | Факты → web_search. Мнения/аргументы → хранить в wiki как есть               |

**Правило**: Если `web_search` из того же источника, что и текущая страница wiki, но данные изменились — внешние данные имеют приоритет.

### Issue #3: Критерий "novel insight"

**Решение**: Чёткие критерии вместо субъективного определения:

| Тип                            | Критерий                                                                                             | Действие                                                |
| ------------------------------ | ---------------------------------------------------------------------------------------------------- | ------------------------------------------------------- |
| **Синтез фактов**              | Сбор фактов из 2+ источников без нового вывода                                                       | ❌ Не создавать новую страницу, добавить в существующую |
| **Новый вывод**                | Агент делает логический шаг, который не был явно stated ни в одном источнике (например: «A + B → C») | ✅ Flag for fixation, предложить создать страницу       |
| **Контекстуальное применение** | Формулирует как применить известные концепты к текущему контексту пользователя                       | ⚠️ Заметки/notes, не новая wiki-страница                |

**Правило**: Novel insight = новый логический вывод (не сбор фактов). Агент должен уметь объяснить: «Какие данные → какой вывод?» Если цепочка прозрачна и все шаги из источников — это synthesis, не novel insight.

---

## 📄 Page Templates

### ⚠️ Global Rule: Template Editing Policy

> **Запрещено свободное редактирование общих шаблонов.** Любые изменения в секции `Шаблоны страниц` или их структурных элементах требуют согласования с пользователем.
>
> Все шаблоны — shared contract между агентом и пользователем. Agent может предлагать улучшения через `[schema-patch]`, но не применять самостоятельно.

---

### 📋 Universal Frontmatter (All Types)

**Обязательная секция для всех типов документов.** Machine-readable metadata, единообразна независимо от типа страницы.

```yaml
---
tags: [] # recommended keyword-теги для классификации и поиска — см. rules/tag-guidelines.json
date: YYYY-MM-DD # текущая дата системы (не из источника!)
type: documentation # reality layer: documentation | code_reality | live_state
category: entity # раздел wiki: entity | concept | synthesis | comparison | note | project | bibliography | resource
aliases: [] # discoverability synonyms — слова которые user печатает в query, см. rules/tag-guidelines.json#aliases_system
sources: [] # откуда данные (raw/..., wiki paths, web_search)
related: [] # связанные wiki-страницы (wiki-relative paths)
---
```

**Fields:**
| Field | Required | Description |
|-------|----------|-------------|
| `tags` | ✅ | Recommended массив keyword-тегов (3-7 тегов) для классификации, поиска и систематизации. Agent получает recommended patterns из `rules/tag-guidelines.json`. Без generic tags — доменные тега обязательны. Примеры: `symfony`, `hexagonal-architecture`, `doctrine`, `phpunit` (не `entity/concept`). |
| `date` | ✅ | Текущая дата системы в формате YYYY-MM-DD. Никогда не берётся из имени файла или комита источника. |
| `type` | ✅ | Reality layer — уровень достоверности данных: `documentation` (docs/articles/blogs), `code_reality` (machine-verifiable code, GitHub issues/PRs), `live_state` (ephemeral metrics, API responses, logs). Используется в cascade-алгоритме разрешения противоречий. |
| `category` | ✅ | Раздел wiki, к которому относится страница: `entity`, `concept`, `synthesis`, `comparison`, `note`, `project`, `bibliography`, `resource`. Определяет куда поставить страницу (entities/, concepts/, syntheses/, comparisons/). |
| `aliases` | ⚠️ Recommended | Массив discoverability-синонимов — слова которые user реально печатает в query. Включайте product names, synonyms, author references, bilingual variants (EN/RU). Never put architecture terms as aliases. Canonical: `rules/tag-guidelines.json#aliases_system`. |
| `sources` | ✅ | Список источников данных: raw source paths, wiki-relative paths, или `web_search` marker. Может содержать любые источники — не только raw/. |
| `related` | ✅ | Массив wiki-relative путей к связанным страницам (например: `[wiki/entities/symfony.md]`). Пустой массив означает «нет связей». |

---

### 🔍 Auto-computed Fields (Agent-level)

Некоторые поля вычисляются автоматически агентом при ingest — не требуют ручного заполнения.

#### `evidence_grade` — уровень доказательности фактов

**Когда применяется:** Только для источников с `type: documentation`. Для `code_reality` и `live_state` — авто-статус `documented` (машинная верификация = высокий grade).

| Grade            | Когда ставить                                                                          | Значение                    |
| ---------------- | -------------------------------------------------------------------------------------- | --------------------------- |
| `documented`     | Факт из авторитетного источника (официальная docs, wiki проекта, blog core-maintainer) | Высокая уверенность         |
| `corroborated`   | Факт подтверждён 2+ независимыми источниками                                           | Средняя-высокая уверенность |
| `assertion_only` | Утверждение без подтверждения или из weak source (generic blog, forum post)            | Низкая уверенность          |

**Правила auto-compute:**

1. Agent анализирует источник при ingest → автоматически присваивает grade каждому факту
2. Grade фиксируется в метаданных страницы (не в теле)
3. При contradiction resolution: `documented(1) > corroborated(2) > assertion_only(3)` — работает как sub-priority для documentation sources
4. **Никогда не ставится вручную** — только агентом из анализа source authority

> Canonical: `AGENTS.md#auto_computed_fields`

---

### 🌐 Language Policy for Wiki Pages & Agent Responses

#### Page Structure Headers (Templates)

- **All section titles in templates are English** — `## Definition`, `## Key Characteristics`, `## Principles`, `## Context`, `## Analysis`, `## Conclusions`, etc.
- This provides consistent structural anchors for agent navigation, regardless of content language
- Templates serve as machine-readable guide for agent — headers don't change with user language preference

#### Page Content Language

- Content follows source language
- Bilingual sources → bilingual sections (allowed and normal)
- No forced translation required at ingest time

#### Agent Response Translation

- When synthesizing answer: **translate section headers to match user's question language**
  - User asked in Russian → agent uses `Определение`, `Ключевые характеристики`, etc.
  - User asked in English → agent uses `Definition`, `Key Characteristics`, etc.
- Content paraphrasing is agent's discretion — can quote directly, summarize, or translate

#### Mixed-Language Pages

- Allowed and encouraged when reflecting bilingual sources
- Agent treats each section independently for translation at response time

**Canonical reference:** `AGENTS.md#language_policy`

---

### 🔄 Template Co-evolution Process

1. **Agent proposes** structural improvement → log via `process-ingest.json#schema_evolution`
2. **User reviews and approves** → agent commits update
3. **New scenarios detected** → discussed in context.md → added to schema
4. **Never auto-modify templates** — always user-approved changes

---

### 📐 Template Files (Phase 13.4)

Детальные шаблоны страниц хранятся в `wiki/templates/`.

| Category | File |
|----------|------|
| Entity | [entity-template.json](wiki/templates/entity-template.json) |
| Concept | [concept-template.json](wiki/templates/concept-template.json) |
| Synthesis | [synthesis-template.json](wiki/templates/synthesis-template.json) |
| Comparison | [comparison-template.json](wiki/templates/comparison-template.json) |

**Canonical**: `AGENTS.md#template_files` → full catalog: `[wiki/templates/index.json](wiki/templates/index.json)`

> Templates are **recommended**, not enforced. Agent may add/remove sections as needed.

---

### 🗂 Wiki Categories (canonical source)

Все скрипты и агент читают порядок категорий из единого источника:

**Файл**: `rules/categories.json`

Структура:
```json
{
  "version": "1.0",
  "categories": [
    { "key": "entities",       "label": { "en": "Entities",         "ru": "Сущности" },        "description": "..." },
    { "key": "concepts",       "label": { "en": "Concepts",          "ru": "Концепции" },         "description": "..." },
    ...
  ]
}
```

**Поля:**
| Field | Описание |
|-------|----------|
| `key` | Идентификатор — соответствует имени директории под wiki/ |
| `label` | Отображаемое имя в формате `{lang: name}` (поддерживает en, ru, de, fr...) |
| `description` | Описание назначения категории |

**Куда читать:**
- `scripts/rebuild-meta.sh` — строит index.md из CATEGORY_ORDER + CATEGORIES_LABELS_RAW
- `scripts/wiki-search.sh` — вычисляет порядок при старте скрипта в `CATEGORY_ORDER`
- `scripts/duplicate-titles.sh` — читает CATEGORIES для проверки дублей
- **Агент**: когда создаёт страницу, проверяет category из frontmatter → соответствует ли директории под wiki/

**Правило**: никогда не хардкодить категории. Всегда читать из JSON.

> Canonical: `AGENTS.md#wiki_categories` — agent must reference this file when adding/changing categories.

---

### Compounding Workflow

Ответ считается компандящимся (требует сохранения как новая wiki-страница), если:

- Синтез из ≥2 wiki-страниц с новым выводом (не просто сбор фактов)
- Разрешено противоречие, требующее документирования в отдельной странице
- Ответ дополняет existing entity/concept новыми фактами
  **Save conditions**: Compounding → предложить пользователю сохранить как новую страницу. Synthesis = новый логический вывод (A+B→C), а не просто агрегация.

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
        { "name": "## Active Projects", "type": "project_list" },
        {
          "name": "### [Название проекта]",
          "properties": [
            "status: active/completed/on-hold",
            "context: brief project goal and current status",
            "related_pages: links to Entity/Concept pages"
          ]
        },
        { "name": "---\\n*Last updated: YYYY-MM-DD*", "type": "footer" }
      ]
    },
    "load_conditions": {
      "read_when": "WORK_MODE is project and snapshot contains entry for this project",
      "never_read": [
        "oneoff questions",
        "deep-dive study (query/discussion modes)"
      ]
    },
    "update_rules": [
      { "action": "create", "trigger": "user declares new project" },
      {
        "action": "update",
        "trigger": "every ingest/query that adds or changes related wiki pages"
      },
      {
        "action": "archive",
        "trigger": "project completed — entry moved to wiki/projects/, removed from snapshot.md"
      }
    ],
    "rule": "agent never loads snapshot.md if user is not working on a project. session starts with index.md + overview.md."
  }
}
```

---

## 🧠 User Work Modes (Schema-уровень)

Эти режимы определяют, как агент управляет контекстом при различных типах пользовательских запросов.

### Как агент определяет [WORK_MODE: project]

Агент **не ждёт явного маркера** — он сам определяет режим по контексту задачи. Три пути:

| Способ                             | Когда срабатывает                                                  | Пример                                               |
| ---------------------------------- | ------------------------------------------------------------------ | ---------------------------------------------------- |
| **Прямая инструкция пользователя** | Пользователь явно говорит «работаю над проектом» или ставит маркер | `[WORK_MODE: project]` в запросе                     |
| **Контекст задачи**                | Агент понимает по формулировке, что это итеративная работа         | «Мигрирую auth на JWT → какие схемы token rotation?» |
| **Уточняющий вопрос**              | Агент не уверен → спрашивает пользователя                          | «Это одноразовый вопрос или часть проекта?»          |

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

**Trigger**: agent detects ≥3 wiki pages used for answer synthesis → proposes save to user.
**Rule**: Never auto-create without explicit fixation flag (DR-4). Web-sourced data requires user approval.

- **Контекст**: ответ на вопрос содержит novel insight → агент предлагает сохранить как новую страницу.
- **Политика**: Compaction=false до момента fixation страницы в wiki.
- **Новая сессия**: false — контекст не переносится, агент начинает с snapshot.md

**Технические вызовы (Ingest / Lint)**:

- Вызов из Ingest: FLUSH_RAWS после извлечения, читать только страницы для обновления.
- Вызов из Lint: агент НЕ читает wiki напрямую — только отчёт из bash/Python скрипта.

---

## 🧠 Memory Architecture Contract (системные правила)

Эти контракты определяют, как агент управляет памятью и читает файлы через bash.

### Three-Layer Memory Model

Wiki использует три слоя памяти — каждый закрывает свою роль, не дублируя друг друга:

| Файл | Роль | Живёт | Читаю/пишу |
|------|------|-------|------------|
| **working_memory.json** | Оперативная память *текущей* сессии — focus_node, open_pages, next_steps_todo. Периодически перезаписывается (turn → turn). | Коротко: одна сессия. Чистится при dismissal/compaction. | Agent записывает каждый turn. |
| **hot.md** | Срез *активного проекта и вопросов* — на чём остановились, какие wiki-страницы были полезны, ключевые выводы из обсуждений. Выживает компакцию через restore-hot-cache.sh. | Долгосрочно: между сессиями. Обновляется при end-of-session или когда важная задача закрыта. | Agent записывает срез, не полную ленту. |
| **log.md** | Append-only летопись всех действий и изменений wiki. Хронологическая лента. | Навсегда. Не переписывается, только append. | Agent append'ит каждую запись. |

**Как они взаимодействуют:**
```
Session start:
  ├── read working_memory.json → restore focus_node, next_steps_todo
  ├── restore-hot-cache.sh → прочитать hot.md для контекста активного проекта/вопроса
  └── grep log.md последние записи → понять о чём был разговор раньше

Session end:
  ├── write_to_working_memory → обновить WM (next_steps_todo, open_pages)
  └── write_session_context_to_hot.md → записать срез в hot.md
```

**Что должно быть в каждом файле:**

- **working_memory.json**: `current_mode`, `focus_node`, `open_pages`, `next_steps_todo`, `dead_ends`, `query_summary`.
- **hot.md**: `Active Project` (WORK_MODE: project) — project name, focus node, related wiki pages, key findings, next steps. `Active Session Context` (WORK_MODE: query/discussion) — topic, pages read, key findings. `System State` — Active Threads как сейчас.
- **log.md**: `[YYYY-MM-DD] type | description`, sources, append-only. Agent читает при старте сессии для контекста предыдущих обсуждений (grep последние 10-20 записей).

> Canonical: `AGENTS.md#three_layer_memory_model`

### Session Context Management (Global Rule)

Агент сохраняет контекст сессии в hot.md **сразу при каждом действии** — не дожидаясь конца сессии, когда агент отключён.

- **Глобальное правило**: `rules/session_context_rules.json` определяет алгоритм сохранения и чтения контекста.
- **Триггеры**: 1) вопрос получен → записать суть запроса; 2) ответ/действие завершены → записать summary + использованные wiki-страницы.
- **Чтение при старте сессии**: `restore-hot-cache.sh` → прочитать hot.md для контекста активного проекта/вопроса.

> Schema ref: `rules/session_context_rules.json`. Canonical: `AGENTS.md#session_context_management`

### CONTEXT_BUBBLE & GREP CONTRACT

### 📝 Grep Contract

```json
{
  "allowed": ["grep -m N pattern wiki/", "head -20 file.md", "sed -n 'X,Yp'"],
  "prohibited": ["cat large_file.md", "grep pattern wiki/ (no -m)"]
}
```

> **Rule**: Always use `-m` flag with grep. Never `cat >50-line files`. Read working_memory.json#grep_contract for full details.

- **CONTEXT_BUBBLE**: не более 3 активных страниц в контексте одновременно.
- **GREP CONTRACT**: используем только разрешённые паттерны bash (см. `process-query.json#grep_contract`).
  > Canonical: `process-query.json#grep_contract`.

### Log.md Read Pattern

Agent читает log.md при старте сессии для понимания контекста предыдущих обсуждений:
- **Правило**: Agent использует grep (не cat) для чтения последних записей — не более 10-20 строк.
- **Когда читать**: При start session, если `working_memory.json` пустой или stale (>30 days без обновлений).
- **Как читать**: `grep -m 20 "" wiki/log.md | tail -20` для последних записей. Или по ключевым словам: `grep -m 10 "project_name" wiki/log.md`.
- **Цель**: Понять о чём был разговор, какие проекты велись, в каком контексте остановились.
- **Не читать весь log**: Это ~250+ строк, дорого по токенам. Только релевантные записи.

> Canonical: `AGENTS.md#log_read_pattern`

### CONTEXT COMPACTION HANDLING

- Компакция контекста выбрасает injected content (tool results, pages read) из текущего turn.
- **После компакции** → агент обязан вызвать:
  ```bash
  bash scripts/restore-hot-cache.sh || true
  ```
- Это восстановит `hot.md` из файла — слой долговременной памяти, который переживает compact.
- **Важно**: Working memory (focus_node, next_steps_todo) может быть обрезан в WM.json при compact. Но `hot.md` содержит срез проекта/сессии и восстанавливается через restore-hot-cache.sh.
  > Canonical: `AGENTS.md#context_compaction_handling`

### LOG_APPEND_ONLY — wiki/log.md never overwritten, always appended

### LOG_APPEND_ONLY — wiki/log.md never overwritten, always appended

- **Rule**: `wiki/log.md` is append-only. Never use `write()` or `cat > file`. Always use `cat >> file` (append).
- Violation example: `cat > wiki/log.md` → destroys entire history (~250 lines).
- Correct pattern: read existing log → append new entries at end → write back. Or better: always append via bash `>>`.
- **Canonical reference**: `AGENTS.md#log_append_only` — canonical source for log.md edit rules.

### NATURAL MEMORY TRANSLATION

- Факты из frontmatter / git → переводить в human-time: «позавчера», «неделю назад»
- Ссылаться на «мы» вместо «система/агент» когда речь об общем опыте проекта
- Точность фактов не нарушается — просто формулировка становится естественной
- Living-страница для примеров и эволюции: `wiki/concepts/natural-memory.md`
  > Canonical: `AGENTS.md#natural_memory_translation`

---

### EXECUTION CONTRACT — Proposal → Action, Never Stop at "Давай запущу?"

- **Rule**: Agent never stops after proposing a plan or asking permission to execute.
  - User says _what_ they want. Agent decides _how_ to do it and acts immediately.
  - Phrases like "Давай запущу веб-поиск?" → proposed, didn't execute → dead_end marker.
  - Correct pattern: propose plan (optional) → **immediately execute** → report results.
- **When to ask user**: Only for schema-patch proposals (structural wiki changes), novel insight pages requiring approval, or ambiguous intent where context is unclear.
- **Never ask permission for execution actions**: web_search, file reading, git commits, script runs, link repairs — these are agent's autonomous domain.
- **Pattern recognition**:

| Trap pattern                                                | Why it happens                                                                                                                 | Fix                                                                            |
| ----------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------ |
| Proposed A/B → "Давай запущу...?" → stop                    | Agent-mode: presentation instead of execution. Question phrase = request permission, but AGENTS.md requires autonomous action. | Execute immediately after proposing. Report results, not approval.             |
| Complex query → read WM/log/AGENTS.md → propose plan → stop | Agent prepares context → doesn't act                                                                                           | Read context (allowed) → execute tool calls (required)                         |
| New topic → unsure → offer discussion → stop                | Uncertainty triggers "let's discuss" instead of action                                                                         | Ask ONE clarifying question, then execute regardless. No loops on uncertainty. |

**Canonical**: `AGENTS.md#execution_contract` — agent acts, user decides direction.

---

## 🔧 Error Handling Protocol

При обнаружении любой ошибки, противоречия или dead end — **не зависать**, а следовать шагам:

### 4-step loop

1. **Detect & Log** `[!]` → См. `process-query.json#error_handling.logging_actions`
   Записать в log.md с типом [error], описанием и контекстом. Всегда append (`>>`), never overwrite.
2. **Analyze** → Краткий анализ: что пошло не так, почему инструкция сломалась (не просто «ошибка», а корень проблемы)
3. **Resolve** → Выбрать стратегию:

- `local-fix`: проблема локальная (путь, ссылка, логика) → исправить самостоятельно
- `schema-patch`: противоречие в Schema/AGENTS.md → предложить патч пользователю на review
- `source-conflict`: два источника говорят противоположное → отметить как `CONFLICT` на странице и продолжить
- `dead-end`: подход не работает (например, grep дал шум) → документировать причину, сменить стратегию

4. **Continue** → Двигаться дальше по task, не застревая на сломанной инструкции

### Примеры применения

| Ситуация                                    | Действие                                                                               |
| ------------------------------------------- | -------------------------------------------------------------------------------------- |
| `git add *` заблокирован guardrails         | `[!] Log: protected zone blocked` → `local-fix: switch to git add wiki/`               |
| fetch_content вернул обрезанный markdown    | `[!] Log: truncation detected` → `local-fix: fallback web_search + get_search_content` |
| Новая команда несовместима с текущей Schema | `[!] Log: schema conflict` → `schema-patch: предложить патч AGENTS.md`                 |
| Grep дал >100 совпадений без смысла         | `[!] Log: grep noise` → `dead-end: switch to index.md`                                 |

### Правило

> **Ошибка ≠ стоп.** Каждый error — сигнал к действию, а не причина зависать. Агент фиксирует, анализирует, решает и двигается дальше.

---

## 📂 Raw Corrected Zone (`raw/corrected/`)

### Architecture: Original → Corrected → Wiki

```
Layer 1 (immutable): raw/SRC-*/original.md ← agent read-only, never modified
Layer 2 (agent rw):  raw/corrected/SRC-*/* ← agent writes corrected copies here
Layer 3 (reference): wiki/**.md sources: [] → links to Layer 2
```

**Purpose**: Agent processes/corrects captured content (fixes broken links, OCR errors, extracts entities) and stores corrected versions in `raw/corrected/` — alongside immutable originals.

### Rules:

1. **Original files are immutable**: Agent NEVER modifies files directly under `raw/SRC-*/`. These stay as-captured.
2. **Agent writes to raw/corrected/**: Corrected copies live here with full agent rw access.
3. **Naming convention**: `{original_filename}.md` or `_extracted-{filename}` for processed variants.
4. **Wiki references corrected copies**: `sources: ["raw/corrected/SRC-*/<filename>.md"]` — never direct to originals.

### Guardrails (validate-path.sh):

```bash
PROTECTED_PATTERNS=("meta/")
ALLOWED_WRITE_ZONES=("raw/corrected/" "wiki/" "tracking/")  # ← agent rw zone added
```

**Usage in ingest flow**: Agent calls `scripts/raw-correct.sh --add "path" content` to write corrected copies (never direct writes).

> Schema ref: `process-ingest.json#step_4_corrected_copy` — full workflow.

---

### Phase 3: Non-blocking Lint

- **Entry point**: `scripts/lint.sh` — единый скрипт для всех lint-checks
- **Не блокирует agent turn**: запускается отдельно (можно по cron)
- **Output**: stdout = JSON отчёт, stderr = human-readable summary
- **Process-lint.json** ссылается на этот скрипт вместо inline выполнения отдельных проверок
- **Schema ref**: `AGENTS.md#non-blocking-lint`

## 🔗 Link Conventions & Auto-Fix

### Post-Operation Link Validation

**Rule**: Only check new files after create/update — never full wiki scan in ingest.

> Specific commands, auto-fix policy, and validation triggers defined in `process-ingest.json#step_9_post_checks`.

- **Internal format**: `[text](wiki-relative-path.md)`
- **Prohibited patterns**: `./` — never use dot-relative paths
- **Cross-category exception**: `../` allowed for cross-category links (e.g. from concepts/ to entities/) as long as target exists under wiki/

### External Links Standard (EXT-LINK-V1)

External links must use canonical http/https URLs. Never link to `raw/**` or `../**`.

**Prohibited patterns**: `[text](raw/**)` — never link to raw/. `[text](../**)` — relative paths prohibited.

**Unavailability check policy**:

- Without internet: skip network probes
- With internet: log broken URLs (404/timeouts) → inform user, do NOT auto-remove

> Full workflow: `process-ingest.json#external_source_policy`, `process-query.json#broken_link_awareness`.

### Crosslink Discovery

**Architecture: Script Suggests, Agent Decides**

Скрипт делает черновой score-based анализ и предлагает кандидатов. Агент принимает финальное решение на основе семантического понимания.

| Layer                      | Who                 | What                                       | Output                                            |
| -------------------------- | ------------------- | ------------------------------------------ | ------------------------------------------------- |
| **Discovery** (blackboard) | `auto-crosslink.sh` | Score-based candidate generation           | JSON list of candidates with scores & match types |
| **Decision** (judgment)    | Agent               | Semantic validation + contextual reasoning | Final crosslinks to write                         |

**Rule**: never auto-write crosslinks from script output alone. Script output = suggestion, not command.

**Scoring levels:**

- H1 title match: +3 points
- Shared sources: +2 base + diminishing factor (+1 for each additional shared source)
- Frontmatter related field: +4 points

**Thresholds:**
| Score | Action |
|-------|--------|
| ≥ 5 | Strong candidate — suggest crosslink with confidence |
| 3–4 | Weak signal — suggest review, agent decides |
| < 3 | Ignore (below noise floor) |

**System file exclusion:**

- Wiki system files excluded automatically: `log.md`, `issues.md`, `timeline.md`, `overview.md`, `snapshot.md`, `index.md`
- **hot.md**: больше не исключается — содержит Active Project и Session Context, которые нужны для поиска:
- Root-level system files excluded from scoring: `AGENTS.md`, `context.md`, `PLAN.md` (appear in most pages but NOT wiki content)

**Usage pattern:**

```bash
# After creating/updating a wiki page
./scripts/auto-crosslink.sh <path> --max-results 5
```

Script returns ≤5 candidates sorted by score. Agent reviews each, validates semantic relevance, and writes crosslinks if appropriate.

> Schema ref: `AGENTS.md#crosslink_discovery` — canonical source for crosslink rules.

---

## 🔐 Advisory Locking (wiki-lock.sh) — Prevent Silent Corruption

### Why This Matters

Parallel writes to the same wiki page can silently corrupt content. Without advisory locks, two concurrent operations (batch ingest, background synthesis) could trample each other's changes without any error messages.

### How It Works

`scripts/wiki-lock.sh` provides **per-file advisory locking** with:
- **Noclobber atomic creation** — POSIX race-safe lock acquire (`set -o noclobber`)  
- **Age-based staleness** — crashed writer unblocks automatically after 60s
- **Cross-process release** — simple `rm -f`, no PID tracking needed (design requirement)

### Usage Pattern

```bash
# Before create/update: acquire lock
if bash scripts/wiki-lock.sh acquire wiki/entities/Person.md; then
    # ... write page via Edit tool ...
    bash scripts/wiki-lock.sh release wiki/entities/Person.md
else
    sleep 2  # Retry after brief wait
fi
```

### Integration in Ingest Flow

Locks are automatically acquired/released at **step_9_post_checks**:
- `acquire` → first action (before rebuild-meta, link validation)
- `release` → last action (after all post-checks complete)

This ensures the lock covers ALL post-write operations: metadata updates, crosslink discovery, and manifest sync.

### Exit Codes

| Code | Meaning | Action |
|------|---------|--------|
| 0 | Success (lock acquired) | Continue to next step |
| 75 | Lock held by alive process | Retry after 2s or continue with caution |
| 3 | Cannot create lock dir | Log error, abort write |
| 4 | Invalid path format | Check path validation, fix if needed |

> Schema ref: `FEATURES_PLAN.md#1-advisory-locking` — full implementation plan.

---

## 🤫 Silent-Only Output Contract

### Rule: Agent shows only final results

**Принцип**: Пользователь получает **только финальный ответ**. Все промежуточные операции (grep, find, bash scripts, web_search) идут в `wiki/log.md` через append —  
 пользователь их не видит.

### Что запрещено показывать пользователю

| Запрещено                | Пример                                     |
| ------------------------ | ------------------------------------------ |
| Bash stdout/stderr       | grep output, script results, file listings |
| Intermediate search data | web_search snippets до финального синтеза  |
| "Thinking aloud"         | «думаю нужно сделать X...»                 |

### Что разрешено показывать

| Разрешено                | Пример                                               |
| ------------------------ | ---------------------------------------------------- |
| Финальный ответ/синтез   | Готовый ответ с источниками                          |
| Созданные файлы          | Wiki-страницы с frontmatter и контентом              |
| Ошибки + resolved action | `[!] Contradiction → resolved: 7.x LTS uses PHP 8.2` |

### Trigger для verbose mode

Пользователь может явно запросить промежуточные шаги: `"verbose", "debug mode"` — в этом режиме агент показывает grep/find results, но **только на один turn**. После  
 возвращается к silent.

> Canonical: `AGENTS.md#silent_output_contract`

## ⚙️ Execution Modes

Агент управляет двумя независимыми режимами:

| Флаг             | Значения                       | Где хранится                                                  |
| ---------------- | ------------------------------ | ------------------------------------------------------------- |
| `current_mode`   | `query` / `ingest` / `project` | working_memory.json (определяет **что** делает агент)         |
| `execution_mode` | `silent` / `verbose`           | working_memory.json (определяет **как** показывает результат) |

**Правила:**

- Default: `execution_mode = "silent"`. Не выводит пользователю рассуждения агента, вызванные команды и результаты их выполнения. Показывает только финальный ответ.
- Trigger: пользователь явно просит `"verbose"`, `"debug mode"`, `"покажи шаги"` → агент ставит `"verbose"` в WM и работает один turn.
- Auto-reset: после verbose-answer агент сбрасывает на `"silent"`.
- Явный reset: пользователь говорит `"quiet", "silent", "тише"` → мгновенный сброс.

> Canonical: `AGENTS.md#execution_modes`

---

## 🛡 Rules & Guardrails

### Guardrails Reference

Guardrails enforcement через `scripts/validate-path.sh`. Для схем проверки путей и protected zones — см. `process-ingest.json` (capture flow validation).

#### Schema References

- `process-ingest.json` references this for capture flow validation
- `scripts/validate-path.sh` implements the actual guardrails

### Fetch Content Truncation Handling

```json
{
  "fetch_content_truncation": {
    "condition": "response_markdown_contains '[Content truncated...]' or output is visibly cut off mid-sentence",
    "primary_action": "fallback to web_search(query) + get_search_content(responseId) for complete coverage",
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
  "raw/**": {"owner": "user", "access": "read-only via capture flow"},
  "raw/corrected/": {"rule_id": "RAW-CORRECTED-V1", "owner": "agent", "access": "full read/write for processed copies (scripts/raw-correct.sh)"},
  "wiki/**": {"owner": "agent", "access": "full read/write/manage"},
  "meta/**": {"rule": "auto-generated", "files": ["registry.json", "backlinks.json"], "rebuild_command": "./scripts/rebuild-meta.sh"},
  "tracking/": {"rule_id": "TRACKING-V1", "owner": "agent", "access": "full read/write for ingest registry files", "note": "raw_registry.json, similarity_index.json и другие tracking-файлы. Agent пишет напрямую."},
  ".vault-meta/": {"rule": "gitignored-system", "files": ["locks/", ".wiki-lock.meta"], "owner": "agent", "access": "read/write for system state only", "note": "Не коммитится в git — содержит системные файлы блокировок и логи агента."}
  },
  "zone_def1": {
  "rule_id": "ZONE-DEF1",
  "raw/**": {"owner": "user", "access": "read-only via capture flow"},
  "raw/corrected/": {"owner": "agent", "access": "full read/write for processed copies (scripts/raw-correct.sh)"},
  "wiki/**": {"owner": "agent", "access": "full read/write/manage"},
  "tracking/": {"owner": "agent", "access": "full read/write for registry and tracking files"},
  "implications": ["Agent manages all wiki links/structure. User controls raw/. Agent writes to raw/corrected/ and tracking/."
  },
  "meta_def1": {
  "rule_id": "META-DEF1",
  "rules": [
  "NEVER edit meta files directly",
  "All operations through scripts only"
  ],
  "protected_by": "validate-path.sh blocks direct write to meta/**"
  },
  "never_do": [
  "directly_edit_protected_zones",
  "skip_capture_flow_for_raw_sources",
  "manually_modify_meta_files"
  ]
}
```

#### `.vault-meta/` — системные файлы агента

Системная папка, которая **не коммитится в git** (.gitignore). Содержит:

| Файл/Папка | Назначение |
|-----------|------------|
| `locks/` | Временные директории для блокировок (wiki-lock.sh) |
| `.wiki-lock.meta` | Состояние блокировки мета-слоя |
| `hook.log` | Лог авто-коммитов (git-auto-commit.sh) |
| `auto-commit.disabled` | Флаг отключения auto-commit |

**Правила:**
- Agent может читать и писать в эту папку для управления системным состоянием
- **Никогда не коммитить** — это runtime state, не project artifact
- При поломке: проверить целостность блокировок (`ls .vault-meta/locks/`), удалить stale locks если нужно

> Canonical: `AGENTS.md#vault_meta` — agent must understand this zone when debugging lock corruption or auto-commit failures.

---

### Delta Tracking (Phase 29)

**Purpose**: Prevent waste of tokens on re-ingesting already-processed sources. Ensure contradiction resolution can trace back to original source.

#### Manifest File (`raw/corrected/SRC-*/*/.manifest.json`):

```json
{
  "original_path": "raw/SRC-001/pi-dev-docs-latest.md",
  "corrected_path": "raw/corrected/SRC-001/pi-dev-docs-latest.md",
  "hash_original": "sha256:abc123...",
  "date_ingested": "2026-07-01",
  "status": "processed"
}
```

#### Workflow:

| Step              | Action                                                                                       |
| ----------------- | -------------------------------------------------------------------------------------------- |
| **1. Capture**    | Agent saves original to `raw/SRC-*/*` (immutable)                                            |
| **2. Hash check** | Calculate hash of original → check if `.manifest.json` exists with same hash                 |
| **3a. Skip**      | If manifest exists AND corrected copy is up-to-date → skip re-ingest                         |
| **3b. Process**   | If no manifest or stale → create corrected copy in `raw/corrected/`, write manifest, proceed |

#### Contradiction Resolution:

1. Agent detects contradiction → reads wiki page → gets `sources: ["raw/corrected/SRC-*/<file>.md"]`
2. Reads `.manifest.json` for original_path + hash_original
3. Re-reads raw/original (immutable) for comparison with current wiki facts
4. Resolves based on cascade priority (code > docs, documented > assertion_only)

> Schema ref: `process-ingest.json#step_4_corrected_copy`, `AGENTS.md#raw_corrected_zone`

---

## 🔍 Search Strategy

> Canonical flow: `index_lookup → semantic_search → wiki-search.sh` — полный алгоритм в `process-query.json#search_priority_details`.
> **Fallback**: `meta/search-index.json` — structured index with keywords/tags/first-sentences for fast lookup.
> **System files excluded**: См. `process-query.json#step_1.system_files_exclusion`.

---

## **Schema Reference**: `AGENTS.md#compounding_workflow` → Full workflow defined in [process-query.json](process-query.json). Compounding decision logic is query-specific.

## 📅 Date Convention Rule

- Frontmatter `date` = **current system date** (never derive from source filename / git commit dates)
- Log entries: `## [YYYY-MM-DD] action | description`
- Timestamps in JSON: ISO-8601 `YYYY-MM-DDTHH:MM:SS+TZ`

> Enforced by: `lint.sh check_id=6` (date_consistency_check).

---

## 🔄 Schema Inheritance

Process files inherit from AGENTS.md via `schema_ref` (never duplicate rules).

### Canonical References

| Reference                | Path                                                                                        |
| ------------------------ | ------------------------------------------------------------------------------------------- |
| Meta rebuild             | `./scripts/rebuild-meta.sh`                                                                 |
| Search priority          | `process-query.json#search_priority_details`                                                |
| Lint script              | `./scripts/lint.sh`                                                                         |
| Contradiction resolution | `process-query.json#contradiction_resolution_flow → authoritative > temporal > user_review` |

> Rule: never duplicate AGENTS.md rules in process files. Always add `schema_ref` for canonical source.

---

## 🔧 Auto-Rebuild Metadata

### Meta Rebuild Path

#### Canonical: `scripts/rebuild-meta.sh [--index-only]`

- Full rebuild: `./scripts/rebuild-meta.sh` (registry + backlinks)
- Index only: `./scripts/rebuild-meta.sh --index-only` (index.md H1+first sentences)

`./scripts/rebuild-meta.sh` → rebuilds all meta files (`registry.json` + `backlinks.json` + `index.md`)

`--index-only` flag → rebuilds only `wiki/index.md` (H1 headers + first sentences per category)

**Trigger points**: After any wiki edit in Ingest / Query / Lint processes.

> Full integration flow: `process-ingest.json#step_3a` (full), `process-query.json#post_check`, `process-lint.json#check_id_7`

---

## 📄 Auto-update Index

`./scripts/rebuild-meta.sh --index-only` → rebuilds `wiki/index.md` (H1 headers + first sentences per category)

**Trigger**: Ingest process after create_page/update_existing. Lint after link_validation.

> Logic details: script parses wiki/\*_/_.md, groups by subdirectory, sorts alphabetically.

## 🔄 Non-blocking Lint (Phase 3)

`scripts/lint.sh` — автономный скрипт lint-аудита, который не блокирует agent turn.

### Когда вызывается

| Процесс            | Триггер                                                                                      |
| ------------------ | -------------------------------------------------------------------------------------------- |
| **Самостоятельно** | `./scripts/lint.sh [--quiet] [--skip-checks ID1,ID2]` — можно запустить отдельно или по cron |
| **Process-lint**   | Вместо inline lint → вызывать `./scripts/lint.sh --quiet`                                    |

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
  "checks_run": 11,
  "issues_found": {
    "contradictions": 0,
    "orphan_pages": 3,
    "orphan_paths": [],
    "new_sources_unprocessed": 5,
    "duplicate_titles": 0,
    "date_inconsistencies": 0,
    "broken_links": 2,
    "auto_repaired_links": 1,
    "agent_review_required": 0,
    "agent_review_details": [],
    "contradictions_deep": 0,
    "text_similarity_overlaps": 0,
    "hot_cache_stale": false
  },
  "total_issues": 10,
  "status": "ISSUES_FOUND"
}
```

### Checks выполняемые скриптом

| Check ID | Название                  | Скрипт                                     | Результат                                                    |
| -------- | ------------------------- | ------------------------------------------ | ------------------------------------------------------------ |
| 1        | Contradictions (soft)     | `## Обновлено` grep                        | Pages count for agent review                                 |
| 2        | Orphan pages              | `orphan-pages.sh`                          | Count + paths of orphaned wiki pages                         |
| 3        | Knowledge gaps            | —                                          | Skipped (agent review required)                              |
| 4        | New sources available     | `check-new-sources.sh --max 10`            | NEW: package list                                            |
| 5        | New topics proposal       | —                                          | Skipped (requires external sources)                          |
| 6        | Mechanical linting        | `duplicate-titles.sh` + frontmatter checks | Duplicate count, missing fields                              |
| 7        | Date consistency          | `date-consistency.sh`                      | Inconsistencies count                                        |
| 8        | Broken links auto-resolve | `unified-pass.sh --auto`                   | JSON: broken_links[] + auto_repaired + agent_review_required |
| 9        | Contradictions deep scan  | `detect-contradications.sh`                | potential_contradictions count + conflicts[]                 |
| 10       | Text similarity scan      | `text-similarity.sh --scan-all`            | matches[] with similarity_score, file1, file2                |
| 11       | Hot cache stale check     | `check-wiki-changes.sh`                    | WIKI CHANGES DETECTED / no changes                           |

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

## 🎯 Dynamic Priority + Relevance Scoring (Phase 5)

`scripts/wiki-search.sh --dynamic "query"` — динамический порядок категорий по query intent.

**Query Intent Analysis**:

- Entity keywords → `entities/`, `concepts/`, `syntheses/` priority
- Comparison keywords (`vs`, `compared to`) → `comparisons/`, `syntheses/`, `concepts/` priority
- Concept keywords → `concepts/`, `syntheses/`, `entities/` priority
- Fallback: static priority (syntheses→concepts→entities)

**Relevance Scoring**:

1. Position weight: query in H1 = +3, body = +1 per occurrence
2. Frequency weight: total occurrences × 1
3. Backlink weight: mentions in other wiki pages × 5
4. Category bonus: earlier priority category gets +10×(max_priority - index)

**Usage**: `./scripts/wiki-search.sh --dynamic "query"` — results sorted by combined score descending.

> Full workflow: `AGENTS.md#smart_search_priority` → extended with dynamic intent analysis.
