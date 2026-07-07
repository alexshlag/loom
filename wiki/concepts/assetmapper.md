---
tags: [symfony-assetmapper, frontend-pipeline, static-assets]
date: 2026-06-25
sources: [raw/corrected/SRC-2026-06-25-SYMFONY-001/symfony-comprehensive-knowledge.md]
related: [wiki/entities/symfony.md]
---
- [[wiki/entities/symfony.md]] (score: 4)
- [[wiki/concepts/twig-templating.md]] (score: 6, incoming)
- [[wiki/comparisons/symfony-ux-packages.md]] (score: 5, incoming)

# AssetMapper

This page explores AssetMapper as a key concept in our knowledge base.

## Definition

AssetMapper — component for managing modern CSS & JavaScript assets without build pipelines or Node.js dependencies. Uses browser ES module imports and importmaps instead of bundlers like Webpack Encore. Introduced in Symfony 6.3, stable since 6.4+.

## How It Works

### Zero-Build Approach
- Write modern JS/CSS directly — browsers support ES modules natively via `import` statements
- HTTP/2 eliminates need for asset concatenation (multiple small files = fine)
- `assets/` directory → all files mapped and versioned automatically by AssetMapper
- No npm, no webpack.config.js, no Node dependencies

### importmap.php Configuration
```php
// importmap.php at project root
return [
    'app' => ['./assets/app.js'],
    '@hotwire/turbo' => './vendor/@hotwire-turbo/dist/index.js',
    'chart.js' => './vendor/chart.js/dist/chart.js',
];
```

### Key Features
- **Security audits on dependencies** — built-in vulnerability scanning for JS/CSS packages
- **Versioning & caching headers** — auto-generated versioned filenames with cache-busting
- **Dev server** — live reload in development mode without rebuilding
- **importmap:require command** — downloads vendor assets into `assets/vendor/` directory

## Symfony UX Integration

AssetMapper works seamlessly with Symfony UX packages:
- Stimulus controllers automatically bootstrapped via `assets/bootstrap.js`
- Chart.js renders from PHP objects → JS auto-generated and served by AssetMapper
- Turbo frames/scripts handled without manual bundling

## Migration from Webpack Encore

Symfony official sites (symfony.com, live.symfony.com) migrated from Webpack Encore to AssetMapper:
- Simpler maintenance — no Node tooling required
- importmap.php replaces webpack.config.js for asset mapping
- Smaller deployment footprint — no npm packages in production builds

## Best Practices

1. **AssetMapper preferred** over Webpack Encore unless complex build pipeline needed
2. **`importmap.php` at project root** — single source of truth for asset mappings
3. **Use `symfony/importmap` package** — provides AssetMapper integration with Symfony ecosystem
4. **Vendor assets in `assets/vendor/`** — version these files, don't commit to git

## Связи
- [Symfony Entity](entities/symfony.md) — AssetMapper is recommended frontend asset approach for modern Symfony apps
- [Twig Templating](concepts/twig-templating.md) — templates include JS/CSS via `importmap()` function from AssetMapper
- [Symfony UX Initiative](comparisons/symfony-ux-packages.md) — UX packages leverage AssetMapper for zero-build frontend
