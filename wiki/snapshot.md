---
tags: [snapshot, active-projects]
date: 2026-06-28
sources: []
related: [wiki/comparisons/llm-wiki-implementations.md, wiki/concepts/llm-wiki.md, wiki/entities/loomana.md]
---
# Wiki Snapshot — Активные проекты

## Active Projects

### Управление памятью и контекстом ИИ-агента (Memory Architecture)
- **Статус**: active
- **Контекст**: Интегрируем working_memory.json, CONTEXT_BUBBLE, Grep Contract. Цель: оптимизация памяти без потери важного контекста.
- **Связанные wiki-страницы**:
  - `[Concept: LLM Wiki Pattern](concepts/llm-wiki.md)` — incremental knowledge base building через LLM.
  - `[Synthesis: RAG vs LLM Wiki Pattern](syntheses/rag-vs-llm-wiki-pattern.md)` — сравнение стандартного RAG с compounding knowledge base.

### Сравнение реализаций: Loomana vs pi-llm-wiki
- **Статус**: active (research phase)
- **Контекст**: Анализ двух подходов к реализации LLM Wiki Pattern: Loomana (Markdown-driven wiki) vs TypeScript platform (pi-llm-wiki). Ищем best practices для масштабирования.
- **Связанные wiki-страницы**:
  - `[Comparison: LLm Wiki Implementations](comparisons/llm-wiki-implementations.md)` — детальное сравнение workflow, инструментов, trade-offs

### Loomana — Phase 5: Dynamic Priority + Relevance Scoring
- **Статус**: active (in progress)
- **Контекст**: Внедрение динамического порядка категорий wiki по query intent. Референс: PLAN.md Phases 4-6, pi-llm-wiki layered recall.
- **Связанные wiki-страницы**:
  - `[Comparison: LLm Wiki Implementations](comparisons/llm-wiki-implementations.md)`

### Loomana — Wiki System Documentation
- **Статус**: completed (2026-06-28)
- **Контекст**: Создана полная документация системы Loomana в `wiki/entities/loomana.md`
  - Архитектура трёх слоёв: raw, wiki, schema
  - Три рабочих процесса: ingest, query, lint
  - Guardrails и Error Handling Protocol
  - Memory Architecture (Context Bridge, Context Bubble)
- **Связанные wiki-страницы**:
  - `[Entity: Loomana](entities/loomana.md)` — основная документация системы

---

*Last updated: 2026-06-28*