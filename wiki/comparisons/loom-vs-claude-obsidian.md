---
tags: [ architecture, wiki-framework, ingest, workflow]
date: 2026-07-01
type: comparison
category: comparison
sources: [raw/github/AgriciDaniel/claude-obsidian, /home/andrew/projects/local_wiki/loom/wiki/entities/loomana.md]
related: [wiki/concepts/natural-memory.md, wiki/entities/pi-coding-agent.md, wiki/concepts/wiki-schema.md, wiki/comparisons/llm-wiki-implementations.md]
---

# LOOM vs claude-obsidian — Сравнение двух реализаций LLM Wiki Companion


Comparative analysis covering LOOM vs claude-obsidian — Сравнение двух реализаций LLM Wiki Companion across different contexts and implementations.


## Определение

Сравнительный анализ двух проектов, основанных на одной идее — «LLM Wiki Companion» (persistent knowledge base managed by an AI agent). **LOOM** (`/home/andrew/projects/local_wiki/loom`) — рабочий продукт с реальным контентом и depth-обработкой знаний. **claude-obsidian** (`/home/andrew/.pi/agent/skills/claude-obsidian` / GitHub: `AgriciDaniel/claude-obsidian`) — фреймворк-плагин для Obsidian с breadth-архитектурой, cross-platform support и methodological modes.

**Дата анализа:** 2026-07-01 | **Обновлено:** 2026-07-01 (полный пересмотр)

---

## Ключевые характеристики

| Критерий | LOOM (Loomana) | claude-obsidian |
|----------|----------------|-----------------|
| **Архитектура** | Монолитная схема: `AGENTS.md` → `process-{ingest,query,lint}.json` → 25+ bash/python скриптов | Микросервисная: 15 skills (each has SKILL.md), routing через `wiki/SKILL.md` |
| **Цель** | Построить конкретную wiki — продукт с реальным контентом | Поставить инструмент для создания любых wikis — generic framework |
| **Глубина обработки знаний** | Evidence grading, contradiction cascade (code_reality > live_state > docs), decision rules, dynamic search scoring | Transport detection, advisory locking, delta tracking, token discipline |
| **Гибкость структуры** | Жёсткая: entities/, concepts/, syntheses/... (оптимизирована под один use-case) | Адаптивная: LYT / PARA / Zettelkasten / Generic через `.vault-meta/mode.json` |
| **Реальный контент** | 36+ wiki pages, 7 raw sources, active log.md, git history | Zero user content — framework only (no sample vault) на момент анализа |
| **Production-скрипты** | 25 bash/python скриптов: lint, link-validator, text-similarity, wiki-search, etc. | Нет скриптов в repo (только templates и SKILL.md docs) |
| **Масштабируемость идеи** | Заточен под одного пользователя, одну тему | Generic framework для любого vault-а, cross-project referencing, multi-agent support |

---

## Анализ: Deep Dive

### 1. Архитектурная философия

```
LOOM:                claude-obsidian:
AGENTS.md (монолит)    → 15 skills (routing)
   ↓                      ↓
process-{ingest}       → wiki-ingest/SKILL.md
process-{query}        → wiki-query/SKILL.md  
process-{lint}         → wiki-lint/SKILL.md
   ↓                      ↓
25 production scripts  → templates + references (no implementation)
```

**LOOM** — это **работа** над знаниями. Monolithic schema, который растёт с каждым вопросом и источником. Каждый step в process-файлах имеет чёткие preconditions, actions, decision logic.

**claude-obsidian** — это **инструмент** для работы с знаниями. Каждая skill — отдельный файл `SKILL.md` с name/description frontmatter, совместимый со стандартом Agent Skills (Codex CLI, OpenCode, и другие кросс-платформенные агенты).

### 2. Ингест: глубина vs широта

| Компонент | LOOM | claude-obsidian |
|-----------|------|-----------------|
| **Delta tracking** | `check-new-sources.sh --quick` + timestamp caching в WM | `.raw/.manifest.json` — hash-based, pages_created/pages_updated per source |
| **Transport layer** | Filesystem Read/Write/Edit (единственный путь) | CLI → MCP → filesystem fallback chain через `.vault-meta/transport.json` |
| **Advisory locking** | Pre-commit hook + guardrails на protected zones | `wiki-lock.sh` — per-file granularity, age-based staleness (60s), cross-process release |
| **Mode routing** | Нет — жёсткая структура папок | `scripts/wiki-mode.py route` → LYT/PARA/Zettelkasten/Generic |
| **Contradiction detection** | `detect-contradications.sh`, cascade resolution (objective/subjective) | `[!contradiction]` callout + user override для subjective фактов |

### 3. Поиск и Query: static vs dynamic

**LOOM:**
- Search priority: `index_lookup → semantic_search → wiki-search.sh fallback`
- Dynamic scoring в `wiki-search.sh --dynamic`: position weight, frequency, backlink weight, category bonus
- `search_analytics.json` — S5 persistent rating DB, topic popularity boost
- Context Bubble: max 3 concurrent pages, dismiss least important when exceeded

**claude-obsidian:**
- Query modes: Quick (hot.md only, ~1.5K tokens), Standard (hot + index + 3-5 pages), Deep (full wiki)
- Static priority categories: `syntheses/ > concepts/ > entities/`
- Optional `wiki-retrieve`: BM25 + cosine-rerank (contextual retrieval, modeled on Anthropic's Sept 2024 research)
- No dynamic scoring — relies on static category priority + manual index scanning

### 4. Lint и Health Check

**LOOM:**
- `unified-pass.sh` replaces 3 separate script walks
- 11 checks: contradictions, orphans, new sources, duplicates, date inconsistencies, broken links, meta stale, hot cache stale, etc.
- Auto-fix via `--auto` flag + output normalization
- Post-op link validation after every ingest

**claude-obsidian:**
- `wiki-lint/SKILL.md` — advisory, human-driven lint
- No automated scripts for contradiction detection
- Focus на manual review + `[!contradiction]` / `[!gap]` custom callouts

### 5. Memory и Session Management

**LOOM:**
- `working_memory.json` — Context Bridge между сессиями (focus_node, query_summary, next_steps_todo)
- Harness-independent session ops: 4 key scripts (git-auto-commit.sh, load-hot-cache.sh, restore-hot-cache.sh, check-wiki-changes.sh)
- Natural Memory Translation: «позавчера» вместо «2026-06-28», human-time from machine facts

**claude-obsidian:**
- `wiki-fold`: DragonScale Mechanism 1 — rollup of last 2^k log entries into meta-pages with deterministic IDs, extractive summarization (no invention)
- Hot.md-based context между сессиями (без structured WM)
- No natural memory translation

### 6. Дополнительные возможности claude-obsidian

| Feature | LOOM | claude-obsidian |
|---------|------|------------------|
| **Canvas visual layer** | ❌ Нет | ✅ JSON Canvas с auto-positioning, zones, image/PDF/note nodes |
| **Obsidian Bases (.base)** | ❌ Нет | ✅ Динамические таблицы, фильтры, формулы, карточный/списочный view |
| **Defuddle** | ❌ Нет | ✅ Strip ads/navigation from URLs — 40-60% token savings |
| **Image/Vision ingestion** | ❌ Нет | ✅ Read image → describe → save to raw + attachments |
| **Address Assignment (DragonScale)** | ❌ Нет | ✅ Stable `c-XXXXXX` IDs через atomic counter, backlink index |

---

## Что LOOM заимствует из claude-obsidian (IF приоритеты)

**High Priority:**
1. Mode-based routing — маршрутизация источников по категориям (LYT/PARA/Zettelkasten)
2. Transport abstraction — fallback chain для multi-platform support
3. Advisory locking — `wiki-lock.sh` аналог для safe concurrent writes
4. Delta tracking через `.raw/.manifest.json` — hash-based, skip unchanged sources

**Medium Priority:**
5. Image/Vision ingestion pipeline — raw/images/ + _attachments/images/
6. Web egress hygiene — URL validation, content sanitization (defuddle)
7. Address assignment — stable IDs для pages вместо path-based routing

**Low Priority:**
8. Canvas visual layer (JSON-based, не требует Obsidian UI)
9. Zettelkasten/PARA modes для гибкой организации структуры

---

## Что claude-obsidian мог бы заимствовать из LOOM

**High Priority:**
1. Evidence grading — classification `documented > corroborated > assertion_only`
2. Contradiction cascade resolution — authoritative > temporal > user_review (не просто `[!contradiction]`, а *как* его разрешать)
3. Dynamic search scoring — wiki-search.sh учитывает frequency, backlinks, category bonus
4. Decision Rules (DR-1..5) — authorship/overlap detection, time decay для summary pages (>30 days = -50% popularity), merge duplicates

**Medium Priority:**
5. Context Bubble — max 3 concurrent pages, prevent token overload
6. Compounding decision logic — когда ответ worth saving as new wiki page (novel insight from ≥2 sources)
7. Search analytics — topic frequency tracking → popularity boost for relevant queries

**Low Priority:**
8. Harness-independent session ops — hot.md lifecycle + check-wiki-changes.sh end-of-session flush
9. Working_memory.json — structured context bridge между сессиями (focus_node, query_summary)

---

## Выводы

claude-obsidian мог бы стать сильнее LOOM'а если бы автор доделал каждую skill до уровня process-файлов LOOM: ingest → evidence_grade → contradiction cascade → dynamic scoring. Сейчас он — skeleton с good ideas, но без meat в каждой зоне обработки знаний.

LOOM же — working product с depth (evidence grading, contradiction resolution), но без breadth (только одна организация, один transport, нет canvas/bases/fold).

**Самый честный вывод:** гибкость структуры у claude-obsidian реальный плюс (mode-based routing, transport abstraction, cross-platform support), который стоит подумать о внедрении в LOOM. Но качество обработки знаний — уникальная глубина LOOM'а, которую никто другой не повторил.

**Идеальная комбинация:** LOOM depth + claude-obsidian breadth = production-grade wiki system с auto-rebuild meta, mode routing, evidence grading, и canvas visual layer.

---

*Created: 2026-06-29 | Type: comparison | Last updated: 2026-07-01 (полный пересмотр архитектуры)*