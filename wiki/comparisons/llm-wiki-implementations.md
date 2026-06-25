---
tags: [comparison, llm-wiki, architecture, platform]
date: 2026-06-25
sources: []
related: [wiki/concepts/llm-wiki.md, wiki/syntheses/rag-vs-llm-wiki-pattern.md]
---

# Сравнение: out/ (Markdown-driven wiki) vs pi-llm-wiki/ (TypeScript platform)

## Введение

Оба проекта реализуют **LLM Wiki Pattern** (Andrej Karpathy), но на разных уровнях абстракции. `out/` — это **база знаний в markdown**, управляемая вручную через Schema и git. `pi-llm-wiki/` — это **TypeScript платформа** с 13+ инструментами, автоматизирующая весь workflow.

## Таблица сравнения

| Критерий | out/ (Markdown-driven) | pi-llm-wiki/ (TS Platform) |
|----------|----------------------|---------------------------|
| **Архитектура** | Markdown + Git + JSON Schema | TypeScript extensions + Tool API + Background Runtime |
| **Ингест** | Агент пишет markdown через `edit`/`write`, обновляет index.md вручную | Вызов `wiki_ingest(source)` → TS инструмент создаёт пакет, генерирует страницу, rebuilds meta автоматически |
| **Поиск (Query)** | Чтение index.md → semantic search → grep-fallback. Agent читает файлы по ссылкам | Вызов `wiki_recall(query)` → layered recall: personal + project vaults, hybrid search |
| **Lint** | Bash скрипты (`link-validator.sh`, `validate-path.sh`), guardrails через bash | Вызов `wiki_lint()` → автоматический анализ противоречий, orphan pages, backlinks rebuild |
| **Guardrails** | validate-path.sh + .git/hooks/pre-commit. Блокирует raw/** и meta/** | Auto-rebuild metadata после каждого wiki edit. Blocks direct edits to protected zones |
| **Meta-данные** | Ручное обновление index.md, log.md, timeline.md через agent actions | Автоматический `rebuildMetadata()` / `buildBacklinks()` на каждом инструменте |
| **Background work** | Нет — всё синхронно в agent turn | Off-thread LLM work (distilling skills, trajectories). Не блокирует agent turn |
| **Git workflow** | Ручной commit после каждого значимого действия. Schema v5: `git add wiki/` + dual commit formats | Platform auto-manages metadata; git used for versioning the codebase itself |
| **Масштабируемость** | ~100 страниц (index.md становится менее эффективным, grep noise) | Layered recall + indexing + embeddings масштабируется до >1000 страниц |

## Детальный анализ

### 1. Ингест: Ручной vs Автоматический

**out/** требует агентного действия на каждом шаге:
- Агент читает источник → пишет summary в wiki/ через `edit`/`write`
- Обновляет index.md, entity/concept pages вручную
- Git commit после ingest

**pi-llm-wiki** абстрагирует это через инструменты:
```bash
wiki_ingest(source="https://example.com" | file="/path/to/doc")
```
→ TS инструмент создает пакет в raw/, генерирует markdown, rebuilds meta. Агент не трогает файлы — только вызывает tool.

**Trade-off**: out/ даёт полный контроль и прозрачность (git diff показывает каждый шаг). pi-llm-wiki быстрее при росте wiki, но сложнее дебажить.

### 2. Поиск: Index.md vs Layered Recall

**out/** читает `index.md` по категориям → находит релевантные страницы → semantic search → grep-fallback. Работает до ~100 страниц, затем index.md становится большим и noisy.

**pi-llm-wiki**:
- `wiki_recall(query)` — layered recall из personal + project vaults одновременно
- Hybrid search (BM25 + embeddings) в фоне
- Не требует чтения index.md целиком

### 3. Lint: Bash скрипты vs Auto-rebuild

**out/** использует bash-скрипты для lint:
- `link-validator.sh --full` — сканирование всех wiki на broken links
- `validate-path.sh` — защита raw/** и meta/** от прямых edit
- Agent парсит JSON из stdout → применяет auto-fix

**pi-llm-wiki**:
- `wiki_lint()` — автоматический анализ противоречий, orphan pages, stale claims
- Auto-rebuild metadata после каждого wiki edit (не требует отдельного lint-шага)
- Background runtime для off-thread analysis

### 4. Background Runtime vs Agent Turn

**out/**: все операции синхронны в agent turn. Каждый ingest/query/lint — это новый agent action с полным контекстом.

**pi-llm-wiki**: background-runtime запускает off-thread LLM work (distilling skills, trajectories). Агент не блокируется — tool возвращает immediate acknowledgment, работа идёт параллельно.

## Сильные и слабые стороны

### out/ — Плюсы
1. **Прозрачность**: каждый шаг виден в git diff, легко debugить
2. **Не зависит от TS-платформы**: работает автономно, нет runtime зависимостей
3. **Гибкая Schema**: AGENTS.md co-evolves с пользователем через прямые edits

### out/ — Минусы
1. **Масштабирование**: при >100 страницах index.md теряет эффективность, grep становится noisy
2. **Нет auto-rebuild meta**: требуется отдельный lint-шаг для backlinks/registry
3. **Синхронность**: каждый operation блокирует agent turn

### pi-llm-wiki — Плюсы
1. **Автоматизация**: ingest/query/lint через tools API, не требует ручных edits
2. **Layered recall + indexing**: масштабируется до >1000 страниц
3. **Background runtime**: off-thread work не блокирует agent turn
4. **Auto-rebuild meta**: metadata rebuilds после каждого wiki edit

### pi-llm-wiki — Минусы
1. **Сложность дебага**: TS-платформа, зависимости от platform API
2. **Harder to customize**: изменения требуют TS-компиляции и reload extension
3. **Platform lock-in**: wiki работает только в рамках платформы

## Итог: когда что использовать

| Сценарий | Рекомендация |
|----------|-------------|
| Wiki < 50 страниц, полный контроль, прозрачность | out/ (Markdown-driven) — проще debugить, гибче Schema |
| Wiki > 100 страниц, нужен scalable search, auto-rebuild | pi-llm-wiki (Platform) — layered recall, indexing, background work |
| Эксперименты с структурой, co-evolution Schema | out/ — прямые edits в AGENTS.md без platform lock-in |
| Production-grade wiki с автоматизацией | pi-llm-wiki — tools API, auto-rebuild, off-thread analysis |

## Связи с нашим проектом

### Текущая реализация (out/)
* Markdown-driven wiki с Schema v6 (AGENTS.md), Error Handling Protocol, JSON git policy
* Bash guardrails: validate-path.sh, link-validator.sh, .git/hooks/pre-commit
* Manual index.md + log.md maintenance
* 36+ страниц по трём темам: LLM Wiki Pattern, Python на NixOS, Symfony

### Возможная интеграция (из pi-llm-wiki)
1. **Auto-rebuild meta**: взять guardrails из pi-llm-wiki для автоматического обновления backlinks/registry после каждого wiki edit
2. **Layered recall**: добавить search по personal + project vaults одновременно вместо ручного index.md чтения
3. **Background distillation**: off-thread skills extraction (opt-in, trajectories)

---
*Создано: 2026-06-25 | Сравнение двух реализаций LLM Wiki Pattern*
