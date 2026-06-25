---
tags: [концепция, messenger, messaging, queue]
date: 2026-06-25
sources: [raw/sources/SRC-2026-06-25-SYMFONY-001/symfony-comprehensive-knowledge.md]
related: [wiki/entities/symfony.md]
---

# Messenger Component

## Definition

Messenger — component for sending and receiving messages to/from other applications or via message queues. Provides a message bus that can handle messages immediately (sync) or send them through transports (queues) for async processing. PSR-compliant, works independently outside Symfony framework.

## Core Architecture

### Message Bus Pattern
```php
// Send a message
$bus->dispatch(new SendEmailMessage('user@example.com', 'Welcome!'));

// Handler registered via attribute
#[AsMessageHandler]
class EmailHandler {
    public function __invoke(SendEmailMessage $message): void {
        // Process the message (send email, log, etc.)
    }
}
```

### Sync vs Async Processing
| Mode | Описание | Use Case |
|------|----------|----------|
| **Sync** (default) | Message handled immediately when dispatched | Simple operations, no queue needed |
| **Async via Transports** | Message serialized → sent to transport → processed later | Email sending, file processing, external API calls |

### Transport Configuration
```yaml
framework:
  messenger:
    transports:
      async: 'doctrine://app?queue_name=async'
      async_priority_high: 'doctrine://app?queue_name=high&priority=100'
```

## Best Practices (Symfony 7.4+)

### Priority Queues (New in 7.4)
Multi-level transports for priority-based processing:
- `async_priority_high` — critical operations processed first
- `async_priority_medium` — standard queue
- `async_priority_low` — background/background tasks

### Supported Transports
| Transport | Описание |
|-----------|----------|
| **Doctrine** | Queue stored in database table (simplest setup) |
| **AMQP/RabbitMQ** | Production-grade message broker |
| **Redis** | High-performance queue backend |
| **Native PHP** | File-based queue for simple setups |

## Best Practices

1. **Async for non-critical operations** — email, notifications, file processing → send to transport instead of blocking request
2. **Priority queues in 7.4+** — separate critical vs background work across different transports
3. **Handler attributes preferred** — `#[AsMessageHandler]` auto-tags handlers (no manual config)
4. **Fault tolerance** — configure retry strategies, dead letter channels for failed messages

## Связи
- [Symfony Entity](wiki/entities/symfony.md) — Messenger is core Symfony component
- [Service Container](wiki/concepts/service-container.md) — Message handlers are services with `#[AsMessageHandler]` auto-tagging
- [Event Dispatcher](wiki/concepts/event-dispatcher.md) — Both patterns: EventDispatcher for events, Messenger for messages
