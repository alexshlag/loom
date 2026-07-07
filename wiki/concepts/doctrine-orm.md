---
tags: [ doctrine, orm, entities, repositories]
date: 2026-06-25
sources: [raw/corrected/SRC-2026-06-25-SYMFONY-001/symfony-comprehensive-knowledge.md]
related: [wiki/entities/symfony.md]
---
- [[wiki/entities/symfony.md]] (score: 5)

# Doctrine ORM Integration

This page explores Doctrine ORM Integration as a key concept in our knowledge base.

## Определение

[[Doctrine ORM]] — object-relational mapper для PHP, интегрированный в [[Symfony]] через DoctrineBridge. Позволяет работать с database через PHP entities and repositories instead of raw SQL. Symfony recommends using PHP attributes for entity mapping metadata. Doctrine работает параллельно с [[service container]], который управляет зависимостями между entities и repositories.

## Entity Pattern

### Basic Entity Structure
```php
#[Entity(repositoryClass: ProductRepository::class)]
class Product {
    #[Id, Column] private ?int $id = null;
    #[Column(length: 255)] private string $name = '';

    public function getId(): ?int { return $this->id; }
}
```

### Best Practices
- **PHP attributes** for mapping (not annotations) — recommended format since Symfony 4+
- **Repository classes**: Extend `EntityRepository` for custom query logic isolation from controllers
- **Private properties with getters/setters** or public properties depending on Doctrine version compatibility

## Repository Pattern

### Custom Repositories
```php
use Doctrine\ORM\EntityRepository;

final class ProductRepository extends EntityRepository {
    /** @return Product[] */
    public function findActiveProducts(): array {
        return $this->createQueryBuilder('p')
            ->where('p.active = :active')
            ->setParameter('active', true)
            ->getQuery()
            ->getResult();
    }
}
```

### Repository Benefits
- Query logic isolated from controllers → reusable, testable
- DQL queries encapsulated in repository methods
- Custom finder patterns (e.g., `findByAuthor()`, `findRecent()`)

## Entity Relationships

### Association Types
| Type | Attribute | Описание |
|------|-----------|----------|
| ManyToOne | `#[ManyToOne]` | Multiple entities reference one parent entity |
| OneToMany | `#[OneToMany]` | One entity has collection of related entities |
| ManyToMany | `#[ManyToMany]` | Entities can relate to many others (junction table) |
| OneToOne | `#[OneToOne]` | Single entity references single other entity |

### Multiple Entity Managers
- Support for multiple DB connections and entity managers per application
- Each manager handles specific entities/databases independently

## Лучшие практики

1. **PHP attributes over annotations** — more convenient, integrated with PHP 8+ syntax
2. **Custom repositories for complex queries** — never write DQL in controllers
3. **Separation of concerns**: Entity = data model + basic logic; Repository = query patterns; Service = business orchestration
4. **Use `make:entity` command** for auto-generating entity classes with Doctrine mapping

## Связи
- [Symfony Entity](entities/symfony.md) — Doctrine ORM является основным ORM для Symfony
- [Testing Strategy](concepts/testing-strategy.md) — Zenstruck Foundry replaces DoctrineFixturesBundle for test data generation
