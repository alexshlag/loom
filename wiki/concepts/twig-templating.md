---
tags: [концепция, twig, templating]
date: 2026-06-25
sources: [raw/sources/SRC-2026-06-25-SYMFONY-001/symfony-comprehensive-knowledge.md]
related: [wiki/entities/symfony.md]
---

# Twig Templating

## Определение

Twig — flexible, fast, secure PHP template engine used by Symfony. Compiles templates down to optimized PHP code with minimal overhead. Provides autoescaping for XSS protection, sandbox mode, and powerful templating syntax.

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
