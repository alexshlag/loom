---
tags: [entity, researcher, ai-scientist]
date: 2026-06-24
sources: [raw/llm-wiki.md]
related: []
---

# Andrej Karpathy

AI Researcher, автор LLM Wiki pattern (LLM-powered personal knowledge base).

## Ключевые характеристики:
* **Researcher** — работал над computer vision, NLP, autonomous driving
* **Educator** — создал курс CS231n (Stanford), YouTube-контент по ML
* **LLM Wiki Pattern Author** — предложил подход к построению персональных wiki через LLM

## Ключевая идея: LLM Wiki Pattern
Вместо стандартного RAG, где LLM каждый раз заново извлекает фрагменты документов, Karpathy предлагает **incrementally build and maintain a persistent wiki** — структурированную коллекцию markdown-файлов, которую LLM автоматически обновляет при добавлении новых источников. Знания компилируются один раз и поддерживаются актуальными.

## Связи:
* [LLM Wiki Pattern](concepts/llm-wiki-pattern.md) — методика построения wiki через LLM
* [Synthesis: Python NixOS Dev Environments](../syntheses/python-nixos-development-environments.md) — пример синтеза

## Источники:
* `raw/llm-wiki.md` — идея файла для передачи LLM-агенту (оригинал)

