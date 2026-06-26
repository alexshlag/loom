# AGENTS.md — Wiki Schema & Conventions

## 📋 Overview

Данный документ определяет структуру, конвенции и рабочие процессы wiki. Он служит единственным источником истины о том, как агент должен оперировать при:
- Ингесте новых источников
- Ответе на вопросы через базу знаний
- Поддержании и health-checkwiki

Schema **co-evolves** по мере работы с пользователем — обновляется вместе с опытом.

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

## 📄 Page Formats & Templates

### Frontmatter Schema

```json
{
  "frontmatter": {
    "required": ["tags", "date", "sources"],
    "optional": ["related"],
    "template": "---\ntags: [entity, coding-agent]\ndate: YYYY-MM-DD\nsources: [raw/sources/...]\nrelated: [wiki/entities/example.md]\n---"
  }
}
```

### Entity Pages

```json
{
  "format": {
    "title": "# [Название]",
    "definition": "Краткое определение (1-2 предложения)",
    "sections": [
      {"name": "## Ключевые характеристики", "type": "bullet_list"},
      {"name": "## Связи", "type": "links_list"},
      {"name": "## Источники", "type": "raw_refs"},
      {"name": "## Обновлено [date] — новое уточнение (если обновлялось)", "type": "update_section"}
    ]
  }
}
```

### Concept Pages

```json
{
  "format": {
    "title": "# [Название концепции]",
    "sections": [
      {"name": "## Определение", "content": "формальное определение"},
      {"name": "## Принципы работы", "type": "numbered_list"},
      {"name": "## Контекст и применение", "type": "use_cases"},
      {"name": "## Примеры", "type": "code_or_text_examples"},
      {"name": "## Обновлено [date] — новое уточнение (если обновлялось)", "type": "update_section"}
    ]
  }
}
```

### Comparison Pages

```json
{
  "format": {
    "title": "# Сравнение: [Сущность A] vs [Сущность B]",
    "sections": [
      {"name": "## Таблица сравнения", "type": "markdown_table"},
      {"name": "## Анализ", "content": "детальный анализ и синтез"},
      {"name": "## Выводы", "content": "когда использовать, trade-offs"}
    ]
  }
}
```

### Synthesis Pages

```json
{
  "format": {
    "title": "# [Название синтеза]",
    "sections": [
      {"name": "## Контекст", "content": "вводный контекст"},
      {"name": "## Анализ", "content": "deep dive, объединяющий несколько страниц/источников"},
      {"name": "## Инсайты и выводы", "content": "новые находки, не очевидные из отдельных источников"},
      {"name": "## Связи", "type": "links_to_related_pages"}
    ]
  }
}
```

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

### Формат коммитов
```bash
# <type> | <scope>: <description>
ingest | added entity pi-coding-agent
query | synthesis on RAG vs classical DBs
lint | fixed orphan pages, added backlinks
schema | updated AGENTS.md with date convention rule
```
**Type** — ingest / query / lint / schema / fix / refactor.
**Scope** — файл или модуль, к которому относится (необязательно).
**Description** — краткое описание действия. Начинается с маленькой буквы.

```json
{
  "git_policy": {
    "allowed_commands": [
      {
        "command": "git status --short",
        "requirement": "MANDATORY",
        "phase": "pre_action",
        "description": "Вызывать строго перед формированием индекса и перед коммитом для валидации состояния репозитория."
      },
      {
        "command": "git add wiki/",
        "requirement": "RECOMMENDED",
        "phase": "staging",
        "description": "Использовать для автоматического добавления всех новых, измененных и удаленных файлов внутри директории wiki/. Исключает пропуск файлов."
      },
      {
        "command": "git add <file>",
        "requirement": "OPTIONAL",
        "phase": "staging",
        "description": "Использовать только для точечного добавления конкретных файлов вне директории wiki/."
      },
      {
        "command": "git rm --cached <file>",
        "requirement": "OPTIONAL",
        "phase": "staging",
        "description": "Использовать исключительно для удаления файлов из индекса без их физического удаления с диска."
      }
    ],
    "prohibited_commands": [
      {
        "command": "git add *",
        "reason": "Критическая ошибка. Добавляет системный мусор, временные файлы (.tmp, logs) и игнорирует настройки оболочки."
      },
      {
        "command": "git commit -a",
        "reason": "Запрещено сквозное индексирование. Агент обязан строго разделять фазы 'git add' и 'git commit'."
      }
    ],
    "protected_zones": {
      "paths": ["raw/**", "meta/**"],
      "policy": "NEVER_STAGED_OR_COMMITTED",
      "error_handling": {
        "action_on_block": "ABORT_AND_REPORT",
        "message_to_user": "Критическая ошибка: Зафиксирована попытка изменения или индексации файлов в защищенной зоне (raw/meta). Операция прервана."
      }
    },
    "commit_message_policy": {
      "formats": [
        {
          "name": "pipe-style",
          "pattern": "<type> | <scope>: <description>",
          "example": "ingest | added entity pi-coding-agent",
          "description": "Классический формат: type, scope (необязательно), краткое описание с маленькой буквы."
        },
        {
          "name": "conventional-commits",
          "pattern": "<type>(<scope>): <short_description>",
          "example": "feat(wiki): add structured page templates",
          "description": "Conventional Commits: feat/fix/docs/refactor, scope в скобках."
        }
      ],
      "prohibited_examples": [
        "fix stuff",
        "update",
        "commit"
      ],
      "required_fields": {
        "type": ["feat", "fix", "docs", "refactor"],
        "scope": "wiki"
      }
    }
  }
}
```

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

### CONTEXT_BUBBLE
- **Правило**: не более 3 активных страниц в контексте одновременно.
- **Когда срабатывает**: при чтении 4-й страницы — выгружаем наименее важную из предыдущих.
- **Статусы страниц**: `reading` (агент читает сейчас), `updating` (агент обновляет страницу), `read` (прочитана, можно выгрузить).

### Grep Contract
Агент читает файлы через bash только разрешёнными паттернами. Запрещено читать полные файлы.

| ✅ Разрешено | ❌ Запрещено |
|-------------|-------------|
| `grep -E '^# ' file.md` — быстрое оглавление | `cat file.md` — файл >50 строк (токеновая перегрузка) |
| `head -n 20 file.md` — чтение фронтматера | `grep pattern wiki/` — без `-m` (тысячи строк) |
| `sed -n 'X,Yp' file.md` — диапазон строк | |
| `grep -m N pattern wiki/` — искать до N совпадений (обязательно) | |

**Правило**: агент должен использовать только разрешённые паттерны для bash-чтения. Нарушение контракта = токеновая перегрузка.

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
| Lint | [process-lint.json](process-lint.json) | Периодическая проверка здоровья wiki, обнаружение противоречий |

Каждая роль наследует общие правила из AGENTS.md (guardrails, date_convention, logging_templates).
Полный workflow каждой роли — в соответствующем файле.

## Link Conventions & Auto-Fix

### Path Resolution

```json
{
  "path_resolution": {
    "base": "wiki_root",
    "format": "wiki-relative_from_wiki_root",
    "examples": ["entities/pi-coding-agent.md", "concepts/llm-wiki-pattern.md"],
    "never_use": ["./paths", "../relative_paths", "/absolute/wiki/..."]
  }
}
```

### Auto-Fix Protocol

```json
{
  "auto_fix_protocol": {
    "steps": [
      {"step": 1, "action": "validate_all_internal_links"},
      {"step": 2, "condition": "path_is_filesystem_relative", "auto_fix": "rewrite_to_wiki_relative"},
      {"step": 3, "condition": "target_page_does_not_exist", "fallback_message": "[!] Broken link: [text](path) — target does not exist. Proposed fix: create page or remove link."}
    ]
  }
}
```

### Post-Operation Link Validation

После **любой операции**, которая меняет пути, имена файлов или названия страниц (rename, move, delete, new page creation), agent обязан выполнить:

1. Вызов `./scripts/link-validator.sh <pattern>` — сканирование wiki на сломанные ссылки.
2. Парсинг JSON из stdout → применение auto-fix к каждому найденному линку.
3. Если target page не существует → предложить fix (create page / remove link).

**Обязательные триггеры:**
| Trigger | Description |
|---------|-------------|
| `page_created` | new wiki page — scan for mentions of the same topic |
| `page_renamed_or_moved` | old path → new path — scan ALL wiki files for broken links to old path |
| `page_deleted` | remove all references to deleted file from other pages |

**Логирование:**
```
[✓] Link validation: scanned N files, fixed X broken links, flagged Y orphaned targets
```

> **Полный workflow и команды — см. [process-ingest.json#post_operation_link_validation](process-ingest.json)**

### Link Format Standards

```json
{
  "link_formats": {
    "markdown_body_text": "[link text](wiki-relative-path.md)",
    "yaml_frontmatter_sources": "[raw/path/to/file]",
    "yaml_frontmatter_related": "[wiki/entities/example.md]"
  }
}
```

---

## ⚙️ Execution Modes

```json
{
  "default_mode": "silent",
  "verbose_phrases": ["давай проверим", "нет ли ошибок", "покажи как работает", "verbose mode", "покажи шаги выполнения"],
  "return_to_silent_after": 3,
  "process_overrides": {},
  "logging_templates": {
    "query_verbose": [
      "[✓] Index lookup: index.md прочитан",
      "[✓] Semantic search: найдено X релевантных страниц",
      "[!] Grep fallback использован для Y фактов",
      "[✓] Synthesis из Z источников"
    ],
    "ingest_verbose": [
      "[✓] Source classified: entity/concept/notes",
      "[!] Contradiction detected in X.md",
      "[✓] Pages created/updated: N"
    ],
    "lint_verbose": [
      "[✓] Check 1/N: contradictions — M конфликтов",
      "[✗] Check 2/N: orphan_pages — найдено K сирот",
      "[!] Check 3/N: knowledge_gaps — X нехватки"
    ]
  }
}
```

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

Priority order:

```json
{
  "search_priority": [
    {"priority": 1, "method": "index_lookup", "description": "read index.md by categories matching topic"},
    {"priority": 2, "method": "semantic_search", "command": "wiki_recall(query)", "description": "find pages by meaning, not keywords"},
    {"priority": 3, "method": "wiki_search_script", "fallback": true, "command": "./scripts/wiki-search.sh query wiki/ --max 15", "description": "smart priority search (syntheses→concepts→entities), fallback to full grep"}
  ]
}
```

### Smart Search Priority (Phase 2)

```json
{
  "wiki_search_script": {
    "path": "./scripts/wiki-search.sh",
    "usage": "./scripts/wiki-search.sh \"query\" wiki/ --max N",
    "priority_categories": ["syntheses", "concepts", "entities", "comparisons", "notes", "meetings", "projects", "bibliography", "resources"],
    "output_format": "relative/path/to/file.md:matched_line_number:matched_text",
    "fallback": "full grep по всем wiki/**/*.md если ничего не найдено в priority categories",
    "rule": "AGENT_MUST_USE_wiki_search_sh_INSTEAD_OF_RAW_GREP_RECURSIVE"
  }
}
```

**Логика приоритета:**
1. Сначала ищет в syntheses/ → concepts/ → entities/ (наивысшая релевантность)
2. Затем comparisons/ → notes/ → meetings/ → projects/ → bibliography/ → resources/
3. Если ничего не найдено — fallback на полный grep
4. Результаты всегда с относительными путями от wiki_dir

**Почему это важнее raw grep:**
- `grep -r query wiki/` при >100 страницах даёт noise и irrelevant results
- Priority categories: syntheses/concepts/entities содержат самую релевантную информацию
- Fallback на полный grep только если priority не дал результатов

---

**Schema Reference**: `AGENTS.md#compounding_workflow` → Full workflow defined in [process-query.json](process-query.json). Compounding decision logic is query-specific.
---

## 📈 Schema Evolution Guidelines

```json
{
  "evolution_rules": {
    "add_new_page_types_if_needed": ["projects/", "meetings/"],
    "refine_categorization_as_wiki_grows": true,
    "update_workflows_based_on_usage_patterns": true,
    "document_discoveries_in_log.md_with_prefix": "## [YYYY-MM-DD] ..."
  }
}
```

---

## 📚 Additional Tools (Optional)

```json
{
  "optional_tools": {
    "obsidian_web_clipper": {"purpose": "convert web articles to markdown"},
    "qmd": {"purpose": "local search engine with hybrid BM25/vector + LLM re-ranking"},
    "marp": {"purpose": "markdown-based slide decks from wiki content"},
    "dataview": {"purpose": "Obsidian plugin for queries over page frontmatter"}
  }
}
```
---

## 📅 Date Convention Rule

```json
{
  "date_rules": {
    "page_frontmatter_date_source": "system_current_date_only",
    "never_derive_from": ["source_filename", "raw_timestamps", "git_commit_dates"],
    "format": "YYYY-MM-DD for frontmatter, ISO-8601 (YYYY-MM-DDTHH:MM:SS) for verbose logs",
    "example": {
      "correct": "date: 2026-06-24 (current system date)",
      "wrong": "date: 2025-06-24 (derived from source filename SRC-2025-06-24)"
    },
    "log_entry_format": {
      "markdown_header": "## [YYYY-MM-DD] action | description",
      "json_timestamp_for_verbose": "ISO-8601: YYYY-MM-DDTHH:MM:SS+TZ",
      "reasoning": "system date is authoritative; source filenames encode capture time, NOT page creation time"
    }
  }
}
```

### Why This Matters
- `raw/sources/SRC-2025-06-24-001/file.md` означает что исходник был захвачен **24 июня 2025**
- Дата создания страницы в wiki должна быть **текущим системным временем** (например, 2026-06-24)
- Использование дат из имён файлов источников создаёт исторический дрейф и путает temporal reasoning

---

## 🔄 Process Initialization & Schema Inheritance

Каждый процессный файл наследует общие правила из AGENTS.md через явные ссылки, а не дублирует их.

```json
{
  "process_initialization": {
    "ingest": {
      "inherits_from": ["guardrails", "date_convention", "logging_templates"],
      "schema_ref": "AGENTS.md#guardrails",
      "note": "Ingest читает guardrails из AGENTS.md, а не копирует их. strict_rules в process-ingest.json — краткая шпаргалка, canonical источник — AGENTS.md"
    },
    "query": {
      "inherits_from": ["guardrails", "search_priority", "contradiction_resolution", "logging_templates", "date_convention"],
      "schema_ref": "AGENTS.md",
      "note": "Query ссылается на canonical Search Priority и Contradiction Resolution Flow из AGENTS.md. Если нужно расширить — расширяй в AGENTS.md, а не в process-query"
    },
    "lint": {
      "inherits_from": ["guardrails", "logging_templates"],
      "schema_ref": "AGENTS.md#guardrails",
      "note": "Lint обнаруживает проблемы, но не разрешает их. Resolution flow — зона Query/Ingest"
    }
  },
  "canonical_references": {
    "meta_rebuild_path": "./scripts/rebuild-meta.sh (относительный путь из корня wiki)",
    "search_priority": "AGENTS.md#search-priority → index_lookup → semantic_search → grep_recursive",
    "contradiction_resolution_flow": "AGENTS.md#contradiction-resolution → authoritative > temporal > user_review"
  },
  "rule": "Никогда не дублировать правила из AGENTS.md в процессных файлах. Всегда добавляй \"schema_ref\" для ссылки на canonical источник."
}
```

---

## 🔧 Auto-Rebuild Metadata (Phase 1)

`rebuild-meta.sh` автоматически пересобирает метаданные после каждого wiki edit:
- **registry.json** — список всех страниц с метаданными (tags, date, sources)
- **backlinks.json** — граф связей между страницами

### Когда вызывается

| Process | Триггер |
|---------|----------|
| **Ingest** | После create_page (step 3a), update_existing (step 3b) |
| **Query** | После create_new_page (post_check) |
| **Lint** | После link_validation_with_auto_fix (check_id=7), file_rename_or_delete (check_id=8) |

### Как использовать
```bash
# Вызывается автоматически из process-файлов
cd /path/to/loomana && ./scripts/rebuild-meta.sh
```

**Output:**
- Exit 0 = success — метаданные актуальны
- Exit 1 = failure — warning logged, continue (не блокирует flow)

### Почему это важно
- **Single Source of Truth**: AGENTS.md — единственный авторитетный источник общих правил
- **Автоматическая консистентность**: если AGENTS.md изменён — process файлы не требуют обновления (только ссылки)
- **Прозрачность наследования**: каждый процесс явно объявляет, от кого он получает правила

---

*Schema Version: 6 | Last Updated: 2026-06-25 | Author Pattern: Andrej Karpathy (LLM Wiki)*
