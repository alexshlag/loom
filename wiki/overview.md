---
tags: [overview, wiki-status]
date: 2026-06-28
sources: [wiki/index.md]
related: [
    wiki/concepts/llm-wiki.md,
    wiki/entities/symfony.md,
    wiki/concepts/python-nixos-development.md
]
---

# Wiki Overview — Текущая картина знаний

## Статус
Wiki содержит **36+ markdown-файлов**: 4 root files (index, log, overview, timeline), 2 entity pages (Symfony, Nvidia), ~18 concept pages, 2 synthesis pages.

## Ключевые области

### LLM Wiki Pattern / AI Agent
* **[LLM Wiki Pattern](concepts/llm-wiki.md)** — compounding knowledge base вместо стандартного RAG (Andrej Karpathy)
* **[RAG vs LLM Wiki](syntheses/rag-vs-llm-wiki-pattern.md)** — основное различие: RAG rediscover on every query, wiki compounds incrementally
* **[Pi Coding Agent](entities/pi-coding-agent.md)** — terminal harness, расширяемый через TypeScript extensions
* **[AI Factory](entities/ai-factory.md)** — CLI tool, stack-agnostic skill system
* **[Temporal Decay](concepts/temporal-decay-in-wiki.md)** — проблема устаревания знаний в compounding wiki
* **[Andrej Karpathy](entities/andrej-karpathy.md)** — AI Researcher, автор LLM Wiki Pattern
* **AI Factory vs Pi** — [сравнение категорий](concepts/ai-factory-vs-pi.md)

### Python на NixOS
* **[Python Development on NixOS](concepts/python-nixos-development.md)** — изолированные среды разработки (virtualenv / conda аналог)
* **Синтез**: [основные способы создания сред](syntheses/python-nixos-development-environments.md)
* **Related**: [Home Manager docs](https://nixos.org/manual/hm/), [Nixpkgs Manual](https://nixos.org/nixpkgs/manual/#contributing-guidelines)

### Symfony Framework
* **[Symfony Entity](entities/symfony.md)** — high-performance PHP web framework, component-based architecture
* **Концепты** (18+):
  * [Service Container & DI](concepts/service-container.md) — центральный механизм управления сервисами
  * [Dependency Injection](concepts/symfony-dependency-injection.md) — паттерн внедрения зависимостей
  * [Hexagonal Architecture](concepts/hexagonal-architecture.md) — Ports & Adapters в Symfony
  * [Routing System](concepts/routing-system.md), [Security System](concepts/security-system.md)
  * [Event Dispatcher](concepts/event-dispatcher.md), [Messenger Component](concepts/messenger-component.md)
  * [Workflow/State Machine](concepts/workflow-state-machine.md), [Twig Templating](concepts/twig-templating.md)
  * [Doctrine ORM](concepts/doctrine-orm.md), [Cache System](concepts/cache-system.md)
  * [Testing Strategy](concepts/testing-strategy.md), [AssetMapper](concepts/assetmapper.md)
  * [Symfony Flex & Recipes](concepts/symfony-flex.md), [Symfony AI Component](concepts/symfony-ai.md)
* **Сравнения**: [UX vs AssetMapper](comparisons/symfony-ux-packages.md), [LLM Wiki implementations](comparisons/llm-wiki-implementations.md)

## Schema & Conventions
AGENTS.md (v9) — живая схема с Error Handling Protocol, JSON git policy, decision rules (DR-1/DR-2/DR-3/DR-4). Process файлы: ingest.json, query.json, lint.json.

### Live Issues Status
* **Issues #5/#9** (Auto-Crosslink): ✅ Fixed — multi-level scoring + integrated into ingest process
* **Issue #8** (Syntheses handling): ✅ DR-4 added — syntheses treated as special category
* **Python-nixos redundancy**: ✅ Resolved — cross-references added between concept and synthesis
* **System files exclusion**: ✅ Resolved — excluded from normal search + auto-crosslink

## Следующие шаги
1. ✅ Обновлён overview.md — все основные страницы с бэклинками
2. Реализовать wiki scalability (локальные индексы + search-index.json) → отдельный спринт
3. Периодический lint-аудит через `./scripts/lint.sh`
4. Проверить auto-crosslink после каждого ingest/query

## Связи:
* [LLM Wiki Pattern](concepts/llm-wiki.md)
* [Symfony](entities/symfony.md)
* [Python NixOS Development](concepts/python-nixos-development.md)
* [Dependency Injection](concepts/symfony-dependency-injection.md) — новый concept с 2026-06-28

---
*Создано: 2026-06-23 | Обновлено: 2026-06-28 — полный обзор всех областей знаний + авто-кросслинки*

---
*Создано: 2026-06-23 | Обновлено: 2026-06-25 — полное обновление статуса*
