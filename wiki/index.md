# Wiki Index


## Сущности
* [AI Factory](entities/ai-factory.md) — Stack-agnostic CLI tool and skill system for AI-powered development. — [obsidian-cli, vault-transport, cli-tool, spec-driven]
* [API Platform](entities/api-platform.md) — [[API Platform]] — фреймворк для создания гипермедийных REST и GraphQL API. — [api, rest, graphql, symfony]
* [Andrej Karpathy](entities/andrej-karpathy.md) — AI Researcher, автор LLM Wiki pattern (LLM-powered personal knowledge base). — [machine-learning, deep-learning, computer-vision, nlp, llm-wiki-pattern]
* [Clippy](entities/rust-clippy.md) — Clippy is a collection of lints (static analysis checks) to catch common mistakes and improve Rust code. — [rust, linter, linting-tool]
* [Ibexa DXP](entities/ibexa-dxp.md) — [[Ibexa DXP]] (Digital Experience Platform) — enterprise-grade CMS + commerce platform на базе [[Symfony]]. — [dxp, cms, commerce, symfony]
* [Loomana — Wiki System Documentation](entities/loomana.md) — **Loomana** (внутреннее имя `loom`) — это **LLM-powered personal knowledge base**, где знания компандятся с каждым новым источником и вопросом. — [llm-wiki, personal-knowledge-base, compounding, rag-alternative, karpathy-wiki]
* [Node.js](entities/nodejs.md) — Node.js — это runtime для выполнения JavaScript-кода вне браузера. — [runtime, javascript, server-side, npm]
* [Nvidia](entities/nvidia.md) — Американская технологическая корпорация, лидер в области разработки графических процессоров (GPU), аппаратных ускорителей для искусственного интеллекта (AI) — [hardware, ai, semiconductor]
* [Pi Coding Agent](entities/pi-coding-agent.md) — Минимальный терминальный код-агент (harness), расширяемый через TypeScript-расширения, skills, prompt templates и темы. — [coding-agent, terminal-ui, typescript-extension, llm-agency, nodejs-sdk] ([Pi Coding Agent] [pi-llm-wiki])
* [Sylius](entities/sylius.md) — [[Sylius]] — open-source eCommerce framework на базе [[Symfony Full Stack]]. — [ecommerce, symfony, headless]
* [Symfony](entities/symfony.md) — [[Symfony]] — высокопроизводительный PHP веб-фреймворк с открытым исходным кодом, созданный SensioLabs. — [framework, php, dependency-injection, service-container, autowiring, di-pattern] ([Symfony] [Symfony Framework])

## Концепции
* [AI Factory vs Pi Coding Agent — Category Distinction](concepts/ai-factory-vs-pi.md) — **Это не сравнение сущностей, а различение категорий. — [workflow-schema, agent-orchestration, harness-comparison, methodology]
* [AssetMapper](concepts/assetmapper.md) — AssetMapper — component for managing modern CSS & JavaScript assets without build pipelines or Node.js dependencies. — [assetmapper, css, javascript, frontend]
* [Cache System](concepts/cache-system.md) — Symfony Cache component provides PSR-6 and PSR-16 compliant caching with advanced features: tag-based invalidation, cache stampede protection, multiple adapters. — [cache, psr6, tags, invalidation]
* [Dependency Injection в Symfony](concepts/symfony-dependency-injection.md) — Dependency Injection (DI) — паттерн проектирования, позволяющий внедрять зависимости объекта извне. В Symfony DI реализуется через контейнер сервисов (Service Container). ### 1. — [symfony, dependency-injection, service-container, autowiring, di-pattern]
* [Doctrine ORM Integration](concepts/doctrine-orm.md) — [[Doctrine ORM]] — object-relational mapper для PHP, интегрированный в [[Symfony]] через DoctrineBridge. — [doctrine, orm, entities, repositories]
* [EasyAdmin Bundle](concepts/easyadmin-bundle.md) — EasyAdmin — пакет (bundle) для Symfony, генерирующий admin backends. Создаёт CRUD-интерфейсы автоматически из entity моделей. Бесплатный, быстрый, с полной документацией. — [admin, symfony-bundle, cruds]
* [Event Dispatcher](concepts/event-dispatcher.md) — [[Event Dispatcher]] — компонент [[Symfony]], который обеспечивает decoupled communication между компонентами системы через события. — [event-dispatcher, symfony-messenger, psr-event, observable-pattern, event-bus]
* [Harness-Aware Wiki Setup Flow](concepts/harness-aware-setup.md) — Идея автоматической настройки wiki-контекста для конкретного harness (Pi, Claude Code, Cursor и т.д.). — [harness, wiki-setup, design-idea, pending]
* [Hexagonal Architecture & Clean Patterns in Symfony](concepts/hexagonal-architecture.md) — [[Hexagonal Architecture]] (Ports & Adapters) — architectural pattern that keeps business logic separate from technical details. Domain layer sits at center, depending on nothing. — [architecture, hexagonal, clean-architecture, domain-driven-design] ([Hexagonal Architecture] [Ports and Adapters])
* [LLM Wiki Pattern — Incremental Knowledge Base Building](concepts/llm-wiki.md) — > **Origin:** Andrej Karpathy. [Reference gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f). — [rag, knowledge-base, llm, compounding-knowledge] ([LLM Wiki Pattern] [Karpathy wiki])
* [Messenger Component](concepts/messenger-component.md) — [[Messenger Component]] — component for sending and receiving messages to/from other applications or via message queues. — [messenger, messaging, queue]
* [Natural Memory Translation — Перевод машинных фактов в живую память](concepts/natural-memory.md) — Перевод машино-читаемых данных (даты, комиты, timestamps) в естественную форму, которую человек воспринимает как «мы помним» вместо «система записала». — [memory, agent-behavior, wiki-pattern]
* [Python Development Environments on NixOS](concepts/python-nixos-development.md) — [[Python Development Environments]] on [[NixOS]] — методология создания изолированных сред разработки для [[Python]] в [[NixOS]] — [nixos, python, development-environment]
* [Routing System & Controllers](concepts/routing-system.md) — [[Routing System]] — ключевой компонент [[Symfony]], который маппит incoming URLs к application code (controller actions). — [routing, controllers, attributes]
* [Security System (AuthN & AuthZ)](concepts/security-system.md) — Symfony Security — comprehensive security system для web applications, включающий аутентификацию (кто пользователь) и авторизацию (что может делать). — [security, authentication, authorization, voters]
* [Service Container & Dependency Injection](concepts/service-container.md) — [[Service Container]] — центральный механизм [[Symfony]], который централизует создание и управление объектами (services). — [dependency-injection, service-container, autowiring, di-pattern, symfony]
* [Sonata Admin Bundle](concepts/sonata-admin-bundle.md) — Sonata Admin — пакет (bundle) для Symfony, генерирующий admin panels и CRUD interfaces. Архитектурно вдохновлён Django Admin Project. — [admin, cms, symfony-bundle]
* [Symfony AI Component](concepts/symfony-ai.md) — Symfony AI — set of components integrating LLM capabilities into PHP applications. Unified interface for OpenAI, Anthropic, Google Gemini, Azure providers. — [ai, llm, rag, vector-database]
* [Symfony Deployment & Production Setup](concepts/symfony-deployment.md) — Symfony deployment requires a fully-featured web server (Nginx or Apache), PHP 8.4+ with core extensions, and Composer for dependency management. — [deployment, production, setup, php]
* [Symfony Flex & Recipes](concepts/symfony-flex.md) — Symfony Flex — Composer plugin that intercepts package installation and automatically configures bundles/packages via predefined recipes. — [composer, flex, recipes]
* [Temporal Decay in Compounding Knowledge Base](concepts/temporal-decay-in-wiki.md) — **Temporal decay (времянное устаревание)** — проблема в compounding knowledge base, когда страницы wiki содержат устаревшие факты или противоречия с более новыми источниками. — [temporal-decay, maintenance, wiki-growth]
* [Testing Strategy & Best Practices](concepts/testing-strategy.md) — Symfony testing integrates with PHPUnit for comprehensive test coverage. — [testing, phpunit, zenstruck-foundry]
* [Twig Templating](concepts/twig-templating.md) — Twig — flexible, fast, secure PHP template engine used by Symfony. Compiles templates down to optimized PHP code with minimal overhead. — [twig, php-templates, template-inheritance, cacheable-blocks, symfony]
* [Workflow & State Machine](concepts/workflow-state-machine.md) — Workflow component provides tools for managing business processes as finite state machines. Objects progress through defined stages (places) via transitions (actions). — [workflow, state-machine, finite-state-machine]

## Сравнения
* [LOOM vs claude-obsidian — Сравнение двух реализаций LLM Wiki Companion](comparisons/loom-vs-claude-obsidian.md) — Сравнительный анализ двух проектов, основанных на одной идее — «LLM Wiki Companion» (persistent knowledge base managed by an AI agent). — [architecture, wiki-framework, ingest, workflow]
* [Symfony UX Initiative — Comparison with AssetMapper](comparisons/symfony-ux-packages.md) — Symfony UX packages (Hotwire, Stimulus, Chart.js integrations) leverage AssetMapper for zero-build frontend asset management. — [symfony]
* [Сравнение: Loomana (Markdown-driven wiki) vs pi-llm-wiki/ (TypeScript platform)](comparisons/llm-wiki-implementations.md) — Оба проекта реализуют **LLM Wiki Pattern** (Andrej Karpathy), но на разных уровнях абстракции. **Loomana** — это **база знаний в markdown**, управляемая вручную через Schema и git. — [llm-wiki, architecture, platform]

## Синтезы
* [Основные способы создания сред разработки Python на NixOS](syntheses/python-nixos-development-environments.md) — Вопрос: какие основные подходы к созданию изолированных сред разработки для [[Python]] существуют в экосистеме [[NixOS]]? Исходный источник — [NixOS Wiki - Python](https://wiki. — [nixos, python, development-environment]
* [Сравнение: RAG vs LLM Wiki Pattern (Compounding Knowledge Base)](syntheses/rag-vs-llm-wiki-pattern.md) — Стандартный RAG и большинство систем работы с файлами (NotebookLM, ChatGPT file uploads) — [rag,llm,knowledge-base]

## Обзоры
* [Wiki Overview — Текущая картина знаний](overview.md) — Wiki содержит **36+ markdown-файлов**: 4 root files (index, log, overview, timeline), 2 entity pages (Symfony, Nvidia), ~18 concept pages, 2 synthesis pages. — [overview, wiki-status]
* [Wiki Snapshot — Активные проекты](snapshot.md) — ### Управление памятью и контекстом ИИ-агента (Memory Architecture) — [snapshot, active-projects]

## Заметки


## Встречи


## Проекты


## Библиография


## Ресурсы


---
*Created: auto-generated | Last updated: 2026-07-04 18:20*

## Хронология
| Дата | Событие |
|------|---------|
| [Timeline](timeline.md) — полная хронологическая лента всех изменений.
