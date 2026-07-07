---
tags: [easyadmin-admin-ui, symfony-bundle, crud-generation]
date: 2026-07-01
type: documentation
category: concept
sources: [web_search]
related: [wiki/entities/symfony.md, wiki/concepts/sonata-admin-bundle.md]
---

# EasyAdmin Bundle

This page explores EasyAdmin Bundle as a key concept in our knowledge base.

## Definition

EasyAdmin — пакет (bundle) для Symfony, генерирующий admin backends. Создаёт CRUD-интерфейсы автоматически из entity моделей. Бесплатный, быстрый, с полной документацией. Активно развивается: последняя стабильная версия `v5.1.0` (2026-06-20).

## Architecture

### Core Components

| Component | Description |
|-----------|-------------|
| **Dashboard** | Route path + name, admin context, menu items, user menu, translations |
| **CRUD Controllers** | Entities CRUD operations: pagination, search, sorting, forms. Each controller maps to one entity |
| **Design System** | Custom templates, CSS variables, Bootstrap theming, custom JS assets |
| **Fields** | Field configurators, custom fields, form columns, tabs, fieldsets |

### CrudController Pattern

```php
// AbstractCrudController — базовый класс для CRUD операций
abstract class AbstractCrudController extends AbstractController implements CrudControllerInterface
```

CRUD контроллеры — это обычные Symfony controllers, что позволяет:
- Инжектить сервисы стандартным образом
- Использовать `$this->render()`, `$this->isGranted()` и другие shortcuts
- Реализовывать любые кастомные логики внутри операций

### CRUD Actions

| Action | Description |
|--------|-------------|
| `index` | List all records с pagination, search, sorting, filters |
| `new` | Create form + persistence (POST) |
| `edit` | Edit existing record with form validation |
| `delete` | Delete with confirmation + security check |
| `show` | Detail view для single entity (read-only) |

## EasyAdmin 5 — Что изменилось

### Минимальные требования
- PHP >= 8.2
- Symfony >= 6.4 / 7.x / 8.x

### Ключевые нововведения в v5
- Поддержка регулярных Symfony forms в дизайне EasyAdmin
- TypeScript types для events
- Twig component для рендеринга форм
- Улучшенная миграция с v4 → v5 (UPGRADE.md доступен)

## Integration Points

### Doctrine ORM
EasyAdmin автоматически работает с Doctrine ORM entities через annotations/attributes. Никакой boilerplate конфигурации не требуется для базового CRUD.

### Security System
Интегрируется с Symfony Security:
- `isGranted()` проверки на уровне действий
- Entity access control (`isAccessible()`)
- Role-based и permission-based авторизация

### Event Dispatcher
Lifecycle events для CRUD операций:
- `prePersist / postPersist` — create lifecycle
- `preUpdate / postUpdate` — update lifecycle  
- `preDelete / postDelete` — delete lifecycle

## Ecosystem Position

### Популярность (2026)
EasyAdmin остаётся **самым популярным** решением для Symfony admin панелей:
- ~12k+ GitHub stars, active maintainers в SensioLabs/Symfony team
- Создан Javier Eguiluz, который работает в core Symfony ecosystem
- Включён в official Symfony documentation (the-fast-track)

### Сравнение альтернатив

| Solution | Pros | Cons | Best For |
|----------|------|------|----------|
| **EasyAdmin** | Zero-config, modern UI, fast setup, official Symfony docs | Limited bulk actions, less flexible for complex admin | Rapid CRUD, standard admin panels |
| **Sonata AdminBundle** | Full customization, mature ecosystem, advanced features | Steeper learning curve, older codebase, more boilerplate | Complex enterprise admin interfaces |
| **Symfony Maker** | Simple, quick generation | Basic UI only, no real admin panel | Quick prototyping |

### Когда EasyAdmin vs Sonata

- **Выбирай EasyAdmin**: быстрый старт, стандартный CRUD, team не хочет тратить время на конфигурацию
- **Выбирай Sonata**: нужна сложная кастомизация, bulk actions, сложные relations, enterprise-level админка

## Связи

### Прямые
- [Symfony](entities/symfony.md) — requires Symfony >= 6.4 + PHP 8+
- [Sonata Admin Bundle](concepts/sonata-admin-bundle.md) — альтернатива для сложных сценариев
- [Security System (AuthN & AuthZ)](concepts/security-system.md) — role-based access control

### Взаимное влияние
- **→ Sylius**: использует EasyAdmin как primary admin solution (Sylius Admin Area)
- **→ Ibexa DXP**: enterprise customization, но EasyAdmin используется для стандартных задач

> Canonical: `symfony.com/bundles/EasyAdminBundle` — официальная документация и справочник по API.
