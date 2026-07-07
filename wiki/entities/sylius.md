---
tags: [ ecommerce, symfony, headless]
date: 2026-07-01
type: documentation
category: entity
sources: [web_search]
related: [wiki/entities/symfony.md, wiki/concepts/hexagonal-architecture.md, wiki/entities/api-platform.md, wiki/concepts/sonata-admin-bundle.md, wiki/entities/ibexa-dxp.md]
---
- [[wiki/entities/ibexa-dxp.md]] (incoming, score: 4)
- [[wiki/entities/api-platform.md]] (incoming, score: 4)
- [[wiki/concepts/sonata-admin-bundle.md]] (score: 6)
- [[wiki/entities/ibexa-dxp.md]] (score: 6, incoming)
- [[wiki/entities/api-platform.md]] (score: 6, incoming)

# Sylius

Page covering Sylius — entity information, architecture details, and usage patterns.

## Definition

[[Sylius]] — open-source eCommerce framework на базе [[Symfony Full Stack]]. Архитектурно построен на decoupled компонентах и bundles с сильным фокусом на тестирование (BDD workflow) и гибкость. Поддерживает headless подход через встроенный REST API. Работает поверх [[API Platform]] для headless API и использует [[hexagonal architecture]] для организации кода.

## Architecture Overview

### Layered Architecture
```
src/Domain/          → чистый PHP, бизнес-логика без Symfony
src/Application/     → use cases, orchestration
Infrastructure/Sylius → adapters к Sylius компонентам
```

### Компоненты (decoupled)
Каждый компонент — standalone библиотека:
- **Taxation** — расчёт налогов (не зависит от продуктов)
- **Payment** — payment gateways и транзакции
- **Shipping** — методы доставки
- **Order Management** — lifecycle заказов

### Bundles Integration Layer
Symfony bundles интегрируют компоненты в фреймворк:
- `SyliusCoreBundle` — ядро платформы
- `SyliusAdminBundle` — админ-панель (SUA)
- `SyliusShopBundle` — storefront для клиентов
- `SyliusApiBundle` — REST/GraphQL API endpoints

## Key Features

### Headless Commerce
- REST API для продуктов, заказов, клиентов
- GraphQL поддержка через Sylius API
- Mercure для real-time updates cart/order status

### Admin Panel (SUA)
- Built-in Symfony Admin UI
- Customizable через Twig и JS
- Role-based access control

### Testing Culture
- BDD workflow по умолчанию (Behat интеграция)
- Strong testing practices в коде
- Feature tests для business logic

## Integration with Symfony Ecosystem

### Symfony Components used
| Component | Применение |
|-----------|------------|
| DependencyInjection | DI Container для всех services |
| HttpKernel | Request handling для storefront и API |
| Routing | URL mapping к controllers |
| Security | Access control для admin и customers |
| DoctrineBridge | ORM интеграция для persistence |

### API Platform Integration
Sylius может использовать API Platform для:
- REST/GraphQL endpoints вместо custom controllers
- JSON-LD/Hydra сериализации продуктов и заказов
- OpenAPI documentation из атрибутов ресурсов

### Sonata Admin Integration
Вместо Sylius SUA (Symfony Admin UI) можно использовать Sonata:
- Custom admin panels через Sonata bundles
- Role-based access для managers/customers
- Media management с SonataMediaBundle

### API Platform Integration
Sylius может использовать API Platform для:
- REST/GraphQL endpoints вместо custom controllers
- JSON-LD/Hydra сериализации продуктов и заказов
- OpenAPI documentation из атрибутов ресурсов

## Ecosystem Position

### Vs Ibexa DXP
| Параметр | Sylius | Ibexa DXP |
|----------|--------|-----------|
| Open Source | Полностью open-source | Commercial (OSS edition limited) |
| Focus | eCommerce pure-play | CMS + Commerce + Personalization |
| Pricing | Free core, paid support/enterprise | Subscription model |
| Flexibility | Higher (decoupled components) | Enterprise-grade with vendor support |

### Vs Magento
- Sylius: Symfony-based, decoupled architecture, BDD-first
- Magento: Zend/Laravel heritage, monolithic modules

## Связи

### Прямые
- [Symfony](entities/symfony.md) — полная интеграция через bundles
- [API Platform](entities/api-platform.md) — headless API layer
- [Doctrine ORM](concepts/doctrine-orm.md) — persistence для продуктов/заказов
- [Hexagonal Architecture](concepts/hexagonal-architecture.md) — DDD структура проекта

### Косвенные
- **Symfony Flex** — установка и конфигурация bundles через recipes
- **Symfony UX** — Stimulus/Turbo для storefront interactivity
- **Symfony Security System** — role-based access для admin/shop

> Canonical: `docs.sylius.com`, `github.com/sylius/sylius`
