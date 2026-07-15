---
tags: [dependency-injection, service-container, autowiring, di-pattern, symfony]
date: 2026-06-25
sources: [raw/corrected/SRC-2026-06-25-SYMFONY-001/symfony-comprehensive-knowledge.md]
related: [wiki/entities/symfony.md, wiki/concepts/symfony-dependency-injection.md]
---
- [[wiki/concepts/cache-system.md]] (incoming, score: 3)
- [[wiki/concepts/hexagonal-architecture.md]] (score: 3)
- [[wiki/concepts/symfony-dependency-injection.md]] (score: 5)
- [[wiki/entities/symfony.md]] (score: 5)

# Service Container & Dependency Injection

This page explores Service Container & Dependency Injection as a key concept in our knowledge base.

## Определение

[[Service Container]] — центральный механизм [[Symfony]], который централизует создание и управление объектами (services). Каждый service — это объект, выполняющий полезную задачу (mailer, database connection, logger). Container автоматически решает зависимости через autowiring на основе type-hints в конструкторах. PSR-11 compatible. Работает параллельно с [[event dispatcher]], [[messenger component]] и другими системными компонентами фреймворка.

## Принципы работы

### Autowiring по умолчанию
```yaml
# config/services.yaml
services:
  _defaults:
    autowire: true
    autoconfigure: true

  App\:
    resource: 'src/'
    exclude: ['tests/']
```
- Container читает type-hints конструктора → автоматически подставляет нужный service
- `autoconfigure: true` — автоматически добавляет теги к services на основе их классов (например, `twig.extension`)

### Autoconfiguration через атрибуты
Symfony 7+ использует PHP attributes для автоконфигурации:
```php
#[AsEventListener]
class MyListener { /* auto-tagged with kernel.listener */ }

#[AsMessageHandler] 
class MyHandler { /* auto-registered for Messenger */ }

#[AsCommand(name: 'app:my-command')]
class MyCommand { /* auto-registered as CLI command */ }
```

### Service Patterns

**Service Locator**: Lazy-loading для больших коллекций потенциальных зависимостей. Используется вместо public services для доступа к множеству сервисов.

**Abstract arguments**: Значения, вычисляемые в runtime через compiler passes — объявляются как абстрактные, затем подставляются pass'ом.

**Named autowiring aliases**: Когда несколько сервисов реализуют один интерфейс — явно указываем нужный alias для type-hint.

## Правила и лучшие практики

1. **Services по умолчанию private** — доступ к ним только через DI, никогда `$container->get()`
2. **Type-hint в конструкторе** — единственный правильный способ получить service
3. **Не создавать bundles для организации логики приложения** — использовать PHP namespaces вместо UserBundle/ProductBundle
4. **YAML для конфигурации services** — friendly к newcomers, concise; PHP config тоже поддерживается
5. **Service tagging** — через autoconfigure или вручную (например `twig.extension`)

## Связи
- [Symfony Entity](entities/symfony.md) — container является ядром фреймворка
- [Testing Strategy](concepts/testing-strategy.md) — контейнер компилируется и линтится перед деплоем
