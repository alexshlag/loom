# Wiki Log

## [2026-06-30] lint | Audit: 5 issues found (2 contradictions, 3 orphan pages)
  - Contradictions: 2 pairs detected — agent review required to resolve stale vs fresh facts
  - Orphan pages: 3 pages with zero backlinks — need cross-references or cleanup
  - Broken links: ✅ 0 (all links valid after ../ path resolution fix)
  - Text similarity overlaps: ✅ 0 (no ≥90% copy chains)
  - Date consistency: ✅ OK

## [2026-06-30] process | Query Intent Decoder (QID) mechanism added
  - Добавлен step 0.5 в process-query.json: query_intent_decoder для расшифровки метафор и ассоциаций пользователя
  - Pattern recognition: "окунёмся", "дай мне из" → query_wiki intent
  - Decision logic: if wiki empty → warn_with_humor; if has data → proceed_to_search_flow

## [2026-06-30] schema | Auto-cleanup rule for working_memory.json next_steps_todo
  - Добавлено правило: перед каждым write() agent обязан отфильтровать completed задачи из next_steps_todo
  - broken_links_resolved — audit trail, не удалять. next_steps_todo и open_pages — чистить.

## [2026-06-30] schema | Execution Contract added (proposal → action)
  - Agent never stops after proposing a plan or asking permission to execute
  - User says *what* they want. Agent decides *how* and acts immediately.

## [2026-06-30] schema | Harness-Independent Session & Git Operations complete
# Wiki Log

## [2026-06-26] query | post_search_flow — исправлен алгоритм действий после пустого wiki-search
  - raw/sources/ check → web_availability_check → auto-web_search + предложение сохранить / ручной доступ
  - Добавлен блок `post_search_flow` в process-query.json с 5 шагами

## [2026-06-26] query | web_ingest_flow — добавлен переход от web_search к созданию wiki-страницы
  - `post_user_response` branching: user_saves → execute web_ingest_flow / one-off → deliver only / decline → exit clean
  - 6-шаговый flow: capture raw package → validate path → check existing/create new → rebuild meta & index → register tracking → link validation
  - Интеграция с process-ingest.json#step_3a (создание) и #step_3b (обновление существующей страницы)

## [2026-06-23] ingest | Инициализация wiki — структура и инструкции восстановлены

---

## [2026-06-23] guardrails | реализована Schema-level блокировка direct edits к raw/ и meta/

## [2026-06-24] ingest | Pi Coding Agent — https://pi.dev/docs/latest

## [2026-06-26] schema | Fixed Issues #1-3 (External Sources Update Policy, web_search priority, Novelty Threshold)
  - Issue #1: Два режима обновления — user-requested + cron. Агент не делает web_search без запроса.
  - Issue #2: web_search из того же источника, но данные изменились → внешние приоритетны. Разные источники → Issue #4.
  - Issue #3: Novelty insight = новый логический вывод (не сбор фактов). Чёткие критерии вместо субъективного определения.
  - Обновлена AGENTS.md с секцией "External Sources Update Policy"

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
  * Создана entity: [Symfony](entities/symfony.md) — основной объект
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

## [2026-06-28] fix | corrected Git documentation to prevent rule violations
* Исправлены инструкции по работе с git:
  - `wiki/GIT-WORKFLOW.md` — добавлены предупреждения об операциях, нарушающих правила (git add -f, reset --hard, clean)
  - `wiki/GIT-TROUBLESHOOTING.md` — удалены опасные команды, добавлены предупреждения о безопасности
  - `.gitignore` — исправлено игнорирование similarity_cache.json

## [2026-06-28] docs | Git workflow documentation + Loomana system docs
* Созданы документы по работе с git:
  - `wiki/GIT-WORKFLOW.md` — подробные инструкции по коммитам, protected zones, error handling
  - `wiki/GIT-TROUBLESHOOTING.md` — руководство по решению типичных проблем git
  - Обновлён `.gitignore` (добавлен exception для similarity_cache.json)
* Создана entity страница: wiki/entities/loomana.md — полная документация о системе Loomana
  - Архитектура (три слоя: raw, wiki, schema)
  - Три рабочих процесса: ingest, query, lint
  - Guardrails и Error Handling Protocol
  - Memory Architecture (Context Bridge, Context Bubble)
  - Schema Co-evolution и Git Conventions
* Добавлена запись в index.md (entities секция)
* Пересобраны метаданные: registry.json, backlinks.json, index.md
* Обновлён timeline.md с записью о создании страницы

## [2026-06-28] lint | Contradictions review — fixed 3 incorrect "Обновлено" markers (creation pages now use "Создано")
* **Fixed**: python-nixos-development.md — removed duplicate ## Обновлено section, kept only actual update (2026-06-24)
* **Fixed**: symfony-dependency-injection.md — changed "## Обновлено 2026-06-28 — создана концепция" → "## Создано"
* **Fixed**: nvidia.md — changed "## Обновлено" → "## Создано" (creation, not update)
* **Fixed**: python-nixos-development-environments.md — changed creation marker from "Обновлено" to "Создано"
* **Remaining**: contradictions_deep=1 (python concept vs synthesis overlap) — soft check, requires manual dedup review
* **Status**: Contradictions reduced from 5 → 2 (only actual updates remain flagged)

## [2026-06-28] fix | raw-link-repair.sh — автоматическое преобразование markdown ссылок в GitHub permalinks
* **Проблема**: raw/github источники содержали битые относительные ссылки на .md файлы (./file.md, ../README.md), которые не работали при ingest в wiki.
* **Решение**: 
  - Создан `scripts/raw-link-repair.py` — скрипт для автоматического преобразования всех markdown ссылок в GitHub permalinks
  - Создан `scripts/raw-link-repair.sh` — bash wrapper для вызова из process-ingest.json
  - Работает по шаблону: github/{owner}/{repo}@{branch}/path.md → https://github.com/owner/repo/blob/<branch>/path.md
* **Результат**: 
  - Применён к ai-factory@2.x (13 файлов, 76 repairs)
  - Все относительные ссылки заменены на GitHub permalinks
  - Обновлён `process-ingest.json#step_1`: теперь вызывает raw-link-repair.sh вместо ручных замен агентом
* **Результат**: issues.md #27 — SKILL.md references в ai-factory исправлены. Оставшиеся github репо (если есть) требуют обработки при следующем ingest.

## [2026-06-29] schema | Universal Frontmatter restructured — tags free, type=reality_layer, new category field, evidence_grade auto-computed
  - `tags`: → свободный массив keyword-тегов (убрано ограничение enum)
  - `type`: reality layer: documentation | code_reality | live_state (для cascade противоречий)
  - `category` (новое): раздел wiki entity/concept/synthesis/comparison/note/project/bibliography/resource
  - `evidence_grade`: auto-computed агентом при ingest (documented/corroborated/assertion_only), не ручное
  - Обновлены: AGENTS.md, process-query.json (source_type→source_layer), process-ingest.json
  - Зафиксировано в context.md#Q5

## [2026-06-29] schema | Language Policy added — English-only headers in templates, content follows source language, response translation by agent
  - Page structure headers: always English in templates (consistent navigation)
  - Content follows source language (Russian/English/bilingual allowed)
  - Agent translates headers at response time to match user's question language
  - Mixed-language pages normal and encouraged for bilingual sources
  - Fixed в context.md#Q6, added to AGENTS.md#language_policy

## [2026-06-30] schema | Auto-cleanup rule for working_memory.json next_steps_todo
  - Добавлено правило: перед каждым write() agent обязан отфильтровать completed задачи из next_steps_todo
  - broken_links_resolved — audit trail, не удалять. next_steps_todo и open_pages — чистить.

## [2026-06-30] schema | Harness-Independent Session & Git Operations complete
  - Интегрированы все 4 скрипта: git-auto-commit.sh, load-hot-cache.sh, restore-hot-cache.sh, check-wiki-changes.sh
  - Обновлены process-файлы: ingest step 3a/3b (git-auto-commit), query bootstrap (load-hot-cache), query step 2.3 post_action (restore-hot-cache), query step 3 post_operations (git-auto-commit)
  - Секция Harness-Independent удалена из AGENTS.md — правила живут в process-файлах

## [2026-06-30] concept | Natural Memory Translation created
  - Перевод машино-читаемых данных (frontmatter dates, git timestamps) в естественную форму: «позавчера», «неделю назад»
  - Правило добавлено в AGENTS.md → Memory Architecture Contract
  - Living-doc создан на wiki/concepts/natural-memory.md с принципами, таблицей соответствия, примерами

## [2026-06-30] process | Query Intent Decoder (QID) mechanism added
  - Добавлен step 0.5 в process-query.json: query_intent_decoder для расшифровки метафор и ассоциаций пользователя
  - Pattern recognition: "окунёмся", "дай мне из" → query_wiki intent

## [2026-06-30] schema | Execution Contract added (proposal → action)
  - Agent never stops after proposing a plan or asking permission to execute
  - User says *what* they want. Agent decides *how* and acts immediately.

## [2026-06-30] lint | Audit: 5 issues found (2 contradictions, 3 orphan pages)
  - Contradictions: 2 pairs — agent review required to resolve stale vs fresh facts
  - Orphan pages: 3 pages with zero backlinks — need cross-references or cleanup
  - Broken links: ✅ 0 | Text similarity overlaps: ✅ 0 | Date consistency: ✅ OK
