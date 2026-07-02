---
tags: [entity, runtime, javascript, server-side, npm]
date: 2026-07-02
type: documentation
category: entity
sources: ["https://nodejs.org/en/about", "https://github.com/nodejs/release"]
related: []
---

# Node.js

Node.js — это runtime для выполнения JavaScript-кода вне браузера. Создан Райном Дэйли (Ryan Dahl) в 2009 году, позволяет строить масштабируемые сетевые приложения с использованием асинхронной event-driven модели.

## Определение

Node.js — runtime на движке V8 от Google, предназначенный для написания серверного JavaScript. В отличие от классических thread-based моделей, Node.js использует event loop как конструкцию времени выполнения, а не библиотеку.

## Ключевые характеристики

### Event Loop и Non-Blocking I/O

- Node.js обрабатывает множество соединений одновременно через callback-функции
- Если нет работы — процесс просто «спит», без блокировок
- Практически все функции в Node.js не выполняют прямых I/O, поэтому процесс никогда не блокируется (кроме синхронных методов стандартной библиотеки)

### Модель конкурентности

```javascript
// Пример: обработка множества соединений одновременно
const http = require('node:http');

const host = '127.0.0.1';
const port = 3000;

const server = ((req, res) => {
  . = 200;
  res.setHeader('Content-Type', 'text/plain');
  res.end('Hello World\n');
});

server.listen(port, host, () => {
  console.log(`Server running at http://${host}:${port}/`);
});
```

### Многопоточность через child_process

- `child_process.fork()` — создание процессов для параллельного выполнения
- Модуль `cluster` — шаринг сокетов между процессами для load balancing по core'ам

## Release Schedule

| Версия | Статус | Codename   | Initial Release | Active LTS Start | Maintenance Start | End-of-Life |
|--------|--------|------------|-----------------|------------------|-------------------|-------------|
| v22.x  | Maintenance LTS | Jod    | 2024-04-24      | 2024-10-29       | 2025-10-21        | 2027-04-30  |
| v24.x  | Active LTS     | Krypton  | 2025-05-06      | 2025-10-28       | 2026-10-20        | 2028-04-30  |
| v26.x  | Current        | —        | 2026-05-05      | 2026-10-28       | 2027-10-20        | 2029-04-30  |

### Фазы жизни релиза

| Фаза | Описание |
|------|----------|
| **Current** | Новый релиз, активная разработка, API может меняться |
| **Active LTS** | Стабильная версия для production — 6 месяцев после Current |
| **Maintenance LTS** | Только критические исправления безопасности и багов |

## Архитектурное влияние

Node.js похож на Ruby's [Event Machine](https://github.com/eventmachine/eventmachine) и Python's [Twisted](https://twisted.org/), но выходит дальше — event loop как конструкция runtime, а не библиотека. Нет `blocking call` для старта event-loop: Node.js просто входит в цикл после выполнения входного скрипта и выходит когда нет больше callbacks.

## HTTP как first-class citizen

HTTP-стек спроектирован с streaming и low latency в mind, что делает Node.js подходящим фундаментом для веб-библиотек и фреймворков (Express, Fastify, Hapi).

## Официальные ресурсы

### Домены
| Домен | Назначение |
|-------|------------|
| [nodejs.org](https://nodejs.org) | Основной сайт, загрузки, docs |
| [nodejs.dev](https://nodejs.dev) | Редирект на nodejs.org |
| [iojs.org](https://iojs.org) | Редирект на nodejs.org (исторический) |

### npm Scopes
| Scope | Назначение |
|-------|------------|
| [@node-core](https://npmjs.com/~node-core) | Ядро Node.js |
| [@pkgjs](https://npmjs.com/~pkgjs) | Инструменты pkg |

### GitHub Organizations
| Organization | Направление |
|--------------|-------------|
| [nodejs](https://github.com/nodejs) | Основные проекты (core, docs, modules) |
| [pkgjs](https://github.com/pkgjs) | Пакетные инструменты |

Связанные страницы (pending):
- npm — пакетный менеджер для Node.js
- Express — веб-фреймворк на основе Node.js
- V8 Engine — JavaScript engine, лежащий в основе
