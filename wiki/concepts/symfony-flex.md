---
tags: [ composer, flex, recipes]
date: 2026-06-25
sources: [raw/corrected/SRC-2026-06-25-SYMFONY-001/symfony-comprehensive-knowledge.md]
related: [wiki/entities/symfony.md]
---
- [[wiki/entities/symfony.md]] (score: 5)

# Symfony Flex & Recipes

This page explores Symfony Flex & Recipes as a key concept in our knowledge base.

## Определение

Symfony Flex — Composer plugin that intercepts package installation and automatically configures bundles/packages via predefined recipes. Default Symfony skeleton starts minimal (only `flex` + `framework-bundle`) and grows organically through recipe-driven installs.

## How It Works

### Installation Flow
1. User runs: `composer require twig` 
2. Flex intercepts Composer install → finds matching recipe from symfony/recipes repository
3. Recipe manifest.json defines which files/directories to create/update
4. Auto-generated config files, routes, services appear in project automatically

### Default Minimal Skeleton
```json
{
  "require": {
    "symfony/flex": "^2.0",
    "symfony/framework-bundle": "^7.4"
  }
}
```
No Twig? No problem — `composer require twig` adds it via recipe automatically.

### Recipe Structure
- **manifest.json**: Defines files to create, directories to add, commands to run during install/update
- **Official recipes**: In symfony/recipes repository (endorsed by Symfony Core Team)
- **Contributed recipes**: Community-maintained in contrib repository

## Best Practices

1. **Start minimal** — only flex + framework-bundle initially; add packages via `composer require` → recipes handle config
2. **Private recipe repositories** for internal bundles — custom install tasks for proprietary packages
3. **Don't create recipes for bundles** unless they need significant auto-configuration beyond simple bundle registration

## Связи
- [Symfony Entity](entities/symfony.md) — Flex powers the default installation workflow recommended by Symfony docs
- [Service Container](concepts/service-container.md) — Recipes often auto-generate services.yaml configurations
