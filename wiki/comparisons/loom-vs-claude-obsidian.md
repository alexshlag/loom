---
tags: [comparison, architecture, wiki-framework]
date: 2026-06-29
type: comparison
category: comparison
sources: []
related: [wiki/concepts/wiki-schema.md]
---

# LOOM vs claude-obsidian — Сравнение двух реализаций LLM Wiki Companion

## Определение

Сравнительный анализ двух проектов, основанных на одной идее — «LLM Wiki Companion» (persistent knowledge base managed by an AI agent). **LOOM** (`/home/andrew/projects/local_wiki/loom`) — рабочий продукт с реальным контентом и depth-обработкой знаний. **claude-obsidian** (`/home/andrew/.pi/agent/skills/claude-obsidian`) — фреймворк-плагин для Obsidian с breadth-архитектурой, но без пользовательского контента на момент анализа (2026-06-29).

## Ключевые характеристики

| Критерий | LOOM | claude-obsidian |
|----------|------|-----------------|
| **Архитектура** | Монолитная схема: AGENTS.md → process-{ingest,query,lint} → 25 скриптов | Микросерисная: 14 skills (each has SKILL.md), routing через wiki/SKILL.md |
| **Цель** | Построить конкретную wiki — продукт | Поставить инструмент для создания чужих wikis |
| **Глубина обработки знаний** | Evidence grading, contradiction cascade, decision rules, dynamic search scoring | Transport detection, advisory locking, delta tracking, token discipline |
| **Гибкость структуры** | Жёсткая: entities/, concepts/, syntheses/... (оптимизирована под один use-case) | Адаптивная: LYT / PARA / Zettelkasten / Generic через .vault-meta/mode.json |
| **Реальный контент** | 36 wiki pages, 7 raw sources, active log.md, git history | Zero user content — framework only (no sample vault) |
| **Production-скрипты** | 25 bash/python скриптов: lint, link-validator, text-similarity, wiki-search, etc. | Нет скриптов в repo (только templates и SKILL.md docs) |
| **Масштабируемость идеи** | Заточен под одного пользователя, одну тему | Generic framework для любого vault-а, cross-project referencing |

## Анализ

### Сильные стороны LOOM

1. **Система оценки фактов (evidence_grade)**: каждый факт классифицируется как `documented > corroborated > assertion_only`. Это определяет priority в cascade-resolution противоречий. У конкурента этого нет — он только ставит `[!contradiction]` callout без градации.

2. **Decision Rules (DR-1..5)**: авторство/overlap detection, time decay для summary страниц (>30 days = -50% popularity), merge duplicates. У конкурента — ни одной decision rule.

3. **Dynamic search scoring**: `wiki-search.sh --dynamic` учитывает position weight, frequency, backlinks, category bonus. Конкурент использует static priority (syntheses > concepts > entities).

4. **Contradiction resolution cascade**: authoritative > temporal > user_review. LOOM не просто флажит противоречие — он знает *как* его разрешать.

5. **Полный жизненный цикл контента**: ingest → evidence_grade + category + tags → auto-crosslink scoring ≥5 → summary creation trigger (≥3 pages = auto-create faq_summary) → time decay check → merge duplicates → snapshot.md update.

### Сильные стороны claude-obsidian

1. **Transport Detection & Fallback Chain**: автоматически детектирует CLI > MCP > filesystem, пишет `transport.json`, использует лучший доступный путь. LOOM всегда идёт по единственному пути (Read/Write/Edit на файлах).

2. **Methodology Modes**: vault может объявить организацию через `.vault-meta/mode.json` — LYT (MOC-ноды), PARA (Projects/Areas/Resources/Archives), Zettelkasten (timestamped IDs, no folders). LOOM имеет жёсткую структуру без этой адаптивности.

3. **Visual Layer (Canvas)**: JSON Canvas для Obsidian с auto-positioning, zones, image/PDF/note nodes. Отдельный modal layer для визуального мышления. У LOOM этого нет.

4. **Log Rollup (wiki-fold)**: берёт `2^k` записей из log.md, делает extractive rollup без выдуманных фактов, пишет `wiki/folds/` с детерминистичным ID. LOOM имеет `working_memory.json`, но не умеет агрегировать историю работы.

5. **Delta Tracking через .manifest.json**: хеширует каждый файл в `.raw/.manifest.json`, проверяет hash перед обработкой — unchanged = skip. LOOM не знает, ingesting ли источник повторно.

6. **Obsidian Bases (.base files)**: динамические таблицы, фильтры, формулы, карточные/списочные виды через native Obsidian format. У LOOM нет.

7. **Advisory file-locking**: per-file granularity с age-based staleness (60s), cross-process release. LOOM's guardrails — на уровне git hooks (pre-commit blocks protected zones).

### Архитектурная разница: глубина vs широта

```
LOOM:                claude-obsidian:
AGENTS.md (монолит)    → 14 skills (routing)
   ↓                      ↓
process-{ingest}       → wiki-ingest/SKILL.md
process-{query}        → wiki-query/SKILL.md  
process-{lint}         → wiki-lint/SKILL.md
   ↓                      ↓
25 production scripts  → templates + references (no implementation)
```

LOOM — это **работа** над знаниями. claude-obsidian — это **инструмент** для работы с знаниями. Разные оси: LOOM глубже в каждой зоне, конкурент шире по возможностям организации.

## Выводы

claude-obsidian мог бы стать сильнее LOOM'а если бы автор доделал каждую skill до уровня process-файлов LOOM (ingest → evidence_grade → contradiction cascade → dynamic scoring). Сейчас он — skeleton с good ideas, но без meat в каждой зоне.

LOOM же — working product с depth, но без breadth (только одна организация, один transport, нет canvas/bases/fold).

**Самый честный вывод:** гибкость структуры у конкурента реальный плюс, который стоит подумать о внедрении в LOOM. Но качество обработки знаний — уникальная глубина LOOM'а, которую никто другой не повторил.

---
*Created: 2026-06-29 | Type: comparison | Author: agent via ingest process*
