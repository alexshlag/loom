---
tags: [ingest, workflow, claude-obsidian, architecture]
date: 2026-06-30
type: documentation
category: concept
sources: [wiki/comparisons/loom-vs-claude-obsidian.md, /home/andrew/projects/claude-obsidian/skills/wiki-ingest/SKILL.md, /home/andrew/projects/claude-obsidian/skills/autoresearch/SKILL.md]
related: [wiki/concepts/natural-memory.md, wiki/entities/pi-coding-agent.md]
---

# Ingest Workflow Patterns — Claude-obsidian vs Loomana

## Definition
Сравнительный анализ архитектур ingest и обработки источников между **claude-obsidian** (фреймворк) и **Loomana** (LOOM). Выявляет лучшие практики, которые можно заимствовать в нашу систему.

## Core Ingest Mechanisms

### Claude-obsidian: Dual-path Ingest
Claude-obsidian реализует два отдельных пути ingest:

1. **URL Ingestion** (через `wiki-ingest` skill):
   - Fetch → Defuddle → Slug derivation → `.raw/articles/[slug]-[date].md`
   - Delta tracking через `.raw/.manifest.json`
   - Single source ingest из `.raw/` в wiki

2. **Direct-to-wiki filing** (через `autoresearch` skill):
   - Web search + fetch → прямое создание страниц в `wiki/sources/`, `wiki/concepts/`, `wiki/entities/`
   - Без промежуточного `.raw/` слоя

### Loomana: Immutable Raw Layer
- `raw/**` — только чтение, защищён через `validate-path.sh`
- Agent пишет напрямую в `wiki/**`
- Нет промежуточного raw для web sources — web_search сразу → wiki

## Key Differences & Best Practices

### 1. Mode-based Routing (Claude-obsidian)
```python
# Python script routes content to correct folder based on vault mode
python3 scripts/wiki-mode.py route source "Topic Name"
# generic:    wiki/sources/[topic].md
# LYT:        wiki/notes/[topic].md + MOC update
# PARA:       wiki/resources/incoming/[topic].md
# zettelkasten: wiki/<timestamp>-[topic].md
```
**Зачем**: Автоматическая маршрутизация контента в зависимости от методологии.

### 2. Transport Abstraction Layer
Claude-obsidian поддерживает три способа записи через `.vault-meta/transport.json`:
- **CLI** — `obsidian-cli write` (preferred)
- **MCP** — MCP server protocol
- **Filesystem** — direct Write/Edit tools (fallback)

### 3. Advisory File Locking
```bash
# Per-file locking prevents concurrent write corruption
wiki-lock.sh acquire wiki/concepts/[page].md
# ... write operations ...
wiki-lock.sh release wiki/concepts/[page].md
```
Скрипт использует `flock`, age-based staleness (60s), cross-process release.

### 4. Delta Tracking
`.raw/.manifest.json` хранит:
- Source hash → skip if unchanged
- Pages created/updated per source
- Address map для стабильных ID

### 5. Image/Vision Ingestion
Два файла на одно изображение:
- `.raw/images/[slug]-[date].md` — markdown с OCR + описанием
- `_attachments/images/[slug].[ext]` — копия оригинала в vault

## Loomana Advantages

| Aspect | Loomana | Claude-obsidian |
|--------|---------|-----------------|
| Raw immutability | ✅ `validate-path.sh` guardrails + pre-commit hook | ⚠️ `.raw/**` read-only, но без filesystem-level protection |
| Schema co-evolution | ✅ AGENTS.md живая схема с user approval | ❌ Static skill templates |
| Context bubble | ✅ Max 3 pages в контексте | ❌ Нет ограничения |
| Compacting memory | ✅ `restore-hot-cache.sh` после compact | ⚠️ Только hot.md |
| Natural memory translation | ✅ "позавчера" вместо "2026-06-28" | ❌ Raw dates |

## Заимствуемые решения для Loomana

### High Priority (IF-1..IF-4)
1. **Mode-based routing** — добавить `wiki-mode.py` или аналог для маршрутизации новых страниц по категориям
2. **Transport abstraction** — подготовить fallback chain (MCP → filesystem), пока filesystem-only
3. **Advisory locking** — `scripts/wiki-lock.sh` для safe concurrent writes
4. **Delta tracking** — `.raw/.manifest.json` или аналог в нашем проекте

### Medium Priority
5. **Image ingestion pipeline** — `.raw/images/` + `_attachments/images/` структура
6. **Web egress hygiene** — URL validation, content sanitization (script tags, wikilink injection)
7. **Address assignment** — DragonScale c-XXXXXX для стабильных ссылок

### Low Priority (deferred)
8. **MCP server support** — пока filesystem-only достаточно
9. **Zettelkasten/para modes** — только если пользователь выберет методологию

## Conclusions
Claude-obsidian предоставляет более структурированный ingest workflow с тремя слоями абстракции: routing → transport → locking. Loomana выигрывает в schema co-evolution и контекстном управлении. Комбинация лучших практик даст hybrid architecture.

---

*Created: 2026-06-30 — анализ сравнения ingest архитектур.*
