---
tags: [twig, php-templates, template-inheritance, cacheable-blocks, symfony]
date: 2026-07-05
sources: [raw/corrected/SRC-2026-06-25-SYMFONY-001/symfony-comprehensive-knowledge.md, raw/corrected/SRC-2026-07-05-TwigOfficial/twig-homepage.md]
related: [wiki/entities/symfony.md]
---
- [[wiki/concepts/assetmapper.md]] (score: 6)
- [[wiki/concepts/assetmapper.md]] (score: 6)
- [[wiki/concepts/assetmapper.md]] (score: 6)
- [[wiki/concepts/assetmapper.md]] (score: 6)
- [[wiki/concepts/assetmapper.md]] (score: 6)
- [[wiki/entities/php.md]] (score: 6, incoming)

# Twig Templating


This page explores Twig Templating as a key concept in our knowledge base.


## Определение

Twig — flexible, fast, secure PHP template engine used by Symfony. Compiles templates down to optimized PHP code with minimal overhead. Provides autoescaping for XSS protection, sandbox mode, and powerful templating syntax.

## Ключевые особенности (по [twig.symfony.com](https://twig.symfony.com/))

### Три столпа

| Столп | Описание |
|-------|----------|
| **Fast** | Twig компилирует шаблоны в оптимизированный PHP-код. Overhead по сравнению с raw PHP — минимальный. |
| **Secure** | Sandbox mode для оценки недоверенного шаблонного кода. Позволяет использовать Twig как template language, когда пользователи могут менять дизайн шаблона. |
| **Flexible** | Гибкий lexer и parser позволяют определять кастомные теги, фильтры и создавать собственную DSL. |

### Почему лучше PHP как шаблонизатор?

PHP сам по себе — шаблонизатор, но без эволюции современных фич:
- **Concise**: Twig синтаксис значительно короче, чем output escaping в чистом PHP
- **Template-oriented syntax**: shortcuts для common patterns (default text при итерации по пустому массиву)
- **Full Featured**: multiple inheritance, blocks, autoescaping — всё из коробки
- **Easy to learn**: syntax оптимизирована для дизайнеров, не мешает работе

### Архитектурные преимущества

- **Extensibility**: open architecture → кастомные tags, filters, functions, operators → собственная DSL
- **Unit tested**: stable library ready for large projects
- **Documented**: online book + full API documentation
- **Clean error messages**: при syntax problem — filename + line number для удобства дебага

### Безопасность (Security Features)

1. **Automatic output escaping** — включается глобально или на уровне блока
2. **Sandboxing** — ограниченный set tags, filters, object methods; можно включить globally или локально для отдельных шаблонов

### Экосистема

Twig используется множеством Open-Source проектов:
- Symfony, Drupal8, eZPublish, phpBB, Matomo, OroCRM
- Фреймворки с поддержкой: Slim, Yii, Laravel, Codeigniter

### Системные требования

Twig 3.x требует **PHP 8.1+** для работы.


## Core Principles

### Template Structure
- **Template inheritance**: Parent templates with `{% block %}` that children override — avoids duplication
- **Variables**: `{{ variable }}` output; `{% if condition %}{% endif %}` logic
- **Functions/Filters**: `{{ name|upper }}`, `{{ render(controller(...)) }}`

### Naming Conventions
- **Snake case** for template names/variables: `user_profile.html.twig` (not `UserProfile`)
- **Underscore prefix** for fragments/partial templates: `_user_metadata.html.twig` — differentiates from complete templates
- **Directory structure**: Templates organized by controller/bundle in `templates/controller_name/action.html.twig`

## Symfony UX Twig Components

Twig components bind PHP objects to templates — reusable UI elements with automatic JS/CSS handling:

```php
#[Component(name: 'alert', template: 'components/alert.html.twig')]
class AlertComponent {
    public function __construct(public string $message, public string $type = 'info') {}
}
```

### Benefits
- Components live in `templates/components/{component_name}.html.twig`
- PHP class + Twig template = single reusable UI unit
- Auto-imports JS/CSS dependencies via Stimulus bridge

## Modern Features (Twig 3.15+)

- **Enhanced for loop filtering**: Filter items directly inside templates
- **Arrow functions in templates**: More concise inline logic
- **Safe filtering**: Better escaping strategies, `html_attr` function for attribute handling
- **Null-safe operators**: Cleaner template syntax for optional data

## Best Practices

1. **Template inheritance** over duplicated blocks — parent → child hierarchy
2. **Fragments prefixed with `_`** to differentiate partials from full templates
3. **Twig Components** for reusable UI elements (alerts, cards, modals)
4. **Autoescaping on by default** — never manually disable unless explicitly needed

## Связи
- [Symfony Entity](entities/symfony.md) — TwigBundle is core bundle of Symfony framework
- [Hexagonal Architecture](concepts/hexagonal-architecture.md) — controllers pass data to templates (view layer in MVC)
