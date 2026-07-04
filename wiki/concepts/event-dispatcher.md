---
tags: [event-dispatcher, symfony-messenger, psr-event, observable-pattern, event-bus]
date: 2026-06-25
sources: [raw/corrected/SRC-2026-06-25-SYMFONY-001/symfony-comprehensive-knowledge.md]
related: [wiki/entities/symfony.md]
---

# Event Dispatcher

## Определение

[[Event Dispatcher]] — компонент [[Symfony]], который обеспечивает decoupled communication между компонентами системы через события. Listeners и Subscribers реагируют на определённые события (например, HTTP request, kernel exception, console command). Поддерж как method-based registration, так и attribute-based (`#[AsEventListener]`). Работает параллельно с [[messenger component]] для async messaging и использует [[service container]] для управления зависимостями..

## Принципы работы

### Events & Listeners
- **Listeners**: Классы с методами для обработки событий. Методы вызываются при dispatch соответствующего event
- **Subscribers**: Классы, реализующие `EventSubscriberInterface` — объявляют subscribed events в static method

```php
#[AsEventListener(priority: 10)] // higher = earlier execution
class MyListener {
    public function onKernelRequest(RequestEvent $event): void { ... }
}
```

### Priority & Ordering
- Listeners execute in priority order (higher first)
- Default priority = 0; positive values = earlier, negative = later
- Critical events: `kernel.request`, `kernel.controller`, `kernel.response`, `kernel.exception`

## Лучшие практики

1. **Используйте attributes** — `#[AsEventListener]` auto-tags и регистрирует listener
2. **Не наруайте принцип единственной ответственности** — один listener = одна логика, не mixed concerns
3. **Понимайте lifecycle events** — kernel.request → controller → response → exception для правильного hooking

## Связи
- [Symfony Entity](entities/symfony.md) — EventDispatcher встроен в HttpKernel и FrameworkBundle
- [Service Container](concepts/service-container.md) — listeners/subscribers are services, auto-wired and auto-tagged
