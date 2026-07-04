---
tags: [ api, rest, graphql, symfony]
date: 2026-07-01
type: documentation
category: entity
sources: [web_search]
related: [wiki/entities/symfony.md, wiki/concepts/doctrine-orm.md, wiki/comparisons/api-platform-symfony-rest.md, wiki/entities/sylius.md, wiki/entities/ibexa-dxp.md]
---

# API Platform


Page covering API Platform — entity information, architecture details, and usage patterns.


## Definition

[[API Platform]] — фреймворк для создания гипермедийных REST и GraphQL API. Поддерживает JSON-LD, Hydra, OpenAPI, HAL, JSON:API и CSV одновременно из единого определения ресурса (PHP атрибуты/аннотации). Работает поверх [[Symfony]], Laravel или как standalone библиотека. Тесно интегрирован с [[Doctrine ORM]] для работы с entities и repositories.

## Key Characteristics

### Архитектура
- **Three-tier architecture**: API Platform Backend → Next.js PWA Frontend + Admin Interface
- **Provider/Processor Pattern**: разделение чтения и записи данных через декораторы
- **Schema-first подход**: единый `#[ApiResource]` атрибут генерирует:
  - Full CRUD операции (GET, POST, PUT, DELETE)
  - JSON-LD/Hydra сериализацию по умолчанию
  - OpenAPI 3.1 spec автоматически (`/api/docs`)
  - Pagination, фильтрацию, валидацию
  - Access control через Security System

### Форматы вывода из одного ресурса
| Формат | Описание |
|--------|----------|
| JSON-LD + Hydra | Hypermedia-driven REST по умолчанию |
| OpenAPI / Swagger | Автоматическая документация |
| GraphQL | Опционально включается через конфиг |
| HAL, JSON:API, CSV, XML | Дополнительные форматы через настройки |

## Integration with Symfony

### Установка через Symfony
```bash
composer require api-platform/symfony
```

- Интегрируется с Doctrine ORM для persistence
- Использует Symfony Security System для access control
- Наследует DI Container и Event Dispatcher от Symfony

### Core Components
1. **Schema Generator** — генерирует OpenAPI spec из атрибутов
2. **Data Providers** — извлекают данные (Doctrine, API, external)
3. **Data Processors** — обрабатывают/валидируют входящие данные
4. **Normalizers** — преобразуют объекты в JSON и обратно

## Headless Architecture

API Platform поддерживает headless подход:
- Backend отдаёт только API (JSON-LD/Hydra + GraphQL)
- Frontend (Next.js, Vue, React) требует Node.js runtime для SSR и build pipeline
- [Node.js](entities/nodejs.md) — runtime для JavaScript frontend stack
- Mercure для real-time updates через Server-Sent Events

## Связи

### Прямые
- [Symfony](entities/symfony.md) — основная интеграция через bundle
- [Doctrine ORM](concepts/doctrine-orm.md) — стандартный persistence layer
- [Symfony Security System](concepts/security-system.md) — access control для API endpoints
- [Symfony Event Dispatcher](concepts/event-dispatcher.md) — events для lifecycle операций

#### Взаимное влияние
- **→ Sylius**: использует API Platform для headless commerce (REST/GraphQL API для продуктов, заказов)
- **→ Ibexa DXP**: может использовать API Platform для GraphQL/REST endpoints
- **→ Symfony AI**: Store компонент + RAG pattern интегрируется с API Platform для content management

## Связи между экосистемными проектами

### API Platform ↔ Sylius
API Platform предоставляет REST/GraphQL API слой, который Sylius использует для:
- Product catalog через JSON-LD/Hydra
- Order management endpoints
- Customer data APIs
- OpenAPI documentation из `#[ApiResource]` атрибутов

### API Platform ↔ Ibexa DXP
Ibexa может использовать API Platform для:
- GraphQL schema generation из content types
- REST/HATEOAS APIs для headless commerce
- Symfony AI integration для personalization

> Canonical: `api-platform.com/docs/` — официальная документация
