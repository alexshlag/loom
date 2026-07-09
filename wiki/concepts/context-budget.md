---
tags: [context-management, ingest-optimization, agent-behavior, attention-budget]
date: 2026-07-08
type: documentation
category: concept
aliases: [context-engineering, forget-after-extract, tool-result-clearing]
sources: ["web_search", "anthropic-context-engineering", "langchain-context-editing"]
related: ["wiki/concepts/agent-memory-management.md", "rules/context_budget.json"]
---
# Context Budget — Управление контекстным окном LLM при Ingest

# Context Budget — Управление контекстным окном LLM при Ingest

Context budget management governs what stays in the agent's working window during ingest operations. Every token competes for attention — stale content degrades quality even before hitting hard limits.
## Definition
Контекстное окно LLM — конечный бюджет с убывающей отдачей. Каждый токен в окне конкурирует за внимание модели. Удержание устаревшего контента (прочитанных исходников, созданных wiki-страниц после записи) деградирует качество работы на текущем этапе даже до достижения хард-лимита ("context rot").

## Problem Statement

**Проблема:** Во время ingest-agent читает исходные документы, извлекает знания, пишет wiki-страницы — но весь прочитанный контент остаётся в контексте. Это:
1. Тратит контекстный бюджет на данные, которые уже записаны на диск (в wiki)
2. Создаёт "context rot" — модель теряет recall для ранних документов даже когда они "технически присутствуют"
3. При batch ingest (≥3 источника) — экспоненциальный рост: O(N × doc_size) токенов в окне одновременно

**Решение:** Явный forget после extract/write — содержимое источников и созданных страниц выбрасывается из контекста, остаются только метаданные (path, title, category). Wiki — это память на диске; контекст — это рабочая зона.

## Research Backing

### Anthropic Context Engineering [1]
- **Context is a finite resource with diminishing marginal returns**
- **5 turn-level decisions:** Continue → Rewind → Clear → Compact → Delegate to subagent
- **Tool-result clearing** (API primitive): Удаляет старые tool outputs после обработки, оставляет metadata о вызове
- **Sub-agent delegation**: Если промежуточный output disposable — обрабатывай в isolation, возвращай только conclusion

### LangChain Context Editing Middleware [2]
- Хирургическое удаление stale file-reads из conversation history
- Замена содержимого на placeholder (например: `[file /path/to/doc was read at turn 3]`)
- Модель знает что файл был прочитан, но не несёт его полный текст

### Claude Code Best Practices [3]
- **Context rot**: деградация recall *до* хард-лимита, даже когда контент технически в окне
- `/clear` между unrelated tasks — чистить контекст при смене задачи
- `/compact` at task boundaries (не ждать 95% заполнения)

### Key Finding from Anthropic Cookbook [4]
Без context management: agent читает 8 документов (~320K токенов), все в контексте одновременно. Модель "видит" их, но recall из глубины окна деградирует. С tool-result clearing — peak контекста снижается с 335K до ~169K (compaction) или ~5K (clearing).

## Implementation — What We Changed

### Three Forget Triggers in process-ingest.json

#### Trigger 1: After Step 3 (source analysis complete)
```
READ source → EXTRACT entities/facts/concepts → WRITE to wiki page
→ FORGET SOURCE CONTENT from context
→ Keep only: path, title, evidence_grade
```

**Instruction:** "Source document [{TITLE}] processed. Knowledge captured in wiki page [{PATH}]. Discard full source text — it is now re-fetchable from disk via read_file."

#### Trigger 2: Between Sources (batch ingest)
```
Read A → extract → write wiki → FORGET A
Read B → extract → write wiki → FORGET B
...
```

**Prohibited:** Reading all N sources simultaneously — causes O(N×doc_size) bloat.

#### Trigger 3: After Step 9 (post-checks pass)
```
CREATE wiki page → VALIDATE structure + crosslinks → WRITE to disk
→ FORGET PAGE CONTENT from context
→ Keep only: path, title, category
```

**Rationale:** Wiki pages are disk-persisted. Once validated and linked — fully retrievable via grep/read.

### Context Bubble Policy
- Max 3 wiki pages in active context simultaneously
- When opening a new page to read → close (forget) one of the current 3

## Architecture Rules Reference

| Rule | File | Purpose |
|------|------|---------|
| CBUDGET-V2 | `rules/context_budget.json` | Token budget: lazy load, one source at a time, context bubble max 3 |
| SCM-V4 | `rules/session_context_rules.json#operational_rules.context_bubble_max_pages` | Max open pages config |

## Session Bootstrap Integration

Bootstrap does NOT pre-load context budget rules. Agent reads `rules/context_budget.json` on demand via schema_ref when processing any source.

## Why This Matters for Loomana Specifically

1. **Ingest process читает большие исходники** (PDF, long documents) — каждый токен сырого текста конкурирует с записью wiki-страницы
2. **Batch ingest clusters ≥3 related sources** — без forget: O(N×doc_size) токенов одновременно → overflow или severe context rot
3. **Wiki pages disk-persisted** — после создания + валидации, страница полностью доступна по пути; нет смысла держать её текст в контексте для шагов 10-12 (registration/logging)

## Comparison: Before vs After

| Metric | Before Forget | After Forget |
|--------|--------------|--------------|
| Source docs in context after extract | Full text of all read sources | Only path + title + grade |
| Generated wiki pages in context post-validation | Full page content for registration steps | Only metadata (path, category) |
| Batch ingest memory usage | O(N × doc_size) simultaneous | O(doc_size) sequential |
| Context available for actual work | Reduced by stale content | Maximised — budget allocated to current task |

## Related Pages
- [[wiki/concepts/agent-memory-management.md]] — общая архитектура памяти агента
- [[wiki/concepts/natural-memory.md]] — естественный перевод фактов
- [[rules/context_budget.json]] — детальные принципы context management

---

## References

[1] [Effective Context Engineering for AI Agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) (Anthropic, 2025)
[2] [Context Editing Middleware](https://github.com/langchain-ai/langchain/blob/main/libs/langchain_v1/langchain/agents/middleware/context_editing.py) (LangChain)
[3] [Turn-Level Context Decisions for AI Coding Sessions](https://agentpatterns.ai/context-engineering/turn-level-context-decisions/) (AgentPatterns, 2025)
[4] [Context engineering: memory, compaction, and tool clearing](https://platform.claude.com/cookbook/tool-use-context-engineering-context-engineering-tools) (Claude Cookbook, Anthropic API docs)
