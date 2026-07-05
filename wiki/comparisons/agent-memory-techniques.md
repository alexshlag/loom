---
tags: [memory, agent-architecture, comparison, zero-dependency]
date: 2026-07-06
type: documentation
category: comparison
aliases: [agent memory patterns, context management comparison]
sources: ["web_search"]
related: ["wiki/concepts/agent-memory-management.md"]
---

# Сравнение техник управления памятью агента

## Definition
Сравнительный анализ основных архитектурных подходов к управлению памятью LLM-агентов с точки зрения применимости в нашем проекте (loomana) — нулевая зависимость от внешних библиотек, file-based хранение.

## Comparison Matrix

| Техника | External DB | Embedding Service | Custom Dependencies | Подходит для loomana | Примечание |
|---------|-------------|-------------------|---------------------|----------------------|------------|
| **Compaction (summarization)** | ❌ | ❌ | ❌ | ✅ Да | Встроено в pi; LLM-генерируемое резюме |
| **Tool-result clearing** | ❌ | ❌ | ❌ | ✅ Да | Server-side API, zero deps |
| **Structured note-taking** (WM + hot.md) | ❌ | ❌ | ❌ | ✅ Да | Уже реализовано |
| **Hybrid lexical+semantic search** | ❌* | ⚠️ Optional | ❌ | ✅ Да | Lexical без эмбеддингов; semantic с ними |
| **Vector store memory** (Pinecone, Weaviate) | ✅ | ✅ | ✅ | ❌ Нет | Внешняя БД + сервис — не подходит |
| **Knowledge graph** (Neo4j, Graphiti) | ✅ | ⚠️ Optional | ✅ | ❌ Нет | Требует графовую БД и/или embedding service |
| **MemGPT / Letta** (inner monologue) | ❌* | ❌ | ❌ | 🟡 Частично | Архитектурно интересно, но требует перестройки agent loop |
| **Mem0 / Zep** (managed services) | ✅ | ✅ | ✅ | ❌ Нет | Cloud-dependant, heavy infra |
| **Ebbinghaus forgetting curve** | ❌ | ❌ | ❌ | ✅ Да | Один Python-файл — легко интегрировать |

## Deep Dive: Top 3 Recommended for Loomana

### 1. Compaction (приоритет: высокий)

**Почему**: Уже встроено в pi-agent-core через `compaction.ts`. Автоматический trigger при достижении token threshold, structured summary generation.

**Что добавить**:
- Периодическая запись `session_summary` в working_memory.json → улучшает continuity между compactions
- Custom instructions для summary prompt: сохранять key decisions и file paths

### 2. Hybrid Recall (приоритет: высокий)

**Почему**: Реализовано в pi-llm-wiki (`recall.ts`). Lexical search по registry.json работает без каких-либо внешних зависимостей; semantic boost опционален.

**Что добавить**:
- `recall_triggers` field в frontmatter wiki pages → auto-trigger recall при релевантных запросах
- Links-first rendering для больших виток (>50 страниц)

### 3. Trajectory Capture + Skill Distillation (приоритет: средний)

**Почему**: [pi-llm-wiki trajectories](https://github.com/zosmaai/pi-llm-wiki/tree/main/extensions/llm-wiki/lib) — opt-in feature, off by default. Запись как агент решил задачу → дистилляция в reusable skills.

**Что добавить**:
- `wiki_capture_trajectory` после завершения сложных задач
- Периодический `wiki_distill_skills` → превращение trajectory в skill/case pages
- `wiki_recall_skill` → поиск по навыкам при новых похожих задачах

## Related Pages
* [agent-memory-management.md](../concepts/agent-memory-management.md) — полное описание всех техник
* [process-query.json](../../process-query.json) — search priority + recall integration
* [AGENTS.md#Memory Architecture Contract]('../../AGENTS.md') — WM/hot.md/log.md specification

## Sources
* **Anthropic**: [Context Engineering Cookbook](https://platform.claude.com/cookbook/tool-use-context-engineering-context-engineering-tools) — compaction, tool-clearing, memory
* **Agent Memory Techniques**: [30 techniques repo](https://github.com/NirDiamant/Agent_Memory_Techniques) — comprehensive taxonomy
* **Pi-llm-wiki**: [hybrid recall implementation](https://github.com/zosmaai/pi-llm-wiki/blob/main/extensions/llm-wiki/lib/recall.ts) — lexical+semantic fusion
