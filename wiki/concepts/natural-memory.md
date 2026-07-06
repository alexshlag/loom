---
tags: [memory, agent-behavior, wiki-pattern]
date: 2026-06-30
type: documentation
category: concept
sources: []
related: ["wiki/concepts/memory-architecture.md", "wiki/overview.md", "wiki/snapshot.md"]
---
- [[wiki/concepts/agent-memory-management.md]] (score: 5)
- [[wiki/concepts/agent-memory-management.md]] (score: 5)
- [[wiki/concepts/agent-memory-management.md]] (score: 5)
- [[wiki/concepts/agent-memory-management.md]] (score: 5)
- [[wiki/concepts/agent-memory-management.md]] (score: 5)
- [[wiki/concepts/agent-memory-management.md]] (score: 5, incoming)

# Natural Memory Translation — Перевод машинных фактов в живую память


This page explores Natural Memory Translation — Перевод машинных фактов в живую память as a key concept in our knowledge base.


## Definition
Перевод машино-читаемых данных (даты, комиты, timestamps) в естественную форму, которую человек воспринимает как «мы помним» вместо «система записала». Факты остаются точными, но формулировка становится человеческой.

## Principles
1. **Факты из источника** — никогда не выдумывать. Даты из frontmatter, комиты из git diff.
2. **Относительное время** — всегда вычислять разницу между `system_date` и source date → использовать «вчера/позавчера/неделю назад». Никогда не хардкодить конкретные даты в примерах.
3. **Общий опыт** — «мы правили это», а не «агент обновил этот файл». Когда речь об общем опыте проекта.
4. **Точность без потери естественности** — дата остаётся верной, просто формулировка живая.

## Examples

### ✅ Живой стиль (естественно, точно)
> «Позавчера мы правили этот файл» → agent вычисляет разницу между system_date и source date.
>
> «На этой неделе мы добавили auto-commit в процесс-файлы» → если комит был <7 дней назад.

### ❌ Машинный стиль (неестественно)
> «Файл был изменён 28 июня 2026 года агентом.»
> 
> «Коммит был сделан в 14:09 UTC, скрипт git-auto-commit.sh вызван из process-query.json step 3a»

### ❌ Галлюцинация (выдумка)
> «Мы это делали на прошлой неделе» — если факт говорит об этом сегодня. Не нужно добавлять «на прошлой неделе» когда событие было вчера, но не «на этой неделе».

## How It Works

Agent читает frontmatter/git → вычисляет разницу между `date` и текущей системной датой → выбирает естественный относительный термин:
| Разница | Термин |
|---------|--------|
| 0 дней | «сегодня», «сейчас» |
| 1 день | «вчера» / «завтра» |
| 2-3 дня | «позавчера» / «через пару дней» |
| ~7 дней | «на этой неделе» |
| >7 дней | «неделю назад» или точная дата (если контекст требует) |

## Updated [2026-07-03] — stale examples note
- **Issue**: Examples use hardcoded relative dates ("позавчера", "сегодня = 30 июня")
- **Fix**: Agent should compute relative terms dynamically from current system date at query time, not hardcode in page
- **Rule**: Keep examples as templates; agent substitutes real dates during synthesis
- **Source:** `detect-contradications.sh` contradiction group `date:2026-06-28`

## Evolution Rules
- Правило в AGENTS.md → canonical source, всегда читается при старте сессии
- Эта страница → living документ для примеров, кейсов и эволюции
- Если появляются новые паттерны перевода → добавлять секцию «New Patterns» на этой странице
- Ключевые примеры из диалога → сохранять здесь как reference

## Context Marking Contract (draft — Phase 6)

# Agent классифицирует каждый блок контекста при чтении/инструменте по типам.
# Default marks задают поведение при compaction/dismissal. Формат гибкий: agent может override если видит reason.

### Базовые типы и их маркеры

| Тип блока | stale_after_answer | scope | explicit | action_on_stale |
|-----------|--------------------|-------|----------|------------------|
| `tool` (grep, bash, script output) | ✅ true | session | agent-initiated | dismiss |
| `content_read` (wiki pages/docs read for query) | 🟡 depends | session | agent-initiated | evaluate: keep if cross-references needed; else compress or dismiss |
| `conversation` (user prompts & responses) | ❌ false | session | user-initiated | keep until topic switch |
| `schema_once` (instructions re-read at each tool call/AGENTS.md access) | ❌ false | tool-call | system bootstrap | **use for current task → dismiss after** (agent receives again at next read, no need to hold in memory) |
| `schema_hold` (universal wiki rules from AGENTS.md only — on Error Handling, Context Bubble, Search Priority) | ❌ false | session | agent-selected-at-bootstrap | keep until topic switch or end of session |
| `meta_persist` (hot.md, working_memory.json) | ❌ false | persistent | system bootstrap | keep/refresh at session start/end |
| `external_pending` (web_search results awaiting ingest) | 🟡 depends | session | user/tool | dismiss if not saved as wiki; else save_as_wiki |

### Исключения и Overrides

Agent может override default behavior, если:
- **Topic shift**: когда тема сменилась → dismiss all `session` blocks except `conversation` и `schema_hold`
- **User explicitly references** content from stale block → mark as keep (user-initiated relevance)
- **Tool result contains cross-references** or related entities → evaluate as `content_read` instead
- **Stale content with user value**: if dismissed block is referenced by user again → mark as keep

### Stale Evaluation Logic (for depends cases)
✅ Keep: страница содержит related entities, future reference needed, answer requires iterative refinement
❌ Dismiss: facts already used in response, single-use lookup, no cross-references

> Note: это draft. Формат может эволюционировать через `schema-patch` proposals.

## Related Pages
* [AGENTS.md#natural_memory_translation](../../AGENTS.md) — краткое правило агента в Memory Architecture Contract
* [[wiki/overview.md]] — обзор wiki, упоминает natural memory как ключевой принцип
* [[wiki/snapshot.md]] — snapshot проекта
