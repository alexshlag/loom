---
tags: [overview, wiki-status]
date: 2026-06-25
sources: []
related: []
---

# Wiki Overview — Текущая картина знаний

## Статус
Wiki содержит **36+ markdown-файлов**: 4 root files (index, log, overview, timeline), 2 entity pages (Symfony, Nvidia), ~18 concept pages, 2 synthesis pages.

## Ключевые области

### LLM Wiki Pattern / AI Agent
* **LLM Wiki Pattern** — compounding knowledge base вместо стандартного RAG (Andrej Karpathy)
* **RAG vs LLM Wiki** — основное различие: RAG rediscover on every query, wiki compounds incrementally
* **Pi Coding Agent** — terminal harness, расширяемый через TypeScript extensions
* **AI Factory** — CLI tool, stack-agnostic skill system
* **Temporal Decay** — проблема устаревания знаний в compounding wiki

### Python на NixOS
* **Python Development on NixOS** — изолированные среды разработки (virtualenv / conda аналог)
* **Синтез**: основные способы создания сред разработки Python на NixOS

### Symfony Framework
* **Symfony Entity** — high-performance PHP web framework, component-based architecture
* **18 концептов** покрывают ключевые компоненты: Service Container, Routing, Events, Security, Doctrine ORM, Flex, Hexagonal Architecture, Twig, Testing, AssetMapper, Symfony AI, Messenger, Workflow/State Machine, Cache

## Schema
AGENTS.md (v6) — живая схема с Error Handling Protocol, JSON git policy, dual commit formats. Process файлы: ingest, query, lint.

## Следующие шаги
1. ✅ Заполнить index.md по мере роста wiki
2. Провести lint-проверку для проверки здоровья структуры
3. Добавить backlinks между связанными страницами (Symfony → концепты)

## Связи:
* [LLM Wiki Pattern](concepts/llm-wiki.md)
* [Symfony](entities/symfony.md)
* [Python NixOS Development](concepts/python-nixos-development.md)

---
*Создано: 2026-06-23 | Обновлено: 2026-06-25 — полное обновление статуса*
