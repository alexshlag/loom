---
tags: [концепция, workflow, state-machine, finite-state-machine]
date: 2026-06-25
sources: [raw/corrected/SRC-2026-06-25-SYMFONY-001/symfony-comprehensive-knowledge.md]
related: [wiki/entities/symfony.md]
---

# Workflow & State Machine

## Definition

Workflow component provides tools for managing business processes as finite state machines. Objects progress through defined stages (places) via transitions (actions). Symfony supports both full **Workflows** (multiple simultaneous places) and strict **State Machines** (single place at a time).

## Core Concepts

### Places, Transitions & Marking
```yaml
framework:
  workflows:
    comment_review:
      type: 'state_machine'
      initial_marking: submitted
      supports:
        - App\Entity\Comment
      places:
        - submitted
        - ham
        - potential_spam
        - spam
        - rejected  
        - published
      transitions:
        accept:       { from: submitted, to: ham }
        might_be_spam:{ from: submitted, to: potential_spam }
        reject_spam:  { from: submitted, to: spam }
        publish:      { from: [submitted, potential_spam], to: published }
```

### Workflow vs State Machine
| Feature | **Workflow** | **State Machine** (subset) |
|---------|-------------|---------------------------|
| **Multiple places** | ✅ Can be in multiple places simultaneously | ❌ Single state only |
| **Validation** | Manual — must explicitly call `applyTransition()` | Automatic on state change |
| **Use case** | Complex multi-stage processes (product assembly) | Simple status tracking (order status, moderation) |

### Marking Store
- Tracks current place(s) of each object
- Configurable: method property (`type: 'method', property: 'state'`) or storage column in database
- Initial marking set via `initial_marking:` configuration

## Symfony 7.4+: Weighted Transitions

New feature for probabilistic routing through workflows:
```yaml
places: [pending, approved, rejected]
transitions:
  approve: { from: pending, to: approved, weight: 2 }
  reject:  { from: pending, to: rejected,  weight: 1 }
# Higher weight = more likely transition when auto-selecting
```

## Best Practices

1. **Use State Machine type** unless you genuinely need multiple simultaneous places (most cases)
2. **Marking store on entity property** — track state via method/property rather than separate column
3. **Workflow definitions in YAML config** — keep transition logic centralized, not scattered across controllers
4. **Audit trail enabled** (`audit_trail.enabled: "%kernel.debug%"`) for production debugging

## Связи
- [Symfony Entity](entities/symfony.md) — Workflow is core Symfony component, used by entities that need state management
- [Hexagonal Architecture](concepts/hexagonal-architecture.md) — Workflow logic belongs in Application layer; entity states managed through workflow transitions
