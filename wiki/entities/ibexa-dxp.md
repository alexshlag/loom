---
tags: [dxp, commerce-cms, ecommerce-platform, symfony]
date: 2026-07-01
type: documentation
category: entity
sources: [web_search]
related: [wiki/entities/symfony.md, wiki/entities/api-platform.md, wiki/entities/sylius.md, wiki/concepts/sonata-admin-bundle.md]
---

# Ibexa DXP

Page covering Ibexa DXP — entity information, architecture details, and usage patterns.

## Definition

[[Ibexa DXP]] (Digital Experience Platform) — enterprise-grade CMS + commerce platform на базе [[Symfony]]. Объединяет content management, personalization и eCommerce в единую систему. Доступен как on-premise, cloud или managed Ibexa Cloud PaaS. Работает поверх [[API Platform]] для headless API и используется как альтернатива [[Sylius]] для enterprise commerce.

## Product Editions

### Три основных продукта
| Edition | Focus | Description |
|---------|-------|-------------|
| **Ibexa Headless** | API-first | Decoupled CMS с GraphQL/REST APIs, frontend на любом stack |
| **Ibexa Experience** | Traditional CMS | Full-stack CMS для marketing sites и corporate web |
| **Ibexa Commerce** | B2B eCommerce | Complete commerce platform: products, orders, payments, shipping |

### Open Source vs Commercial
- **Ibexa OSS**: limited open-source edition (community)
- **Commercial editions**: enterprise features, priority support, SLA guarantees

## Architecture

### Symfony Integration
```php
// Ibexa DXP is written mostly in PHP and integrates with Symfony
src/
├── Content/        → CMS content management layer
├── Commerce/       → eCommerce logic (products, orders, checkout)
├── Personalization → Customer journeys, targeting, recommendations
└── Integration/    → API integrations (GraphQL, REST, PIM)
```

### Core Capabilities
| Feature | Description |
|---------|-------------|
| **Content Management** | Multi-site, multi-lingual content editing |
| **GraphQL API** | Type-safe queries for decoupled frontends |
| **REST API** | HAL/HATEOAS endpoints для integrations |
| **PIM Integration** | Product Information Management через remote connectors |
| **Personalization** | Customer journeys, A/B testing, targeting |

## Commerce Features (Ibexa Commerce Edition)

### Transactional Flow
```
Product Listing → Cart Management → Checkout → Payment Processing → Order Management → Shipping → Confirmation
```

### Key Components
- **Shopping List**: B2B bulk ordering with repeat purchases
- **Checkout**: Multi-step checkout с payment gateway integration
- **Order Management**: Order lifecycle tracking и fulfillment
- **Payment Management**: Multiple payment providers (Stripe, PayPal, etc.)
- **Shipping Management**: Carrier integrations, rates, tracking

## Integration with Symfony Ecosystem

### Symfony Components Used
| Component | Ibexa Application |
|-----------|-------------------|
| DependencyInjection | Service container для всех bundles |
| HttpKernel | Request handling для frontend + API |
| Routing | URL mapping к content nodes и commerce endpoints |
| Security | Role-based access для editors/customers/admins |
| DoctrineBridge | ORM integration для content/commerce entities |

### API Platform Integration
Ibexa DXP может использовать:
- **GraphQL Schema**: автоматическая генерация из Ibexa content types
- **REST Endpoints**: HAL/HATEOAS APIs для headless commerce
- **Symfony AI**: personalization engines через RAG + LLM

### Sonata Admin Integration
Enterprise admin customization:
- Custom admin panels через Sonata bundles
- Role-based access для editors/marketers/customers
- Media management с SonataMediaBundle

## Связи между экосистемными проектами

### Ibexa ↔ API Platform
Ibexa использует API Platform для GraphQL/REST endpoints:
- Product catalog через JSON-LD/Hydra
- Order management APIs для headless commerce
- Content delivery APIs для frontend apps

### Ibexa ↔ Sylius
Сравнение в таблице выше, но возможны комбинации:
- **Sylius + API Platform**: headless commerce с REST/GraphQL
- **Ibexa Commerce + Sonata**: enterprise admin panels для commerce management
- **Ibexa Headless + API Platform**: decoupled CMS + GraphQL/REST APIs

## Ecosystem Position

### Vs Sylius
| Параметр | Ibexa DXP | Sylius |
|----------|-----------|--------|
| Focus | CMS + Commerce + Personalization | eCommerce pure-play |
| Architecture | Full-stack CMS with headless option | Decoupled components, headless-first |
| Pricing | Commercial subscription | Open-source core, enterprise support paid |
| PIM Integration | Built-in remote PIM connectors | Requires external integration |
| Personalization | Advanced targeting + journeys | Basic segmentation |

### Vs Magento / Shopify
- Ibexa: Symfony-based, open architecture, enterprise features
- Magento: Zend heritage, complex upgrades
- Shopify: SaaS-only, limited customization

## Связи

### Прямые
- [Symfony](entities/symfony.md) — full-stack integration через bundles
- [API Platform](entities/api-platform.md) — GraphQL/REST API generation
- [Sonata Admin Bundle](concepts/sonata-admin-bundle.md) — enterprise admin customization
- [Doctrine ORM](concepts/doctrine-orm.md) — persistence для content/commerce

### Косвенные
- **Symfony Flex**: установка и конфигурация Ibexa bundles через recipes
- **Symfony UX**: storefront interactivity с Stimulus/Turbo
- **Symfony Security System**: role-based access для editors/marketers/customers/admins

> Canonical: `developers.ibexa.co`, `doc.ibexa.co` — official docs and API references
