---
tags: [php, programming-language, web-development, server-side, rasmus-lerdorf]
date: 2026-07-06
type: documentation
category: entity
aliases: ["PHP", "PHP language"]
sources: [web_search]
related: [wiki/entities/symfony.md, wiki/concepts/symfony-dependency-injection.md, wiki/concepts/hexagonal-architecture.md]
---
- [[wiki/entities/rust-clippy.md]] (incoming, score: 3)
- [[wiki/entities/nvidia.md]] (incoming, score: 2)
- [[wiki/entities/nodejs.md]] (incoming, score: 3)
- [[wiki/concepts/testing-strategy.md]] (score: 6)
- [[wiki/concepts/twig-templating.md]] (score: 6)
- [[wiki/entities/symfony.md]] (score: 6)

# PHP

This page explores PHP — programming language created for web development.

## Определение

**PHP** (Hypertext Preprocessor) — мультипарадигменный серверный язык программирования, созданный специально для веб-разработки. Создан в 1994 году **Рамнусом Лердорфом (Rasmus Lerdorf)** как набор CGI-программ на C для поддержки личной веб-страницы. С тех пор эволюционировал до одного из самых популярных языков для backend: по данным W3Techs, PHP используется в ~75% всех веб-сайтов с известным серверным стеком.

## История создания

### Зарождение (1993–1994)
Рамнус Лердорф, датский программист, написал несколько CGI-программ на C для поддержания своей персональной страницы. Он расширил их для работы с HTML-формами и базами данных, назвав это **"Personal Home Page/Forms Interpreter" (PHP/FI)**.

### Первый релиз (1995)
8 июня 1995 года Рамнус опубликовал **PHP Tools v1.0** в comp.infosystems — официальный первый release. Изначально это был простой набор CGI-бинарников для отслеживания посетителей страницы.

### PHP 3 (1997) — Первый серьёзный релиз
Полностью переписанный парсер с поддержкой множества фреймворков, баз данных и более чистым API. Именно PHP 3 заложил основы современного синтаксиса и объектной модели.

### PHP 4 (2000–2001)
Новый Zend Engine, значительный рост производительности, встроенная поддержка HTTP-клиента и FTP. Зародился Zend Framework (позже — основа Symfony).

### PHP 5 (2004) — Революция ООП
- Полноценные классы, интерфейсы, исключения
- **PDO** (PHP Data Objects) для универсальной работы с БД
- **SimpleXML**, Soap extensions
- Значительный рост производительности благодаря Zend Engine II

### PHP 7 (2015) — Возвращение производительности
- Новый **Zend Engine III** (~3x faster than PHP 5)
- Return type declarations, nullable types
- Spaceship operator (`<=>`)
- JIT-компиляция (experimental)

## Текущие версии (июль 2026)

| Версия | Статус | Поддержка до | Примечание |
|--------|--------|-------------|------------|
| **8.5** | Latest stable | Dec 31, 2027 (~1.5 года) | Стабильная ветка, последняя версия 8.5.8 |
| **8.4** | LTS | Dec 31, 2026 (~5 месяцев) | Long-term support, последняя версия 8.4.23 |

### Цикл поддержки
С марта 2024 года цикл продлён до **4 лет**:
- **2 года** — bug fixes и security patches
- **2 года** — только security fixes
- Для новых minor-версий: alpha → RC → stable release cycle ~1 год

## Ключевые особенности

### Мультипарадигменность
PHP поддерживает: procedural, OOP (classes, interfaces, traits), functional programming (closures, higher-order functions).

### Типизация
PHP 8.x: strong typing в userland, union types, match expression, named arguments. JIT-оптимизация для CPU-bound операций.

### Экосистема
- **Composer** — пакетный менеджер с автолоадом (PSR-4) и ~100k+ пакетов на packagist.org
- **Symfony** — enterprise framework (DI, hexagonal architecture, bundles)
- **Laravel** — elegant syntax framework для rapid development
- CMS: WordPress (~75%), Drupal, Joomla

### Инструменты разработки
| Инструмент | Назначение |
|-----------|-----------|
| **PHPStan/Psalm** | Static analysis (type checking без runtime) |
| **PHPUnit** | Unit/Integration testing |
| **Composer** | Dependency management & autoloading |
| **Symfony CLI / Herd** | Local development environments |

## Эволюция синтаксиса (major versions)

### PHP 5 → 7 — Символьные нововведения
- Namespaces, use statements (`use App\Service\MyService;`)
- Type-hints для параметров и return types
- Closure/Callable с типизацией
- Array dereferencing: `$arr = foo()[0];`

### PHP 8+ — Современная эра
| Feature | Version | Пример |
|---------|---------|--------|
| Union Types | 8.0 | `function test(string|int $value)` |
| Named Arguments | 8.0 | `foo(name: 'John', age: 25)` |
| Constructor Property Promotion | 8.0 | `public function __construct(public string $name)` |
| Match Expression | 8.0 | `match($x) { 1 => 'one', default => 'other' }` |
| Enums | 8.1 | `enum Status: string { case Active = 'active'; }` |
| Readonly Properties | 8.1 | `public readonly int $id;` |
| Fibers | 8.1 | `fiber = new Fiber($callback)` для асинхронности |

## PHP в экосистеме веба (2026)

PHP остаётся доминирующим языком для backend-разработки:
- ~75% всех веб-сайтов используют PHP (W3Techs, 2024 data)
- Symfony, Laravel, WordPress — экосистемы с миллионными install base
- В 2026: активное развитие JIT, улучшения type system, async/await-like features через Fibers

## Связи
- [Symfony](entities/symfony.md) — PHP framework, написан на PHP
- [Dependency Injection в Symfony](concepts/symfony-dependency-injection.md) — DI container как ядро Symfony
- [Hexagonal Architecture](concepts/hexagonal-architecture.md) — паттерн архитектуры для Symfony 7+

## Источники
- `https://www.php.net/manual/en/history.php.php` — History of PHP (official manual)
- `https://talks.php.net/hhs` — "25 Years of PHP" presentation by Rasmus Lerdorf
- `https://en.wikipedia.org/wiki/PHP` — Wikipedia overview
- `https://www.php.net/supported-versions.php` — Supported versions status
- `https://php.watch/versions` — PHP version tracking and release calendar
