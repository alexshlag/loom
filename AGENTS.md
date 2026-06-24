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

## 🔄 Workflows

### Ingest Flow (capture → integrate)

```json
{
  "workflow": "ingest",
  "steps": [
    {"step": 1, "name": "guardrails_validation", "action": "validate_path_for_write"},
    {"step": 2, "name": "source_analysis", "actions": ["classify_source", "extract_theses", "identify_entities_mentioned", "check_for_contradications"]},
    {"step": 3, "name": "discussion_with_user", "action": "present_summary_and_propose_pages"},
    {"step": 4, "name": "create_or_update", "actions": ["fill_sections", "add_citations", "update_frontmatter"]},
    {"step": 5, "name": "log_registration", "actions": ["append_to_log.md"]},
    {"step": 6, "name": "index_update", "action": "update_index_categories"},
    {"step": 7, "name": "meta_rebuild", "command": "./scripts/rebuild-meta.sh"}
  ],
  "rules": {
    "raw_immutable": "никогда не редактировать raw/ напрямую",
    "capture_first_integrate_second": "сначала оригинал в raw/, затем wiki-страница"
  }
}
```

### Query Flow

```json
{
  "workflow": "query",
  "steps": [
    {"step": 1, "name": "search", "priority_order": ["read_index_categories_matching_topic", "wiki_recall(query)", "grep_recursive_fallback"]},
    {"step": 2, "name": "synthesis", "actions": ["read_relevant_pages", "note_key_facts", "cross_reference_same_topic", "identify_matches_or_contradications"]},
    {"step": 3, "name": "compounding_decision", "condition": "answer_synthesizes_2_plus_sources", "action": "propose_save_as_new_page"},
    {"step": 4, "name": "result_fixation", "actions": ["create_or_update_page", "add_source_citations", "update_index"]},
    {"step": 5, "name": "meta_rebuild", "command": "./scripts/rebuild-meta.sh"}
  ],
  "contradiction_resolution": {
    "temporal_conflict_detected": "prefer_newer_version",
    "fact_conflict_no_date_info": "flag_for_user_review",
    "source_conflict_with_authoritative_source": "prioritize: docs > community_wiki > notes"
  }
}
```json
  "search_priority_schema": {
    "rules": [
      {"rule": "index_lookup >=2 совпадения → достаточен", "action": "STOP"},
      {"rule": "wiki_recall >=3 совпадения → достаточен", "action": "STOP"},
      {"rule": "иначе → grep_recursive (first 10 chunks)", "action": "FALLBACK"}
    ],
    "stop_if_any_results": false
  },
  "contradiction_resolution_ref": "see Contradiction Resolution Flow section above"
}
```

### Lint Flow (periodic health check)

```json
{
  "workflow": "lint",
  "checks": [
    {"check_id": 1, "name": "contradictions_between_pages", "actions": ["read_all_wiki_by_category", "compare_facts", "identify_conflicts"]},
    {"check_id": 2, "name": "orphan_pages_detection", "rule": "page_with_zero_backlinks"},
    {"check_id": 3, "name": "knowledge_gaps_detection", "rule": "mentioned_but_no_page"},
    {"check_id": 4, "name": "new_topics_proposal", "inputs": ["conversation_context", "index_links", "external_sources"]},
    {"check_id": 5, "name": "mechanical_linting", "checks": [
      {"check": "orphaned_pages", "rule": "has_at_least_one_backlink"},
      {"check": "broken_links", "rule": "all_paths_resolve_from_wiki_root"},
      {"check": "duplicate_titles", "rule": "no_duplicate_within_same_category"},
      {"check": "missing_frontmatter", "rule": "required: [tags, date, sources]"}
    ]},
    {"check_id": 6, "name": "date_consistency_check", "actions": ["extract_date_from_fm", "extract_dates_from_updates"]},
    {"check_id": 7, "name": "link_validation_with_auto_fix", "rule": "validate_all_wiki_links_and_rewrite_to_wiki_relative"}
  ]
}
```

### Contradiction Resolution Flow (Canonical)

Этот flow определяет, как разрешать конфликты между страницами wiki. Применяется при **ингесте** нового источника и при **query** ответах.

```json
{
  "contradiction_resolution": {
    "description": "Алгоритм разрешения противоречий после их обнаружения",
    "detection_output": {
      "format": "Если найдены противоречия — добавить раздел '## ⚠ Противоречия' в ответ перед основным контентом",
      "include_in_answer_if_contradiction_found": true,
      "log_entry": "## [date] query | Вопрос -> обнаружено X противоречий, Y сопоставлений"
    },
    "resolution_priority": [
      {
        "priority": 1,
        "strategy": "authoritative_source",
        "condition": "source_conflict_with_authoritative_source",
        "rule": "Официальный источник всегда приоритетнее даты обновления",
        "description": "Приоритет: official docs > community wiki > personal notes"
      },
      {
        "priority": 2,
        "strategy": "temporal_conflict",
        "condition": "temporal_conflict_detected",
        "rule": "Использовать информацию из страницы с более поздней датой обновления",
        "description": "Если нет authoritative source — новее лучше"
      },
      {
        "priority": 3,
        "strategy": "user_review",
        "condition": "fact_conflict_no_date_info OR contextual_conflict",
        "rule": "Отметить противоречие в ответе и предложить пользователю выбрать приоритетный источник",
        "description": "Если неясно — спросить пользователя"
      }
    ],
    "resolution_actions": [
      {
        "applies_to": "Страница с устаревшей информацией",
        "format": "## Обновлено [date] — новое уточнение\\n[новая информация]",
        "name": "add_update_section_to_old_page"
      },
      {
        "condition": "contradiction_requires_explanation_for_user",
        "description": "Если противоречие сложное и требует детального анализа — создать сравнительную страницу",
        "destination_template": "wiki/comparisons/[entity-a]-vs-[entity-b].md",
        "name": "create_comparison_page"
      },
      {
        "applies_to": "Ответ пользователю",
        "format": "## ⚠ Противоречия в источниках:\\n* [Страница А] vs [Страница Б]: [описание конфликта]\\n* Рекомендовано: [какая версия использовать]",
        "name": "note_in_answer"
      }
    ],
    "resolution_strategy": [
      {
        "action": "PREFER_AUTHORITATIVE_OVER_NEWER",
        "condition": "authoritative_source_conflict_with_newer_page",
        "rule": "Официальный документ всегда приоритетнее даты обновления. Если official docs говорит X, а новая страница — Y, верить official docs.",
        "priority": 1
      },
      {
        "action": "PREFER_NEWER_VERSION",
        "condition": "temporal_conflict_detected AND no_authoritative_source",
        "rule": "Использовать информацию из страницы с более поздней датой обновления",
        "priority": 2
      },
      {
        "action": "FLAG_CONTRADICTION_FOR_USER_REVIEW",
        "condition": "fact_conflict_no_date_info OR contextual_conflict OR scope_conflict",
        "rule": "Отметить противоречие в ответе и предложить пользователю выбрать приоритетный источник",
        "priority": 3
      },
      {
        "action": "RESOLVE_BY_AUTHORITATIVE_SOURCE",
        "condition": "source_conflict_with_authoritative_source",
        "rule": "Приоритет: official docs > community wiki > personal notes. Если authoritative source найден — использовать его, игнорируя дату.",
        "priority": 1
      }
    ],
    "post_resolution_verification": {
      "description": "Проверить, что противоречие действительно разрешено",
      "actions": [
        {
          "action": "re-read_updated_pages",
          "purpose": "verify_consistency",
          "condition": "always"
        },
        {
          "action": "optional_web_search",
          "description": "Для важных фактов — проверить во внешних источниках",
          "condition": "high_stakes_fact OR user_requested_verification"
        }
      ]
    },
    "history_tracking": {
      "description": "Сохранять историю изменений при разрешении противоречий",
      "format": "### История изменений:\\n- **YYYY-MM-DD**: Обновлено с [старое значение] → [новое значение] (разрешение противоречия со Страницей X)\\n  - Причина: [тип конфликта]\\n  - Источник решения: [страница/источник]",
      "append_to": "## Обновлено [date] — новое уточнение"
    }
  }
}
```

---

## 🔗 Link Conventions & Auto-Fix

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

## 📊 Compounding Knowledge Base

### Why This Matters

```json
{
  "compounding_principle": {
    "insight": "wiki keeps getting richer with every source added and every question asked",
    "contrast_to_rag": "standard RAG rediscover knowledge fresh on each query; wiki compounds cross-references, contradictions flagged, synthesis reflects all sources"
  }
}
```

### How Compounding Works

```json
{
  "compounding_workflow": {
    "when_synthesizing_answer": [
      {"condition": "answer_from_2_plus_existing_pages", "action": "consider_save_as_new_page"},
      {"condition": "novel_insight_or_contradiction_resolution_not_recorded", "action": "save_as_new_page"},
      {"condition": "creating_new_content", "action": "always_add_backlinks_to_related_pages"},
      {"condition": "new_entry_created", "action": "update_index.md"}
    ]
  }
}
```

### When to Create New Pages

```json
{
  "save_conditions": [
    {"condition": "user_explicitly_requests_save", "priority": 1},
    {"condition": "answer_contains_synthesis_from_multiple_sources", "priority": 2},
    {"condition": "comparison_or_analysis_useful_for_future_queries", "priority": 3},
    {"condition": "contradiction_resolution_should_become_permanent_record", "priority": 4}
  ]
}
```

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
```


*Schema Version: 4 | Last Updated: 2026-06-24 | Author Pattern: Andrej Karpathy (LLM Wiki)*
