# Wiki Log

## [2026-06-23] ingest | Инициализация wiki — структура и инструкции восстановлены

---

## [2026-06-23] guardrails | реализована Schema-level блокировка direct edits к raw/ и meta/

## [2026-06-24] ingest | Pi Coding Agent — https://pi.dev/docs/latest

## [2026-06-26] lint-fix | wiki-search.sh — все 7 багов исправлены (critical + medium)
  - Fix #1: comp_count теперь sum(1 for ...) вместо max(0, 1) — корректно считает "vs" запросы
  - Fix #2: escape_for_grep() + sed — regex meta-characters больше не ломают grep
  - Fix #3: grep '^# .*' вместо head -1 — поиск по H1 заголовку работает корректно
  - Fix #4: -gt после COUNTER++ — скрипт останавливается на MAX_RESULTS, а не MAX-1
  - Fix #5: проверка ${#POSITIONAL_ARGS[@]} перед доступом — no crash on bash < 4.4
  - Fix #6: find ... -name '*.md' вместо ** glob — рекурсивный fallback без shopt
  - Fix #7: HISTORY_FILE env var — пути с одинарной кавычкой больше не ломают Python

## [2026-06-24] ingest | Python Development on NixOS — https://wiki.nixos.org/wiki/Python

## [2026-06-24] query | Основные способы создания сред разработки Python для NixOS

## [2026-06-24] ingest | raw/llm-wiki.md — LLM Wiki Pattern (Andrej Karpathy)
* Создана entity: Andrej Karpathy
* Создан concept: LLM Wiki Pattern
* Создан synthesis: RAG vs LLM Wiki Pattern
* Обновлено: overview.md, index.md

## [2026-06-24] query | Andrej Karpathy — тестирование процесса обновления wiki
* Тестовый запрос: "Кто такой Andrej Karpathy?"
* Проверена логика обработки новой информации:
  - Найдено: entity страница существовала, но содержала неполную информацию
  - Web search предоставил дополнительные факты (биография, карьера)
  - Применён исправленный flow: обновление existing страницы с сохранением истории

## [2026-06-24] schema | Исправлена инструкция разрешения противоречий process-query.json
* Добавлена иерархия приоритетов стратегий:
  1. authoritative_source (official docs > community wiki > personal notes)
  2. temporal_conflict (новее лучше)
  3. user_review (если неясно — спросить пользователя)
* Расширены типы противоречий: добавлены scope_conflict, contextual_conflict, version_conflict
* Добавлена пост-проверка разрешения (re-read_updated_pages + optional_web_search)
* Добавлена история изменений при разрешении противоречий
* Создан AGENTS.md (markdown schema document по оригинальной идее Karpathy)
* Добавлен compounding workflow в process-query: step 2.6 compounding_decision, enhanced save_conditions
* Теперь answers сохраняются как новые страницы при novel insights/synthesis — wiki compounds

## [2026-06-24] schema | AGENTS.md created matching Karpathy's original concept
* Markdown schema document co-evolves between human and LLM
* Defines structure, workflows (ingest/query/lint), guardrails, page formats
* Replaces rigid JSON-only approach with flexible evolving schema

## [2026-06-24] query | Andrej Karpathy — обновление entity страницы с новой информацией
* Обнаружена проблема: инструкция process-query.json не имела явного правила для дополняющей информации (new facts without contradiction)
* Исправлено:
  - Добавлен критерий `new_facts_for_existing_entity` в save_conditions (step 3)
  - Уточнен rule в assess_compounding_value: теперь учитывает новые факты об existing entity
* Обновлена wiki/entities/andrej-karpathy.md с полной биографией (Tesla, OpenAI, Stanford PhD, Eureka Labs, Anthropic)

## [2026-06-24] lint | Первый полный lint-аудит wiki
* Создан issues.md — отчёт о проблемах (5 категорий: frontmatter, broken_links, date_inconsistency, orphan_pages, process_improvements)
* Обновлён process-lint.json:
  - Добавлены thresholds для trigger conditions
  - check_id=6: date_consistency_check
  - Уточнены правила missing_frontmatter (required vs optional fields)
  - Указан lint_script_path (scripts/run-lint.sh)
  - Добавлен frontmatter_schema
* Найдено 3 issues по broken_links, 1 date inconsistency, 2 missing frontmatter

## [2026-06-24] ingest | AI Factory — https://github.com/lee-to/ai-factory
* Создана entity: AI Factory (wiki/entities/ai-factory.md)
* Raw sources сохранены в raw/github/lee-to/ai-factory@2.x/
* Tags: tool, cli, agent-skill-system, stack-agnostic, spec-driven

## [2026-06-24] schema | Добавлен режим execution_modes в AGENTS.md
* Глобальный default: silent. По запросу пользователя → verbose (пошаговый trace)
* Переключение: "давай проверим" / "verbose mode" / "покажи шаги"
* Авто-возврат к silent после 3 verbose-ответов
* В AGENTS.md добавлен раздел `## ⚙️ Execution Modes` с примером JSON для process_query
* В process-lint.json добавлён execution_mode (default: silent, trigger for verbose)
* Логирование в verbose зависит от процесса: [✓] success, [✗] issue, [!] warning

## [2026-06-24] concept | AI Factory vs Pi — Category Distinction
* Создан concept: wiki/concepts/ai-factory-vs-pi.md
* Уточнено: AI Factory = workflow schema (запускается на любом harness), Pi = harness runtime

## [2026-06-24] schema | AGENTS.md v4 — добавлено правило Date Convention Rule
* Issue #3 (date consistency): root cause identified — agent confused source capture dates with page creation dates
* Fix: added `📅 Date Convention Rule` to AGENTS.md specifying `system_current_date_only` for frontmatter dates
* JSON schema added to prevent future drift: `never_derive_from: [source_filename, raw_timestamps]`
* Schema version bumped from 3 → 4

## [2026-06-25] query | Temporal decay problem in compounding wiki
  * Создана страница: wiki/concepts/temporal-decay-in-wiki.md
  * Synthesis: LLM Wiki Pattern compounds knowledge но требует maintenance
  * Добавлены backlinks к llm-wiki.md + rag-vs-llm-wiki-pattern.md
  * working_memory.json updated: query_summary + next_steps_todo

## [2026-06-25] ingest | Symfony Framework — Comprehensive Knowledge Base
  * Создан raw пакет: raw/sources/SRC-2026-06-25-SYMFONY-001/
    - symfony-comprehensive-knowledge.md (основной источник, ~40к символов)
    - symfony-manifest.json (manifest с метаданными)
  * Создана entity: [Symfony](wiki/entities/symfony.md) — основной объект
  * Созданы concept-страницы:
    - Service Container & DI
    - Routing System & Controllers
    - Event Dispatcher
    - Security System (AuthN & AuthZ)
    - Doctrine ORM Integration
    - Symfony Flex & Recipes
    - Hexagonal Architecture in Symfony
    - Twig Templating
    - Testing Strategy
    - AssetMapper
    - Symfony AI Component
    - Messenger Component
    - Workflow & State Machine
    - Cache System
  * Обновлено: wiki/index.md (добавлены все новые страницы)
  * Обновлено: wiki/timeline.md (запись о Symfony ingest)

## [2026-06-25] schema | Переработана страница LLM Wiki Pattern по оригинальному gist Karpathy
* Переименована wiki/concepts/llm-wiki-pattern.md → wiki/concepts/llm-wiki.md
* Добавлены секции: Architecture, Operations (Ingest/Query/Lint), Indexing & Logging, Compounding, Tools, Why it works
* Обновлён дубль секции в entity: andrej-karpathy.md (удалён repeat, добавлены backlinks)
* Обновлены backlinks во всех связанных страницах (index.md, overview.md)
* Добавлена секция «Связи с нашим проектом» — mapping элементов проекта к паттерну Karpathy

## [2026-06-25] schema | Added Error Handling Protocol (4-step loop: detect → analyze → resolve → continue)
* Размещён после Memory Architecture Contract, перед Process Roles
* Покрытие: local-fix / schema-patch / source-conflict / dead-end
* Цель: агент не зависает на ошибках — фиксирует, анализирует причину, решает и двигается дальше

## [2026-06-26] query | Phase 2 — Smarter search (wiki-search.sh + priority categories)
* Создан `scripts/wiki-search.sh` с приоритетным поиском по категориям: syntheses → concepts → entities → ...
* Fallback на полный grep если priority не дал результатов
* Output с относительными путями от wiki_dir
* Интегрирован в process-query.json (search_priority_details + step 1 fallback_chain)
* Добавлена секция Smart Search Priority в AGENTS.md
* Обновлён PLAN.md с прогрессом Phase 2

## [2026-06-26] lint | Phase 4 — реализация --index-only в rebuild-meta.sh
* Добавлен флаг `--index-only` в `scripts/rebuild-meta.sh`: пропускает registry.json и backlinks.json, строит только index.md
* Обёрнуты блоки registry + backlinks в условие `if [[ "$INDEX_ONLY" == "false" ]]`
* Проверено: обычный вызов rebuilds всё (registry + backlinks + index), --index-only rebuilds только index
* Обновлён AGENTS.md: секция Auto-Rebuild Metadata дополнена описанием обоих режимов
* Обновлён PLAN.md: зафиксирована реализация --index-only в шаге 4.1

## [2026-06-26] schema | Phase 5 COMPLETED — Dynamic Priority + Relevance Scoring in wiki-search.sh
- Реализован query intent analysis: entity/concept/comparison keywords → dynamic priority categories
- Реализован relevance scoring: position weight (H1 = x3), frequency, backlink weight, category bonus
- Output сортируется по combined score (descending) — релевантные страницы выше
- Флаг --dynamic для wiki-search.sh
