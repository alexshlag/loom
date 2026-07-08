---
tags: [docs, <project>, migration]
date: YYYY-MM-DD
type: documentation
category: docs
aliases: []
sources: []
related: [<entity pages in wiki/entities/>]
---

# Migration Guide — <Project/Tool> v<X>.<Y> → v<A>.<B>

<!-- Navigation header — ALWAYS at top -->
[← Previous Topic](../docs/<prev-topic>.md) · [Back to Index](../docs-index.md) · [Next Topic →](<next-topic>.md)

---

## Overview

Brief paragraph explaining the scope of this migration. What changed? Why is an upgrade needed?

<!-- EXAMPLE: Version 2.x introduces a new message routing system that replaces the previous event-driven architecture. Migration requires updating configuration files, replacing deprecated service definitions, and adjusting CI/CD pipelines. -->

---

## Breaking Changes

### <Category 1> — <Impact level>

**Severity:** 🔴 HIGH / 🟡 MEDIUM / 🟢 LOW

<!-- EXAMPLE: Message handler signature changed → Handler classes must now extend `AbstractHandler` instead of implementing `HandlerInterface`. -->

<Details of the breaking change and what needs to be updated>

```
<!-- Before (v<X>.<Y>) -->
<old_code_or_config>

<!-- After (v<A>.<B>) -->
<new_code_or_config>
```

### <Category 2> — <Impact level>

**Severity:** 🔴 HIGH / 🟡 MEDIUM / 🟢 LOW

---

## Migration Steps

### Step 1: Pre-flight checks

Before starting the migration, verify the following:

- [ ] Project version is `<minimum_version>` or above
- [ ] All custom plugins/extensions are compatible with v<A>.<B>
- [ ] Database schema has been backed up (`./scripts/backup-db.sh`)
- [ ] CI/CD pipeline can roll back to `<previous_version>` if needed

<!-- EXAMPLE: Run `composer validate` and check for deprecated dependency warnings -->

### Step 2: Update dependencies

```bash
# Upgrade package manager / framework core
<command_to_update_deps>

# Resolve conflicts
<command_to_resolve>

# Verify upgrade succeeded
<verification_command> 
```

### Step 3: Apply configuration changes

<!-- EXAMPLE: Replace `config/services.yaml` entries with new format -->

| Old Key | New Key | Action Required |
|---------|---------|-----------------|
| `doctrine.orm.metadata_driver` | `doctrine.metadata.xml` | Update all service definitions |
| `framework.cache.default_provider` | `cache.default_redis_dsn` | Add Redis connection string |

**Migration script:**
<!-- EXAMPLE: Provide a shell/python script that auto-migrates config files -->
```bash
./scripts/migrate-config.sh --from v<X>.<Y> --to v<A>.<B> --dry-run
```

### Step 4: Update code / handlers

<!-- EXAMPLE: Show before/after for common patterns -->

**Pattern 1 — Event listeners → Message handlers:**

```php
// Before (v<X>)
class MyListener { public function onFoo(FooEvent $e) { ... } }

// After (v<A>)
#[AsMessageHandler]
class MyHandler implements MessageHandlerInterface {
    public function __invoke(Message $msg): void { ... }
}
```

### Step 5: Run migrations and verify

```bash
# Apply schema updates
<schema_migration_command> --env=prod

# Verify everything works
./scripts/health-check.sh --strict
```

---

## Rollback Plan

If migration fails at any step, revert to previous version:

```bash
# Step 1: Restore database backup
<restore_db_command> --backup=<timestamp>

# Step 2: Revert dependencies
<revert_deps_command> <previous_version>

# Step 3: Restore old configuration files
cp -r config.bak/* config/
```

---

## Known Issues

| Issue | Impact | Workaround | Status |
|-------|--------|------------|--------|
| `<issue_description>` | Brief impact description | Temporary workaround available | Open/Fixed in v<A>.<B+1> |

---

## See Also

- **[Entity page]** — `[wiki/entities/<entity>.md](../entities/<entity>.md)`
- **Upgrade notes**: `[changelog.md](changelog.md)`
- **Configuration guide**: `[<project>-config.md](<project>-config.md)`

<!-- Navigation footer -->
[← Previous Topic](../docs/<prev-topic>.md) · [Back to Index](../docs-index.md) · [Next Topic →](<next-topic>.md)
