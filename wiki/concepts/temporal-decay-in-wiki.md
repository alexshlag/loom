---
tags: [ temporal-decay, maintenance, wiki-growth]
date: 2026-06-25
sources: [raw/llm-wiki.md, issues.md]
related: [wiki/syntheses/rag-vs-llm-wiki-pattern.md, wiki/concepts/llm-wiki.md]
---
- [[wiki/concepts/agent-memory-management.md]] (score: 4)
- [[wiki/concepts/natural-memory.md]] (score: 5)

# Temporal Decay in Compounding Knowledge Base

This page explores Temporal Decay in Compounding Knowledge Base as a key concept in our knowledge base.

## Определение
**Temporal decay (времянное устаревание)** — проблема в compounding knowledge base, когда страницы wiki содержат устаревшие факты или противоречия с более новыми источниками. В отличие от RAG (stateless, каждый ответ = fresh from documents), wiki эволюционирует со временем и требует maintenance.

## Принципы работы

### 1. Compounding vs Statelessness
* **RAG**: stateless — каждый запрос независимый, ответы всегда из актуальных документов
* **Wiki Pattern**: compounding — знания накапливаются, страницы обновляются, но старые факты могут сохраняться если не обновлены

### 2. Maintenance burden
* Wiki требует periodic lint-аудита для обнаружения устаревших страниц (issues.md → Issue #1)
* Agent должен самостоятельно инициировать updates когда появляются новые источники с противоречащими данными
* Без automated freshness checks wiki может содержать outdated information

### 3. Resolution strategies
* **Authoritative source** — приоритет official docs > community wiki > personal notes
* **Temporal conflict** — если нет authoritative source → новее лучше
* **User review** — ambiguous cases → ask user

## Контекст и применение

### Когда temporal decay критичен:
- Быстроизменяющиеся области (AI/ML, software versions)
- Long-running projects с новыми источниками каждые недели/месяцы
- Teams requiring up-to-date information for decisions

### Когда less critical:
- Historical/theoretical topics (Karpathy's career, philosophical concepts)
- Topics where consensus doesn't change frequently

## Связи:
* [LLM Wiki Pattern Concept](concepts/llm-wiki.md) — compounding knowledge base approach
* [Synthesis: RAG vs LLM Wiki Pattern](syntheses/rag-vs-llm-wiki-pattern.md) — comparison table shows wiki compounds over time
* [Issues #1](../../issues.md#issue-1-актуальность-информации) — актуальность информации требует решения

---
*Создано: 2026-06-25 | Query synthesis on temporal decay problem*
