---
tags: [comparison, symfony]
date: 2026-06-25
type: documentation
sources: []
related: [wiki/entities/symfony.md, wiki/comparisons/loom-vs-claude-obsidian.md]
---

# Symfony UX Initiative — Comparison with AssetMapper

## Overview
Symfony UX packages (Hotwire, Stimulus, Chart.js integrations) leverage AssetMapper for zero-build frontend asset management.

## Key UX Packages
* **Stimulus** — lightweight JavaScript framework for augmenting HTML
* **Hotwire** — approach for building web apps without full SPA frameworks  
* **Turbo** — fast page transitions without full reloads

## Comparison with AssetMapper
| Feature | Symfony UX | Standalone |
|---------|-----------|------------|
| Build step | None (AssetMapper) | Requires bundler |
| JS framework | Stimulus/Hooks | Any framework |
| Integration | Native in Symfony | Manual setup |

