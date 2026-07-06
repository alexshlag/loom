---
tags: [symfony, ux, stimulus, turbo, hotwire, assetmapper, frontend]
date: 2026-07-06
type: documentation
category: comparison
sources: [
  "https://ux.symfony.com/packages",
  "https://ux.symfony.com/stimulus",
  "https://symfony.com/bundles/ux-turbo"
]
aliases: ["Symfony UX Initiative"]
related: [wiki/entities/symfony.md, wiki/concepts/symfony-deployment.md]
---

# Symfony UX — Packages и экосистема


Symfony UX — коллекция PHP и JavaScript пакетов для добавания rich UI в Symfony приложения. Это **не фреймворк**, а набор bundles, которые интегрируются с существующей инфраструктурой (AssetMapper, Twig) и минимизируют необходимость в тяжёлых JS билд-системах.

---

## Основные UX Packages

### Stimulus Bundle — HTML-powered controllers
Stimulus — лёгкий JavaScript framework для augmentation HTML через data attributes:
```html
<div data-controller="symfony-ux-stimulus/autocomplete">
  <input type="text" />
</div>
```
**Ключевая идея:**控制器 (controllers) и targets определяют поведение через декларативные атрибуты, а не императивный JS.

### Turbo — Single-page experience without SPA
Turbo (из Hotwire toolkit) обеспечивает:
- **Page transitions** — мгновенные переходы без full page reloads
- **Fragment replacements** — partial updates вместо AJAX callbacks
- **Form submissions** — seamless form flow без custom handlers

**Result:** SPA-like UX без React/Vue complexity.

### Live Components — Real-time components в Twig
Live Components позволяют создавать интерактивные UI компоненты с automatic reactivity:
```twig
{{ component('UserList', { filters: current_filters }) }}
```
- Automatic diffing и DOM updates
- No custom JS required for basic interactivity
- Integrates with AssetMapper

### Chart.js UX — Charts without build step
Рендеринг chart.js графиков прямо из PHP/Twig через AssetMapper integration.

### React & Vue UX — Embed React/Vue в Twig
```twig
{{ react_component('App', { props: { user: app.user } }) }}
{{ vue_component('MyComponent', { count: 42 }) }}
```
- Props передаются из PHP в JS components
- No Webpack/ESBundler build pipeline required
- AssetMapper handles dependencies

---

## Полный список UX Packages

| Package | Назначение | Status |
|---------|-----------|--------|
| **Stimulus** | HTML-powered JS controllers | Active |
| **Turbo** | Single-page transitions | Active |
| **Live Components** | Real-time Twig components with auto-reactivity | Active |
| **Twig Components** | Reusable PHP-rendered UI components (no JS overhead) | Active |
| **Chart.js UX** | Charts в Twig через AssetMapper | Active |
| **React UX** | Embed React components in Twig | Active |
| **Vue.js UX** | Embed Vue components in Twig | Active |
| **Native** | Build native mobile apps wrapping Symfony web app | Active |
| **Icons** | Render SVG icons from Twig templates | Active |
| **Map** | Interactive maps (Leaflet / Google Maps) via PHP | Active |
| **Notify** | Native browser notifications triggered from PHP | Active |
| **Autocomplete** | Search-as-you-type with async loading | Active |
| **Translator UX** | Use Symfony translations in JavaScript | Active |
| **Toolkit** | Collection of components and templates for pages | Active |
| **CalendarLink** | Add events to user's calendar (Google, Outlook) | Active |
| **Stylized Dropzone** | Styled file uploads with drag-and-drop | Active |
| **Image Cropper** | Image cropping in browser before upload | Active |
| **Toggle Password** | Show/hide password fields UX | Deprecated |
| **Svelte UX** | Embed Svelte components in Twig | Deprecated |
| **Lazy Image** | Lazy loading images with placeholder | Deprecated |
| **Swup Integration** | Page transition library alternative to Turbo | Deprecated |
| **Typed UX** | Animated typing effect from Typed.js | Deprecated |

---

## Symfony UX vs AssetMapper — сравнение подходов

AssetMapper и Symfony UX работают вместе, но решают разные задачи:

| Критерий | AssetMapper | Symfony UX |
|----------|------------|-----------|
| **Назначение** | Zero-build asset management (CSS/JS bundling) | Interactive UI patterns |
| **Механизм** | ES modules + importmaps, auto-resolving | Stimulus controllers + Twig integration |
| **Зависимости** | Автоматическое управление npm-пакетами | Bundles с PHP+JS интеграцией |
| **Build step** | Zero (importmaps) | None — использует AssetMapper для своих JS |

### Workflow: AssetMapper + UX вместе
```bash
# 1. AssetMapper управляет зависимостями через importmap
composer require symfony/asset-mapper

# 2. UX packages автоматически интегрируются
composer require symfony/ux-stimulus symfony/ux-turbo symfony/ux-live-component

# 3. Twig functions генерируют data attributes
stimulus_controller('symfony-ux-stimulus/autocomplete')
```

---

## Symfony UX vs Webpack Encore — сравнение

| Критерий | Webpack Encore | AssetMapper + UX |
|----------|---------------|------------------|
| **Build step** | Обязательный webpack pipeline | Zero-build (importmaps) |
| **JS complexity** | Высокая ( loaders, plugins) | Минимальная (ES modules) |
| **UX integration** | Требует manual setup | Automatic через recipes |
| **Разработка** | Watch mode + HMR | Instant, no compilation |
| **Миграция с Encore** | — | AssetMapper может работать alongside Encore |

---

## Связи

- [Symfony Entity](entities/symfony.md) — UX initiative является частью экосистемы Symfony 7+
- [Deployment & Production Setup](concepts/symfony-deployment.md) — UX packages требуют proper asset handling в production (OPcache + cache warming)
- [Twig Templating](concepts/twig-templating.md) — большинство UX пакетов интегрируются через Twig functions

---

Обновлено 2026-07-06 — полный список всех UX packages, сравнение с Webpack Encore.
