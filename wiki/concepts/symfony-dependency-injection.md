---
tags: [symfony, dependency-injection, service-container, autowiring, di-pattern]
date: 2026-06-28
sources: [raw/sources/SRC-2026-06-28-SYMFONY-DI-001/symfony-di.md]
related: []
---

# Dependency Injection в Symfony

## Определение:
Dependency Injection (DI) — паттерн проектирования, позволяющий внедрять зависимости объекта извне. В Symfony DI реализуется через контейнер сервисов (Service Container).

## Принципы работы:

### 1. Service Container (ContainerBuilder)
- Основной класс для управления зависимостями в Symfony
- Автоматическое внедрение зависимостей (autowiring)
- Синтаксис: `new ContainerBuilder()->register('service_name', MyClass::class)`

### 2. Autowiring
- Автоматическое определение и внедрение зависимостей на основе типов параметров конструктора
- Работает через reflection API PHP

## Примеры:
* **Базовый DI**: `ContainerBuilder()` + `register()`
* **Autowiring**: автоматическое определение типов из сигнатуры конструктора
* **Symfony Flex**: интеграция с автогенерацией конфигов

## Связи:
* [Service Container](concepts/service-container.md) — основная реализация DI в Symfony
* [Hexagonal Architecture](concepts/hexagonal-architecture.md) — DI позволяет внедрять порты и домены
* [Symfony Flex](concepts/symfony-flex.md) — автоматизация конфигурации сервисов

## Источники:
* `raw/sources/SRC-2026-06-28-SYMFONY-DI-001/symfony-di.md` — Symfony DI documentation

## Создано 2026-06-28 — концепция добавлена в wiki
