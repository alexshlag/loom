---
tags: [symfony, dependency-injection, service-container, autowiring, compiler-passes, service-tags]
date: 2026-07-06
type: documentation
category: concept
sources: [
  "https://symfony.com/doc/current/service_container.html",
  "https://symfony.com/doc/current/service_container/autowiring.html",
  "https://symfony.com/doc/current/components/dependency_injection.html"
]
aliases: ["DI Symfony", "Symfony Container"]
related: [wiki/entities/symfony.md, wiki/concepts/service-container.md, wiki/concepts/symfony-flex.md]
---

# Dependency Injection в Symfony


Dependency Injection (DI) — паттерн проектирования, позволяющий внедрять зависимости объекта извне. В Symfony DI является **центральным архитектурным механизмом** и реализуется через контейнер сервисов (Service Container), который управляет созданием, конфигурацией и жизненным циклом всех объектов приложения.

---

## Архитектура Service Container

### ContainerBuilder — фундаментальный класс
`ContainerBuilder` из `Symfony\Component\DependencyInjection` — основной класс для управления зависимостиями:
```php
$container = new ContainerBuilder();
$container->register('my_service', App\Service\MyService::class);
$container->compile(); // оптимизация и инлайн
```

### Жизненный цикл контейнера в Symfony Framework Bundle
1. **Registration** — сервисы регистрируются через `services.yaml` или атрибуты/аннотации
2. **Autowiring & Autoconfiguration** — автоматически анализируются type hints и теги сервисов
3. **Compilation** — `ContainerBuilder::compile()` оптимизирует контейнер (инлайн публичные сервисы, удаляет неиспользуемые)
4. **Dumper** — генерируется PHP-класс контейнера для production

---

## Autowiring — автоматическое внедрение

### Как работает
Autowiring читает type hints в сигнатурах конструктора и автоматически подставляет нужные сервисы:
```php
class OrderService {
    public function __construct(
        private LoggerInterface $logger,
        private EntityManagerInterface $entityManager,
        private RateLimiterFactory $limiter
    ) {}
}
// Контейнер автоматически найдёт и внедрит все три зависимости
```

### Правила предсказуемости
Symfony's autowiring **предсказуем**: если не абсолютно ясно, какую зависимость передать — вы получите actionable exception. Это предотвращает "магию" в пользу явных определений.

---

## Service Definitions — определения сервисов

### YAML Configuration (default)
```yaml
# config/services.yaml
services:
    # default configuration для всех сервисов
    _defaults:
        autowire: true
        autoconfigure: true
        public: false  # best practice: все сервисы приватные
    
    # конкретный сервис — автоматически зарегистрирован
    App\Service\OrderService: ~
    
    # явное определение с параметрами
    App\Service\PaymentProcessor:
        arguments:
            $apiKey: '%env(PAYMENT_API_KEY)%'
            $logger: '@logger'
```

### Service Tag System
Symfony использует **теги** для маркировки сервисов и их ролей в экосистеме фреймворка:

| Тег | Назначение | Пример |
|-----|-----------|--------|
| `tagged` | Группирует сервисы по назначению | `kernel.event_listener`, `messenger.message_handler` |
| `service_locator` | Создаёт ServiceLocator для опциональных зависимостей | `@.tagged` синтаксис в DI |
| `container.service_locator` | Автоматическое создание locator'а | `#[AsTaggedItem]` атрибут |

### Compiler Passes — компиляционные passes
Compiler Passes позволяют **манипулировать контейнером** перед финальной сборкой:

```php
class MyCompilerPass implements CompilerPassInterface {
    public function process(ContainerBuilder $container): void {
        // Находим все сервисы с тегом 'my_tag'
        $taggedServices = $container->findTaggedServiceIds('my_tag');
        
        foreach ($taggedServices as $id => $tags) {
            // Модифицируем или добавляем зависимости
            // Инлайн публичные сервисы, удаляем неиспользуемые
        }
    }
}
```

**Типичные use cases для Compiler Passes:**
- Автоматическая регистрация всех event listeners по тегу
- Создание ServiceLocator'ов из помеченных сервисов
- Инлайн публичных сервисов для оптимизации production
- Conditional service registration (например, только в dev environment)

---

## Best Practices

### 1. Private Services First
```yaml
# ✅ Правильно
defaults:
    public: false  # все сервисы приватные по умолчанию
    
# ❌ Избегайте
$container->get('some_service')  # прямой доступ к контейнеру
```
**Правило:** используйте Dependency Injection для получения зависимостей, не `$container->get()`.

### 2. Explicit over Implicit
Когда autowiring неоднозначен — явно определите аргументы:
```yaml
services:
    App\Controller\CheckoutController:
        arguments:
            $cartService: '@App\Service\CartService'
```

### 3. Service Locator Pattern для опциональных зависимостей
```php
class PaymentProcessor {
    public function __construct(
        private ServiceLocatorInterface $paymentGateways  // только нужные
    ) {}
}
// Register with tagged service locator:
$container->registerForServiceDependencies(
    'PaymentProcessor', 
    new TaggedIteratorResolver('payment_gateway')
);
```

### 4. Autoconfigure — автоматическая конфигурация по class inheritance
Большинство сервисов с `autoconfigure: true` автоматически получают нужные теги и зависимости на основе наследования от базовых классов Symfony.

---

## DI в Hexagonal Architecture

DI является **ключевым инструментом** для внедрения паттерна Hexagonal Architecture в Symfony:

```
Domain/              → чистый PHP, без DI
Application/         → использует DI для оркестрации use cases
Infrastructure/      → имплементирует порты как сервисы с тегами
src/Controller/      → только glue-code через DI
```

- **Ports** (interfaces) — определяются в Domain/Application layer
- **Adapters** (implementations) — регистрируются в DI с тегами
- **Use cases** — получают зависимости через constructor injection

---

## Связи с другими концептами

| Концепт | Как связан |
|---------|-----------|
| [Service Container](concepts/service-container.md) | Контейнер сервисов — реализация DI в Symfony |
| [Hexagonal Architecture](concepts/hexagonal-architecture.md) | DI позволяет внедрять порты и домены |
| [Symfony Flex](concepts/symfony-flex.md) | Recipes автоматически генерируют services.yaml конфигурации |
| [Messenger Component](concepts/messenger-component.md) | Message handlers регистрируются через теги в DI |

---

## Источники

- `https://symfony.com/doc/current/service_container.html` — Service Container documentation
- `https://symfony.com/doc/current/components/dependency_injection.html` — DependencyInjection Component reference
- `raw/sources/SRC-2026-06-28-SYMFONY-DI-001/symfony-di.md` — исходный источник

---

Обновлено 2026-07-06 — расширена информация о service definitions, compiler passes и service tags.
