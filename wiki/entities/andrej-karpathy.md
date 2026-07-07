---
tags: [machine-learning, deep-learning, computer-vision, nlp, llm-wiki-pattern]
date: 2026-06-24
sources: [raw/llm-wiki.md]
related: []
---
- [[wiki/comparisons/llm-wiki-implementations.md]] (score: 6)

# Andrej Karpathy

AI Researcher, автор LLM Wiki pattern (LLM-powered personal knowledge base).

## Ключевые характеристики:
* **Researcher** — работал над computer vision, NLP, autonomous driving
* **Educator** — создал курс CS231n (Stanford), YouTube-контент по ML
* **LLM Wiki Pattern Author** — предложил подход к построению персональных wiki через LLM

## Карьера:
* **Anthropic (2026)** — присоединился к команде pretraining
* **Eureka Labs (2024)** — основал платформу AI-образования
* **Tesla (2017–2022)** — Senior Director of AI, возглавлял компьютерное зрение для Autopilot и Tesla Optimus
* **OpenAI** — Research Scientist, работал над глубоким обучением, компьютерным зрением, генеративными моделями и reinforcement learning
* **Stanford** — PhD в Computer Science (работал с Fei-Fei Li)

## Kлючевая идея: LLM Wiki Pattern
Вместо стандартного RAG, где LLM каждый раз заново извлекает фрагменты документов, Karpathy предлагает **incrementally build and maintain a persistent wiki** — структурированную коллекцию markdown-файлов, которую LLM автоматически обновляет при добавлении новых источников. Знания компилируются один раз и поддерживаются актуальными.

> Источник: [karpathy.ai](https://karpathy.ai/), Wikipedia, LinkedIn

## Связи:
* [Concept: LLM Wiki Pattern](concepts/llm-wiki.md) — методика построения wiki через LLM (компounding knowledge base)
* [Synthesis: RAG vs LLM Wiki Pattern](syntheses/rag-vs-llm-wiki-pattern.md) — сравнение подхода
* [Synthesis: Python NixOS Dev Environments](syntheses/python-nixos-development-environments.md) — пример синтеза через wiki

## Источники:
* `raw/llm-wiki.md` — оригинальный gist Karpathy с описанием паттерна (оригинал)

