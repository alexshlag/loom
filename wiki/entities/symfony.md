---
tags: [entity, framework, php]
date: 2026-06-25
sources: [raw/sources/SRC-2026-06-25-SYMFONY-001/symfony-comprehensive-knowledge.md]
related: [wiki/concepts/service-container.md, wiki/concepts/routing-system.md, wiki/concepts/hexagonal-architecture.md]
---

# Symfony

## Определение

Symfony — высокопроизводительный PHP веб-фреймворк с открытым исходным кодом, созданный SensioLabs. Фреймворк построен на модульной архитектуре: ядро фреймворка состоит из 16+ компонентов, которые можно использовать как отдельно (PSR-совместимые), так и в составе full-stack framework. Symfony 8.x требует PHP 8.4+, LTS-версии 7.x работают на PHP 8.2+.

## Ключевые характеристики

### Версионность
| Версия | Минимальный PHP | Статус | Поддержка до |
|--------|----------------|--------|--------------|
| **8.x** | 8.4+ | Latest stable (May 2026) | Следующая major |
| **7.x** | 8.2+ | LTS (Nov 2025) | July 2026+ |

### Архитектура
- **Компоненты**: DependencyInjection, EventDispatcher, HttpKernel, Routing, Cache, Messenger, Workflow, Console, HTTP-клиент, Form, Validator, Translation, Locale, Serializer, Yaml, Dotenv — все работают независимо
- **Bundles**: FrameworkBundle, SecurityBundle, DoctrineBridge, TwigBundle и 250+ пакетов от SensioLabs
- **Symfony AI**: Новый компонент (2025+) для унификации LLM-интеграций — ~35 мостов к провайдерам, Store для векторных БД

### Экосистема
- **Symfony Flex**: Composer-плагин для автоматической конфигурации пакетов через recipes
- **Symfony UX**: Stimulus (JS), Turbo (SPA feel), Chart.js, Twig Components — интеграция фронтенда без тяжёлых билд-систем
- **AssetMapper**: Zero-build управление CSS/JS через ES modules и importmaps — замена Webpack Encore

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
- [Service Container & DI](wiki/concepts/service-container.md) — центральный механизм фреймворка
- [Routing System](wiki/concepts/routing-system.md) — URL mapping к контроллерам
- [Event Dispatcher](wiki/concepts/event-dispatcher.md) — система событий
- [Security System](wiki/concepts/security-system.md) — аутентификация и авторизация

### Косвенные
- [Hexagonal Architecture](wiki/concepts/hexagonal-architecture.md) — паттерн организации кода для Symfony 7+
- [Doctrine ORM Integration](wiki/concepts/doctrine-orm.md) — работа с БД
- [Symfony Flex](wiki/concepts/symfony-flex.md) — автоматизация установки пакетов

### Взаимное влияние
- Symfony UX → Stimulus + Turbo определяют подход к фронтенду
- Symfony AI → Platform/Agent/Store компоненты расширяют возможности фреймворка

## Источники
- [symfony-comprehensive-knowledge.md](raw/sources/SRC-2026-06-25-SYMFONY-001/symfony-comprehensive-knowledge.md) — основной источник данных
- `https://symfony.com/doc/current/` — официальная документация
- `https://symfony.com/blog/symfony-the-fast-track-now-for-symfony-8-1` — The Fast Track announcement
