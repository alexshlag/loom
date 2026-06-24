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
    "resources/": "инструменты, плагины, библиотеки"
  }
}
```

### 3. Schema (this document)
* Определяет структуру wiki, конвенции и рабочие процессы
* Делает агента дисциплинированным хранителем wiki, а не общим чат-ботом
* Co-evolves между человеком и агентом по оригинальной идее Karpathy

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
    {"priority": 3, "method": "grep_recursive", "fallback": true, "command": "grep -r query wiki/"}
  ]
}
```

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

### Почему это важно
- **Single Source of Truth**: AGENTS.md — единственный авторитетный источник общих правил
- **Автоматическая консистентность**: если AGENTS.md изменён — process файлы не требуют обновления (только ссылки)
- **Прозрачность наследования**: каждый процесс явно объявляет, от кого он получает правила

---

*Schema Version: 4 | Last Updated: 2026-06-24 | Author Pattern: Andrej Karpathy (LLM Wiki)*
