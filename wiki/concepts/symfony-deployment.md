---
tags: [deployment, production, setup, php]
date: 2026-07-01
type: documentation
category: concept
sources: ["https://symfony.com/doc/current/setup.html", "https://symfony.com/doc/current/deployment.html"]
related: ["wiki/entities/symfony.md", "wiki/concepts/service-container.md", "wiki/concepts/doctrine-orm.md", "wiki/concepts/twig-templating.md"]
---

# Symfony Deployment & Production Setup

This page explores Symfony Deployment & Production Setup as a key concept in our knowledge base.

## Definition

Symfony deployment requires a fully-featured web server (Nginx or Apache), PHP 8.4+ with core extensions, and Composer for dependency management. Production environment needs OPcache, cache warming, and proper routing configuration — local development uses the optional Symfony Local Web Server binary.

## System Requirements

### Minimum Stack

| Component | Version / Extension | Notes |
|-----------|---------------------|-------|
| **PHP** | 8.4+ (latest) or 8.2+ (LTS 7.x) | LTS versions supported until July 2026+; Symfony 8.x requires PHP 8.4+ |
| **Extensions** | `ctype`, `iconv`, `pcre`, `session`, `simplexml`, `tokenizer` | Enabled by default in most PHP 8 installations |
| **Composer** | Any recent version | Mandatory for dependency resolution and package installation |
| **Symfony CLI** | Optional but recommended | Provides the `symfony` binary with dev tools, local web server, deployment helpers |

### Server Configuration

Production requires a full-featured web server:
- **Nginx**: Configure to route all requests through `public/index.php`, deny access to `.env`, `composer.json`, `config/`, `src/`
- **Apache**: Use mod_rewrite or equivalent; set document root to `public/` directory

Local development can use the Symfony Local Web Server (`symfony serve`) — production cannot.

## Deployment Steps

Standard deployment workflow (official checklist):

1. **Check Dependencies** — Verify PHP extensions, Composer packages:
   ```bash
   symfony check-deps
   # or manually verify extensions
   php -m | grep -iE "ctype|iconv|pcre|session|simplexml|tokenizer"
   ```

2. **Configure Environment Variables** — Production secrets and database credentials:
   ```env
   APP_ENV=prod
   APP_DEBUG=false
   APP_SECRET=<generated-secret>
   DATABASE_URL=postgresql://user:pass@db:5432/app
   ```

3. **Install / Update Vendors** (production-only flags):
   ```bash
   composer install --no-dev --optimize-autoloader --prefer-dist
   # or: composer install --no-scripts --no-autoload --no-interaction \
   #      --no-plugins --no-progress --classmap-authoritative
   ```

4. **Warm Up Cache**:
   ```bash
   php bin/console cache:warmup
   ```

5. **Run Migrations** (if Doctrine):
   ```bash
   php bin/console doctrine:migrations:migrate --no-interaction
   ```

6. **Set File Permissions** — `var/`, `logs/`, and cache directories must be writable by web server user (www-data / nginx).

## Performance Tuning for Production

### OPcache Configuration

Critical for Symfony performance:
```ini
opcache.enable=1
opcache.validate_timestamps=0  ; disable timestamp checks in production
opcache.memory_consumption=128
opcache.max_file_size=0
opcache.interned_strings_buffer=16
opcache.max_accelerated_files=100000
```

### Service Container Dump

Generate a single-file container for faster autoloading:
```bash
php bin/console cache:pool clear --all
php bin/console cache:warmup
# or with newer Symfony versions:
php bin/console container:dump-env prod
```

### Composer Autoloader Optimization

```bash
composer install --optimize-autoloader --classmap-authoritative
```

### Full Performance Checklist

| Step | Action | Impact |
|------|--------|--------|
| 1 | Dump service container into single file | Reduces autoloading overhead |
| 2 | Enable OPcache bytecode cache | ~30-50% faster PHP execution |
| 3 | Configure OPcache for maximum performance (above) | Prevents unnecessary recompilation |
| 4 | Don't check PHP files timestamps | `opcache.validate_timestamps=0` |
| 5 | Increase PHP realpath cache size | `realpath_cache_size=64M` |
| 6 | Optimize Composer autoloader | Classmap-authoritative mode |

### Hardware Recommendations

- Minimum: **2 GB RAM**, 2 CPU cores
- Recommended: PHP-FPM with dedicated pool, Redis/Memcached for cache and session storage
- Database: PostgreSQL or MySQL with persistent connections

## Web Server Configuration Examples

### Nginx

```nginx
server {
    listen 80;
    server_name example.com;
    root /var/www/symfony/public;

    location / {
        try_files $uri $uri/ =404;
    }

    # Deny access to sensitive directories
    location ~ ^/(config|src|vendor) {
        deny all;
    }
}
```

### Apache

```apache
DocumentRoot "/var/www/symfony/public"
<Directory "/var/www/symfony/public">
    AllowOverride None
    Require all granted
</Directory>
```

## Related Pages

- [Symfony Entity](entities/symfony.md) — overview of framework and versioning
- [Service Container & DI](concepts/service-container.md) — autoloading and dependency injection in production
- [Doctrine ORM Integration](concepts/doctrine-orm.md) — migrations and database setup
- [Twig Templating](concepts/twig-templating.md) — template caching configuration

## Key Takeaways

1. **PHP 8.4+ is mandatory** for Symfony 8.x; LTS 7.x supports PHP 8.2+ until July 2026+
2. **Composer + core extensions** are the only hard dependencies
3. **Production needs OPcache**, warm cache, and authoritative classmap — skipping these causes significant performance degradation
4. **Symfony Local Web Server is development-only**; production requires Nginx or Apache with proper routing through `public/index.php`
