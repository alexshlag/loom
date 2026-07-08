---
tags: [docs, <project>, cli-reference]
date: YYYY-MM-DD
type: documentation
category: docs
aliases: []
sources: []
related: [<entity pages in wiki/entities/>]
---

# CLI Commands — <Project/Tool Name>

<!-- Navigation header — ALWAYS at top -->
[← Previous Topic](../docs/<prev-topic>.md) · [Back to Index](../docs-index.md) · [Next Topic →](<next-topic>.md)

---

## Overview

Brief paragraph defining scope. What does the CLI do? Who is the target audience?

<!-- EXAMPLE: The Symfony CLI provides a unified interface for managing applications, deployments, and local development environments. This reference covers all commands with flags and options. -->

---

## Command Reference

### `command` — <Short description>

**Synopsis:**
```bash
<tool> command [options] [arguments]
```

**Description:**
Detailed explanation of what this command does, when to use it vs alternatives.

<!-- EXAMPLE: The `cache:clear` command clears the application cache for the current environment. Useful after code changes or when stale cache entries cause unexpected behavior. -->

**Options:**

| Flag | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `--env <environment>` | string | No | `dev` | Target environment (prod, dev, test) |
| `--no-warmup` | boolean | No | false | Skip cache warmup after clearing |
| `--quiet` | boolean | No | false | Suppress output |

**Arguments:**

| Argument | Type | Required | Description |
|----------|------|----------|-------------|
| `<target>` | string | Optional | Specific cache directory to clear (default: all) |

**Usage Examples:**

```bash
# Clear all caches in dev environment
<tool> cache:clear --env=dev

# Clear only the prod cache without warmup
<tool> cache:clear --env=prod --no-warmup

# Quiet mode — no output, just exit code
<tool> cache:clear --quiet
```

**Exit codes:**
- `0` — Success
- `1` — General error (invalid arguments)
- `2` — Permission denied (cannot write to cache directory)
- `3` — Environment not found (invalid --env value)

<!-- Repeat for each command -->

---

### `command_group subcommand` — <Description>

**Synopsis:**
```bash
<tool> command_group subcommand [options]
```

| Flag | Type | Required | Default | Description |
|------|------|----------|---------|-------------|
| `<flag>` | ... | Yes/No | ... | ... |

**Usage Examples:**
```bash
<tool> command_group subcommand --example=value
```

---

## Configuration Files

CLI commands often read from configuration files:

### `/path/to/config.yml`

<!-- EXAMPLE: `.symfony.yaml` or `config/packages/*.yaml` -->

| Section | Key | Type | Default | Description |
|---------|-----|------|---------|-------------|
| `[cache]` | `driver` | string | `file` | Cache backend driver (file, redis, memcached) |
| `[cache]` | `ttl` | int | 3600 | Time-to-live in seconds |

---

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `<ENV_VAR>` | Yes | — | Purpose of this variable |
| `SYMFONY_ENV` | No | `dev` | Current environment mode |
| `SYMFONY_DEBUG` | No | `0` | Enable debug mode (1) or disable (0) |

---

## See Also

- **[Entity page]** — `[wiki/entities/<entity>.md](../entities/<entity>.md)`
- **API reference**: `[<project>-api.md](<project>-api.md)`
- **Configuration guide**: `[<project>-config.md](<project>-config.md)`

<!-- Navigation footer -->
[← Previous Topic](../docs/<prev-topic>.md) · [Back to Index](../docs-index.md) · [Next Topic →](<next-topic>.md)
