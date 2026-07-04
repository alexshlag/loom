---
tags: [ testing, phpunit, zenstruck-foundry]
date: 2026-06-25
sources: [raw/corrected/SRC-2026-06-25-SYMFONY-001/symfony-comprehensive-knowledge.md]
related: [wiki/entities/symfony.md]
---

# Testing Strategy & Best Practices

## Definition

Symfony testing integrates with PHPUnit for comprehensive test coverage. Modern Symfony projects use WebTestCase for functional HTTP tests, custom classes for unit tests, and Zenstruck Foundry for expressive data generation. PHPUnit 11+ uses PHP attributes (`#[Test]`, `#[DataProvider]`) — annotations deprecated.

## Test Types

### Unit Tests
- Test individual classes/services without framework context
- Store in `tests/` directory alongside application code
- Use standard PHPUnit assertions and mocking frameworks

### Functional Tests (HTTP)
```php
use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

class UserControllerTest extends WebTestCase {
    public function testShow(): void {
        $client = static::createClient();
        $client->request('GET', '/users/1');
        self::assertResponseIsSuccessful();
        self::assertSelectorTextContent('#username', 'John Doe');
    }
}
```

- `WebTestCase` simulates HTTP requests without real server
- `$client` provides request/response testing API
- Test assertions: `assertResponseIsSuccessful()`, `assertSelectorTextContent()`, etc.

## Zenstruck Foundry

### Factory Pattern for Test Data
Foundry replaces DoctrineFixturesBundle as the recommended test data generation approach:
```php
final class ProductFactory extends ModelFactory {
    protected function getAttributes(): array {
        return [
            'name' => 'Test Product',
            'price' => 99.99,
        ];
    }
}

// Usage in tests:
$product = ProductFactory::createOne(['active' => true]); // persistent entity
$another = ProductFactory::createMany(5); // bulk creation
```

### Benefits
- Expressive, IDE auto-completable factory syntax for Doctrine entities
- Each test creates its own data — no shared state between tests
- Anonymous factories possible; model factories recommended for type safety and IDE support

## Best Practices

1. **Smoke testing URLs** at project start: verify all routes return 200 via PHPUnit data providers
2. **Hard-code raw URLs in tests** (not route names) — catches broken redirects automatically when routes change
3. **Test isolation**: Each test creates its own data → no cleanup dependencies between tests
4. **PHPUnit 11+ attributes only**: No annotations (`/** @test */`) — use `#[Test]`

## Связи
- [Symfony Entity](entities/symfony.md) — Testing is integral part of Symfony development workflow
- [Doctrine ORM](concepts/doctrine-orm.md) — Foundry works with Doctrine entities; replaces fixtures bundle
