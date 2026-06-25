---
tags: [concept, rag, knowledge-base, llm, compounding-knowledge]
date: 2026-06-24
sources: [raw/llm-wiki.md]
related: []
---

# LLM Wiki Pattern — Incremental Knowledge Base Building

## Определение:
Архитектурный паттерн для построения персональных wiki через LLM, который **компилит знания один раз и поддерживает их актуальными** вместо стандартного RAG с извлечением фрагментов на каждый запрос.

## Принципы работы:

### 1. Три слоя архитектуры
* **Raw sources** — immutable коллекция оригинальных документов (статьи, документы, изображения)
* **The wiki** — LLM-generated markdown-файлы (entity pages, concept pages, comparisons, synthesis). LLM владеет этим слоем полностью.
* **The schema** — документ конфигурации (CLAUDE.md/AGENTS.md), который определяет структуру wiki, конвенции и workflows

### 2. Операции
* **Ingest** — пользователь добавляет источник → LLM читает, обсуждает ключевые тезисы с пользователем, пишет summary в wiki, обновает index, обновает entity/concept pages, записывает entry в log
* **Query** — пользователь задаёт вопрос → LLM ищет релевантные страницы, читает их, синтезирует ответ. Ответ может быть записан обратно в wiki как новая страница (сравнение, анализ)
* **Lint** — периодическая health-check wiki: противоречия, устаревшие утверждения, orphan-страницы, недостающие cross-references

### 3. Индексирование и логирование
* **index.md** — content-oriented catalog всех страниц wiki с one-line summary, по категориям
* **log.md** — chronological append-only record ingests, queries, lint passes

## Контекст и применение:

### Персональное использование:
* Цели, здоровье, психология, self-improvement — ведение journal entries, статей, подкастов
* Deep-dive research на темы за недели/месяцы — papers, articles, reports с evolving thesis

### Академическое:
* Чтение книги с filing каждого chapter → character pages, theme pages, plot threads → rich companion wiki (аналог [Tolkien Gateway](https://tolkiengateway.net/wiki/Main_Page))

### Бизнес/Команда:
* Internal wiki maintained by LLMs, fed by Slack, meeting transcripts, project docs, customer calls
* Humans in the loop для review updates

### Другие применения:
* Competitive analysis, due diligence, trip planning, course notes, hobby deep-dives

## Примеры инструментов (опционально):
* **Obsidian Web Clipper** — конвертация web-статей в markdown
* **qmd** — local search engine для markdown с hybrid BM25/vector search и LLM re-ranking
* **Marp** — markdown-based slide decks из wiki content
* **Dataview** — Obsidian plugin для queries по page frontmatter
* **Graph view** — визуализация связей в Obsidian

## Связи:
* [Entity: Andrej Karpathy](entities/andrej-karpathy.md) — автор паттерна
* [Pi Coding Agent](entities/pi-coding-agent.md) — harness для работы с wiki
* [Synthesis: RAG vs LLM Wiki Pattern](syntheses/rag-vs-llm-wiki-pattern.md)
* [Concept: Temporal Decay](concepts/temporal-decay-in-wiki.md) — проблема устаревания знаний в compounding KB

## Источники:
* `raw/llm-wiki.md` — оригинальная идея файла (оригинал)


## Примеры
* **LLM Wiki Pattern** — incremental knowledge base через LLM вместо RAG: каждый ответ агрегируется в wiki, страницы обновляются по мере роста базы.
* **Compounding Knowledge Base** — система становится сильнее с каждым источником/вопросом (в отличие от стандартного RAG, который «перевычисляет» знания на каждом запросе).

