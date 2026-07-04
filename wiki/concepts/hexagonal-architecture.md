---
tags: [ architecture, hexagonal, clean-architecture, domain-driven-design]
date: 2026-06-25
sources: [raw/corrected/SRC-2026-06-25-SYMFONY-001/symfony-comprehensive-knowledge.md]
related: [wiki/entities/symfony.md, wiki/concepts/symfony-dependency-injection.md]
aliases: ["Hexagonal Architecture", "Ports and Adapters", "DDD architecture"]
---



# Hexagonal Architecture & Clean Patterns in Symfony

## Определение

[[Hexagonal Architecture]] (Ports & Adapters) — architectural pattern that keeps business logic separate from technical details. Domain layer sits at center, depending on nothing. Framework — [[Symfony]], Doctrine, Stripe, any external service — lives at edges as adapters. Modern PHP + Symfony 7+ aligns naturally with tactical [[DDD patterns]] и clean architecture principles.

## Three-Layer Structure

```
Domain/          → Pure PHP classes, no framework dependencies
Application/     → Imports Domain, orchestrates use cases via ports & interfaces  
Infrastructure/  → Implements ports (interfaces), converts between framework/domain types
src/Controller/  → Thin glue: routing → application service → response
```

### Layer Responsibilities

| Layer | Dependencies | Purpose |
|-------|-------------|---------|
| **Domain** | None from project | Core business logic, entities, value objects, domain events |
| **Application** | Domain (ports/interface) | Use case orchestration, command handlers, service calls |
| **Infrastructure** | Application + Domain | DB access via Doctrine, API integrations, external services implementation |

## Tactical DDD Patterns in Symfony 7+

### Ports & Adapters Pattern
- **Ports**: Interfaces that define what the domain needs (e.g., `PaymentGatewayInterface`, `EmailNotifierInterface`)
- **Adapters**: Concrete implementations of ports in Infrastructure layer (e.g., `StripePaymentAdapter`, `MailerEmailAdapter`)

### Benefits for Symfony Developers
- Framework changes don't affect business logic — swap Doctrine → another ORM, or Stripe → PayPal
- Testing domain becomes straightforward: mock interfaces, test pure PHP objects
- Clear separation of concerns: controllers thin, services rich with domain knowledge

## Strangler Fig Pattern for Monoliths

For gradually extracting micro-services from a monolithic Symfony application:

1. **Routing Seam**: Single place in front of monolith where request is decided per-route (old code → new service)
2. **Extracted Capabilities**: Each capability peeled off becomes either service, bounded context, or separate application
3. **HttpKernel composable**: Symfony's HTTP-Less Kernel allows CLI/worker applications alongside web

## Лучшие практики

1. **Domain first** — start with business requirements, define ports before writing infrastructure code
2. **Symfony as adapter** — treat framework as capable tool at edge, not core of application
3. **No bundles for application logic** — use PHP namespaces to organize Domain/Application/Infrastructure directories
4. **Worker applications** — HTTP-Less Kernel in 8.x enables CLI/background jobs without HTTP overhead

## Связи
- [Symfony Entity](entities/symfony.md) — Symfony 7+ architecture recommendations align with hexagonal patterns
- [Service Container](concepts/service-container.md) — DI container wires domain/application/infrastructure services together
