---
tags: [framework, php, dependency-injection, service-container, autowiring, di-pattern]
date: 2026-06-25
sources: [raw/corrected/SRC-2026-06-25-SYMFONY-001/symfony-comprehensive-knowledge.md]
related: [wiki/concepts/service-container.md, wiki/concepts/routing-system.md, wiki/concepts/hexagonal-architecture.md]
aliases: ["Symfony", "Symfony Framework", "SF framework"]
---
- [[wiki/concepts/testing-strategy.md]] (score: 8)
- [[wiki/concepts/twig-templating.md]] (score: 6)
- [[wiki/entities/php.md]] (score: 6)
- [[wiki/concepts/testing-strategy.md]] (score: 8)
- [[wiki/concepts/twig-templating.md]] (score: 6)
- [[wiki/entities/php.md]] (score: 6)
- [[wiki/concepts/testing-strategy.md]] (score: 8)
- [[wiki/concepts/twig-templating.md]] (score: 6)
- [[wiki/entities/php.md]] (score: 6)
- [[wiki/concepts/testing-strategy.md]] (score: 8)
- [[wiki/concepts/twig-templating.md]] (score: 6)
- [[wiki/entities/php.md]] (score: 6)
- [[wiki/concepts/symfony-dependency-injection.md]] (score: 5, incoming)
- [[wiki/entities/php.md]] (score: 6, incoming)



# Symfony


Page covering Symfony — entity information, architecture details, and usage patterns.


## Определение

[[Symfony]] — высокопроизводительный PHP веб-фреймворк с открытым исходным кодом, созданный SensioLabs. Фреймворк построен на модульной архитектуре: ядро фреймворка состоит из 16+ [[components]], которые можно использовать как отдельно (PSR-совместимые), так и в составе full-stack framework. Symfony 8.x требует PHP 8.4+, LTS-версии 7.x работают на PHP 8.2+. Центральный механизм — [[service container]] (см. [[concepts/service-container.md]]) для управления зависимостями через [[dependency injection]].

## Ключевые характеристики

### Версионность
| Версия | Минимальный PHP | Статус | Поддержка до |
|--------|----------------|--------|--------------|
| **8.x** | 8.4+ | Latest stable (May 2026) | Следующая major |
| **7.x** | 8.2+ | LTS (Nov 2025) | July 2026+ |

### Архитектура
- **Компоненты** (~40): DependencyInjection, EventDispatcher, HttpKernel, Routing, Cache, Messenger, Workflow, Console, HTTP Foundation (Request/Response), HTTP Client, Form, Validator, Translation, Locale, Serializer, Yaml, Dotenv, Clock, Config, Filesystem, Finder, Process, VarDumper, VarExporter, PropertyInfo, PropertyAccess, PHPUnit Bridge, Contracts, CssSelector, DomCrawler, ExpressionLanguage, BrowserKit, Ldap, Lock, Semaphore, Intl, JsonPath, Mime, OptionsResolver, PSR-7 Bridge, Runtime, TypeInfo, UID
  - Все работают независимо (PSR-compatible)
- **Bundles**: FrameworkBundle, SecurityBundle, DoctrineBridge, TwigBundle и 250+ пакетов от SensioLabs
- **Symfony AI**: Новый компонент (2025+) для унификации LLM-интеграций — ~35 мостов к провайдерам, Store для векторных БД

### Экосистема
- **Symfony Flex**: Composer-плагин для автоматической конфигурации пакетов через recipes
- **Symfony UX**: Stimulus (JS controllers), Turbo (SPA feel), Chart.js, Twig Components, Live Components, React/Vue integration — фронтенд без тяжёлых билд-систем. Полный список: [ux.symfony.com/packages](https://ux.symfony.com/packages)
- **AssetMapper**: Zero-build управление CSS/JS через ES modules и importmaps — замена Webpack Encore
- **Symfony Cloud (Upsun)**: PaaS для хостинга Symfony приложений с автоматическим деплоем, scaling и Blackfire integration
- **Symfony Insight**: Automated quality checks и security audits для PHP проектов

## Паттерны архитектуры

### Hexagonal / Clean Architecture в Symfony 7+
```
Domain/          → чистый PHP, без зависимостей фреймворка
Application/     → импортирует Domain, оркестрирует use cases
Infrastructure/  → имплементирует ports, конвертирует типы
src/Controller/  → только glue-code: routing → service → response
```

### Strangler Fig Pattern
Для постепенного вынесения микро-сервисов из монолита — routing seam на уровне HTTP определяет, куда идёт запрос (старый код vs новый сервис).

## Стандартная структура проекта
```
your_project/
├─ assets/          # CSS, JS, images → AssetMapper
├─ bin/             # Executables (console binary)
├─ config/
│  ├─ packages/     # Per-package configs
│  ├─ routes/       # Routing configuration
│  └─ services.yaml # Service container
├─ migrations/      # Doctrine migrations
├─ public/          # Web root (index.php)
├─ src/             # Application code (auto-loaded as services)
│  ├─ Controller/   # Request handlers
│  ├─ Entity/       # Domain models (Doctrine mapping)
│  ├─ Service/      # Business logic
│  └─ Kernel.php    # Bootstrapper
├─ templates/       # Twig templates
├─ tests/           # PHPUnit + Foundry factories
├─ var/             # Runtime: cache/, logs/, sessions/
└─ vendor/          # Composer dependencies
```

## Связи

### Прямые
- [Service Container & DI](concepts/service-container.md) — центральный механизм фреймворка
- [Routing System](concepts/routing-system.md) — URL mapping к контроллерам
- [Event Dispatcher](concepts/event-dispatcher.md) — система событий
- [Security System](concepts/security-system.md) — аутентификация и авторизация

### Косвенные
- [Hexagonal Architecture](concepts/hexagonal-architecture.md) — паттерн организации кода для Symfony 7+
- [Doctrine ORM Integration](concepts/doctrine-orm.md) — работа с БД
- [Symfony Flex](concepts/symfony-flex.md) — автоматизация установки пакетов
- [Deployment & Production Setup](concepts/symfony-deployment.md) — системные требования, конфигурация сервера, performance tuning
- [Dependency Injection в Symfony](concepts/symfony-dependency-injection.md) — service container, autowiring, compiler passes, service tags

### Экосистемные проекты (Symfony-based)
- [API Platform](entities/api-platform.md) — REST/GraphQL API фреймворк поверх Symfony
- [Sylius](entities/sylius.md) — open-source eCommerce framework на Symfony
- [EasyAdmin Bundle](concepts/easyadmin-bundle.md) — zero-config admin backend, самый популярный выбор для стандартных CRUD задач
- [Sonata Admin Bundle](concepts/sonata-admin-bundle.md) — enterprise-level admin с глубокой кастомизацией
- [Ibexa DXP](entities/ibexa-dxp.md) — enterprise CMS + commerce platform на Symfony

### Взаимное влияние
- Symfony UX → Stimulus + Turbo определяют подход к фронтенду. Live Components обеспечивают real-time reactivity без custom JS.
- Symfony AI → Platform/Agent/Store компоненты расширяют возможности фреймворка (LLM integration, RAG patterns)
- Symfony Cloud + Blackfire → managed hosting и performance profiling
- Symfony Insight → automated code quality and security

## Источники
- `https://symfony.com/doc/current/` — официальная документация
- `https://symfony.com/blog/symfony-the-fast-track-now-for-symfony-8-1` — The Fast Track announcement
