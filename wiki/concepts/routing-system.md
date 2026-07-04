---
tags: [ routing, controllers, attributes]
date: 2026-06-25
sources: [raw/corrected/SRC-2026-06-25-SYMFONY-001/symfony-comprehensive-knowledge.md]
related: [wiki/entities/symfony.md]
---

# Routing System & Controllers


This page explores Routing System & Controllers as a key concept in our knowledge base.


## Определение

[[Routing System]] — ключевой компонент [[Symfony]], который маппит incoming URLs к application code (controller actions). Поддерживает YAML, XML, PHP и Attributes (рекомендуемый формат). Контроллеры — это классы-обработчики HTTP-запросов; в современных проектах они содержат только glue-code: routing → service call → response. Routing тесно связан с [[Symfony security system]] для защиты endpoints через `#[Security]` attributes.

## Принципы работы

### Routing Formats
| Формат | Описание | Статус |
|--------|----------|--------|
| **Attributes** | PHP 8 attributes прямо в controller class | ✅ Recommended |
| YAML | External route definitions | Supported |
| XML | Alternative format | Supported |
| PHP | PHP array-based routes | Supported |

### Routing Attributes (Symfony 7.3+)
```php
#[Route('/users', name: 'app_users_index')]
#[Get('/users/{id}', name: 'app_user_show')]
class UserController extends AbstractController {
    public function show(int $id): Response { ... }
}
```

### Controller Patterns
- **Extend AbstractController**: Для доступа к shortcuts (`$this->render()`, `$this->isGranted()` и т.д.)
- **Service-based controllers**: Альтернатива — `#[AsController]` attribute вместо extends base class
- **Dependency Injection**: Type-hint в action method args или constructor — НИКОГДА `$this->container->get()`
- **Entity Value Resolver**: Автоматически query entity из route param (опционально через Doctrine)

### Attribute Improvements (7.3+)
- `#[AsController]` — enables controller features without extending AbstractController
- Union types support in attributes like `#[CurrentUser]`
- Controller Allowlist + `controller._arguments` для service-based controllers

## Лучшие практики

1. **Attributes preferred** — configuration рядом с кодом, один формат вместо нескольких файлов
2. **Controllers = только glue-code** — business logic в services, не в контроллерах
3. **Entity Value Resolver** использовать только если query простая; для сложных — делать query внутри controller через repository method
4. **Service-based controllers**: `#[Route(...)]` + `controller.service_arguments` tag → public + non-lazy service

## Связи
- [Symfony Entity](entities/symfony.md) — routing маппит URLs к контроллерам Symfony
- [Security System](concepts/security-system.md) — `#[Security]` attribute на controllers для защиты endpoints
