---
tags: [concept, admin, cms, symfony-bundle]
date: 2026-07-01
type: documentation
category: concept
sources: [web_search]
related: [wiki/entities/symfony.md, wiki/concepts/service-container.md, wiki/entities/sylius.md, wiki/entities/ibexa-dxp.md]
---

# Sonata Admin Bundle

## Definition

Sonata Admin — пакет (bundle) для Symfony, генерирующий admin panels и CRUD interfaces. Архитектурно вдохновлён Django Admin Project. Предоставляет declarative подход к управлению моделями через YAML/XML/PHP конфигурацию.

## Architecture

### Core Bundles
| Bundle | Назначение |
|--------|------------|
| `SonataAdminBundle` | Ядро: core libraries, services, dashboard |
| `SonataDoctrineORMAdminBundle` | Интеграция с Doctrine ORM |
| `SonataDoctrineMongoDBAdminBundle` | Интеграция с MongoDB |
| `SonataDoctrinePhpcrAdminBundle` | Интеграция с PHPCR |

### Dependency Injection Pattern
Каждый Admin service автоматически получает:
- `model_manager` — менеджер моделей (ORM/MongoDB/PHPCR)
- `data_source` — источник данных для форм
- `form_contractor` — builder для forms
- `list_builder` / `show_builder` — builders для list/show views
- `datagrid_builder` — построитель фильтров и pagination

### CRUDController Actions
Стандартные операции:
| Action | Description |
|--------|-------------|
| `list` | List all records с pagination/filters |
| `create` | Create form + persistence |
| `edit` | Edit existing record |
| `delete` | Delete with confirmation |
| `show` | Detail view для single entity |

## Integration Points

### Symfony DI Container
- Admin services autowired через стандартный Service Container
- Extends `AbstractAdmin` для декларативной конфигурации
- Реализует `AdminInterface` для custom implementations

### Event Dispatcher Integration
```php
// Events dispatched during CRUD operations
prePersist / postPersist   → create lifecycle
preUpdate / postUpdate    → update lifecycle
preDelete / postDelete    → delete lifecycle
preBatch / postBatch      → batch operations
```

## Ecosystem Usage

### Common Sonata Bundles
| Bundle | Purpose |
|--------|---------|
| `SonataMediaBundle` | Media manager (images, documents) |
| `SonataUserBundle` | User management + security integration |
| `SonataPageBundle` | CMS-like page management |
| `SonataNewsBundle` | Blog/news functionality |
| `SonataClassificationBundle` | Category/tag management |

### Alternative Admin Solutions
| Solution | Pros | Cons |
|----------|------|------|
| **Symfony Maker** | Simple, quick CRUD generation | Basic UI only |
| **EasyAdmin** | Modern UI, zero-config admin | Less flexible than Sonata |
| **Sonata AdminBundle** | Full customization, mature ecosystem | Steeper learning curve, older codebase |

## Связи

### Прямые
- [Symfony](entities/symfony.md) — requires Symfony >= 6.4 + PHP 8+
- [Service Container & DI](concepts/service-container.md) — admin services autowired through DI
- [Security System](concepts/security-system.md) — role-based access for admin panels

### Взаимное влияние
- **→ Sylius**: может использовать Sonata Admin для custom admin interfaces (вместо Sylius SUA)
- **→ Ibexa DXP**: enterprise admin customization через Sonata bundles
- **→ API Platform**: REST API + Sonata Admin = traditional admin + headless API combo

> Canonical: `docs.sonata-project.org` — официальная документация
