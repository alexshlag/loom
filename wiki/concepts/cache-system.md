---
tags: [ cache, psr6, tags, invalidation]
date: 2026-06-25
sources: [raw/corrected/SRC-2026-06-25-SYMFONY-001/symfony-comprehensive-knowledge.md]
related: [wiki/entities/symfony.md]
---

# Cache System

## Definition

Symfony Cache component provides PSR-6 and PSR-16 compliant caching with advanced features: tag-based invalidation, cache stampede protection, multiple adapters. Designed for performance — pre-configured adapters for most common backends (Redis, Memcached, APCu, Doctrine DBAL).

## Architecture: Pools & Adapters

### Cache Contracts (Simpler) vs PSR-6 (Full Featured)
| Layer | Interface | Описание |
|-------|-----------|----------|
| **Cache Contracts** | Simpler API | Easier to use, less features |
| **PSR-6** | Generic caching system | Pools + items pattern |

### Components
```yaml
framework:
  cache:
    apps:
      app_cache: apcu
    adapters:
      redis_pool:
        name: 'cache.redis'
        provider: 'redis://localhost'
```

- **Pool**: Logical repository for cache items — each pool has independent namespace (no conflicts)
- **Adapter**: Template for creating pools — defines how/where data is stored
- **Provider**: Service that connects to storage backend (Redis, Memcached etc.)

## Supported Adapters

| Adapter | Use Case |
|---------|----------|
| **APCu** | In-memory per-server cache (simplest setup) |
| **Redis** | Shared memory across servers; `redis_tag_aware` variant supports tags natively |
| **Memcached** | Distributed caching with tag support |
| **Doctrine DBAL** | Store in database tables (when Redis/Memcached unavailable) |
| **Filesystem** | File-based cache for simple setups |
| **PDO** | Generic database-backed cache |

## Tag-Based Invalidation

### How It Works
- Attach tags to cached items: `$pool->save($item, $tags: ['user_123', 'products'])`
- Invalidate by tag: `$pool->invalidateTags(['products'])` → removes ALL items with that tag
- Solves data dependency problem — no manual item tracking needed

### Use Cases for Tags
- **User-specific caching**: Tag items by user ID → invalidate when user updates profile
- **Cache stampede protection**: Lock mechanism prevents concurrent cache misses from hammering backend
- **Expiration fallback**: Time-based expiration as backup for tag-based invalidation

## Best Practices

1. **Use Redis/Memcached** in production — shared memory across multiple servers
2. **Tag-based invalidation** preferred over manual item deletion — automatic dependency management
3. **Stampede protection** enabled by default on tag-aware adapters — no extra config needed
4. **Separate pools per concern** — different cache namespaces for different data types (e.g., `api_cache`, `template_cache`)

## Связи
- [Symfony Entity](entities/symfony.md) — Cache is core Symfony component, pre-configured in FrameworkBundle
- [Service Container](concepts/service-container.md) — Cache pools are autowired services; providers injected via container
