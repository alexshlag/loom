---
tags: [ rag, knowledge-base, llm, compounding-knowledge]
date: 2026-06-25
sources: [raw/llm-wiki.md]
related: []
aliases: ["LLM Wiki Pattern", "Karpathy wiki", "compounding knowledge base"]
---
- [[wiki/concepts/symfony-ai.md]] (score: 5)
- [[wiki/entities/loomana.md]] (score: 5)
- [[wiki/syntheses/rag-vs-llm-wiki-pattern.md]] (score: 5)
- [[wiki/concepts/symfony-ai.md]] (score: 5)
- [[wiki/entities/loomana.md]] (score: 5)
- [[wiki/syntheses/rag-vs-llm-wiki-pattern.md]] (score: 5)
- [[wiki/concepts/symfony-ai.md]] (score: 5)
- [[wiki/entities/loomana.md]] (score: 5)
- [[wiki/syntheses/rag-vs-llm-wiki-pattern.md]] (score: 5)
- [[wiki/concepts/symfony-ai.md]] (score: 5)
- [[wiki/entities/loomana.md]] (score: 5)
- [[wiki/syntheses/rag-vs-llm-wiki-pattern.md]] (score: 5)
- [[wiki/concepts/symfony-ai.md]] (score: 5)
- [[wiki/entities/loomana.md]] (score: 5)
- [[wiki/syntheses/rag-vs-llm-wiki-pattern.md]] (score: 5)



# LLM Wiki Pattern — Incremental Knowledge Base Building

> **Origin:** Andrej Karpathy. [Reference gist](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f).
> **Related concept:** Vannevar Bush's Memex (1945) — personal curated knowledge store with associative trails.

## Определение
[[LLM Wiki Pattern]] — архитектурный паттерн для построения **персональной wiki через LLM**, которая инкрементально накапливает и поддерживает актуальность знаний, вместо стандартного [[RAG]], где LLM rediscovering knowledge from scratch на каждый запрос. Использует принципы [[hexagonal architecture]] и [[DDD patterns]] для организации структуры wiki.

Ключевая метафора Karpathy: *«Obsidian — это IDE; LLM — programmer; wiki — codebase.»*

## Принципы работы

### 1. Три слоя архитектуры

| Layer | Description |
|-------|-------------|
| **Raw sources** | Immutable коллекция оригинальных документов (статьи, papers, изображения, data files). Source of truth. LLM читает, но не модифицирует. |
| **The wiki** | Directory LLM-generated markdown-файлов: entity pages, concept pages, comparisons, synthesis, overview. LLM владеет этим слоем полностью — создаёт, обновляет, поддерживает cross-references. |
| **The schema** | Configuration document (CLAUDE.md / AGENTS.md), определяющий структуру wiki, конвенции и workflows для ingest/query/lint. Co-evolves между человеком и LLM. |

### 2. Операции (Workflow)

* **Ingest.** Пользователь добавляет источник → LLM читает его, обсуждает key takeaways с пользователем, пишет summary в wiki, обновает index, обновляет relevant entity/concept pages, записывает entry в log. Один источник может затронуть 10-15 wiki-страниц.
* **Query.** Пользователь задаёт вопрос → LLM ищет релевантные страницы, читает их, синтезирует ответ с citations. Good answers могут быть **filed back into the wiki** как новые страницы (comparison table, analysis, synthesis).
* **Lint.** Periodic health-check: contradictions, stale claims, orphan pages, missing cross-references, data gaps. LLM предлагает новые вопросы и источники для исследования.

### 3. Индексирование и логирование

* **index.md** — content-oriented catalog всех страниц wiki с one-line summary по категориям. Работает при ~100 источниках / hundreds pages без embedding-based RAG.
* **log.md** — chronological append-only record с prefix-форматом `## [YYYY-MM-DD] action | description`. Parseable через unix tools (`grep "^## \["`).

### 4. Компандирование (Compounding)

Wiki — это **persistent, compounding artifact**:
* Cross-references уже есть при каждом query
* Contradictions already flagged
* Synthesis reflects everything read
* Wiki **compounds** с каждым новым источником и каждым question-answer pair

## Контекст и применения

### Персональное (Personal)
Цели, здоровье, психология, self-improvement — filing journal entries, articles, podcast notes. Building a structured picture over time.

### Исследование (Research)
Deep-dive на тему за недели/месяцы: papers, articles, reports → incremental comprehensive wiki с evolving thesis.

### Чтение книги
Filing каждого chapter → character pages, theme pages, plot threads → rich companion wiki по аналогии с [Tolkien Gateway](https://tolkiengateway.net/wiki/Main_Page). thousands of interlinked pages built over years (но в одиночку через LLM).

### Бизнес / Команда
Internal wiki maintained by LLMs, fed by Slack threads, meeting transcripts, project docs, customer calls. Humans-in-the-loop для review updates. Wiki stays current because LLM does the maintenance nobody wants to do.

### Другие применения
Competitive analysis, due diligence, trip planning, course notes, hobby deep-dives — anything where you're accumulating knowledge over time and want it organized rather than scattered.

## Примеры инструментов (Optional)

| Инструмент | Purpose |
|------------|---------|
| **Obsidian Web Clipper** | Конвертация web-статей в markdown для ingestion в raw/ |
| **qmd** | Local search engine: hybrid BM25/vector + LLM re-ranking. CLI + MCP server. |
| **Marp** | Markdown-based slide decks из wiki content (Obsidian plugin). |
| **Dataview** | Obsidian plugin для queries по page frontmatter (tags, dates, source counts). |
| **Graph view** | Визуализация связей: hubs, orphans, connected components. |

## Почему это работает

The tedious part of maintaining a knowledge base is not the reading or the thinking — it's the bookkeeping. Updating cross-references, keeping summaries current, noting when new data contradicts old claims, maintaining consistency across dozens of pages. Humans abandon wikis because maintenance burden grows faster than value. LLMs don't get bored and can touch 15 files in one pass.

**Division of labor:**
* **Human**: curate sources, direct analysis, ask good questions, think about implications.
* **LLM**: summarizing, cross-referencing, filing, bookkeeping, maintenance.

## Связи с нашим проектом

### Прямые связи
* [Entity: Andrej Karpathy](entities/andrej-karpathy.md) — автор паттерна
* [Synthesis: RAG vs LLM Wiki Pattern](syntheses/rag-vs-llm-wiki-pattern.md) — сравнение подхода
* [Concept: Temporal Decay](concepts/temporal-decay-in-wiki.md) — проблема устаревания, требует maintenance

### Реализация: Loomana
| Элемент проекта | Соответствие паттерну |
|-----------------|----------------------|
| `raw/**` (immutable sources) | Raw sources layer — immutable collection, read-only via guardrails |
| `wiki/**` (entity/concept/synthesis) | The wiki layer — LLM-owned directory of markdown files organized by type |
| `AGENTS.md` (schema) | The schema document — defines structure, conventions, workflows. Co-evolves with user |
| `process-ingest.json` / `process-query.json` / `process-lint.json` | Three operations: Ingest → Query → Lint as separate process roles |
| `index.md` + `log.md` | Indexing and logging per Karpathy spec |
| `working_memory.json` | Context bridge between sessions (extends Karpathy's idea) |

## Источники
* `raw/llm-wiki.md` — оригинальный gist Karpathy на GitHub Gist


## Примеры
* **LLM Wiki Pattern** — incremental knowledge base через LLM вместо RAG: каждый ответ агрегируется в wiki, страницы обновляются по мере роста базы.
* **Compounding Knowledge Base** — система становится сильнее с каждым источником/вопросом (в отличие от стандартного RAG, который «перевычисляет» знания на каждом запросе).
