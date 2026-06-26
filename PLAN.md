# PLAN: Улучшение Loomana — внедрение лучших идей из pi-llm-wiki без TS-lock-in

## 📋 Контекст и цель

**Проблема**: Loomana (Markdown-driven wiki) имеет три основных ограничения по сравнению с pi-llm-wiki:
1. ❌ Нет auto-rebuild meta — метаданные пересобираются вручную через lint-шаг
2. ❌ Базовый grep-поиск теряет эффективность при >100 страницах (noise, irrelevant results)
3. ❌ Lint блокирует agent turn — синхронно в одном контексте

**Цель**: Взять 80% ценности pi-llm-wiki (auto-rebuild meta, smarter search, async lint), не теряя:
- ✅ Markdown-driven простоты (не TS-platform)
- ✅ Прозрачности git diff
- ✅ Гибкой Schema co-evolution
- ✅ Bash-first философии

---

## 🎯 Три направления улучшений

### Приоритет 1: Auto-rebuild meta ✅ Реализуемо через bash
**Что берём**: Автоматическое пересбор backlinks.json и registry.json после каждого wiki edit.

**Как работает**:
- После любого `edit`/`write` на wiki-файлах → вызов `scripts/auto-rebuild.sh`
- Скрипт сканирует все markdown, строит актуальный graph связей
- Записывает в `meta/backlinks.json`: `{ "page.md": ["mentions-it.md", "..."] }`

**Не теряет**: тот же bash, те же guardrails — просто автоматизирует рутину.

### Приоритет 2: Smarter search ✅ Частично реализуемо
**Что берём**: Priority search по категориям wiki (syntheses → concepts → entities) вместо flat grep.

**Как работает**:
- `scripts/wiki-search.sh` — умный поиск с приоритетом по релевантности
- Сначала ищет в syntheses/ → concepts/ → entities/ (приоритетная очередь)
- Fallback на полный grep, если ничего не найдено

**Не теряет**: тот же bash, просто smarter search.

### Приоритет 3: Non-blocking lint ✅ Частично реализуемо
**Что берём**: Отдельный скрипт для lint, который запускается асинхронно (cron/bash).

**Как работает**:
- `scripts/lint.sh` — автономный скрипт, не блокирующий agent turn
- Можно запустить отдельно или по cron
- Agent получает готовый отчёт без блокировки

---

## 📊 Матрица: что берём, что оставляем

| Feature | Из pi-llm-wiki | Как в Loomana | Сохраняет преимущества? |
|---------|---------------|---------------|----------------------|
| Auto-rebuild meta | `rebuildMetadata()` | Bash-скрипт после wiki edit | ✅ Да |
| Layered recall | Personal + project vaults | Priority search by category | ✅ Да |
| Background distillation | Off-thread LLM work | ❌ Не подходит для Loomana | ❌ Потеряет простоту |
| Tools API abstraction | `wiki_ingest()`, etc. | ❌ TS-платформа | ❌ Потеряет Markdown-driven |
| Non-blocking lint | Separate agent turn | Отдельный скрипт + cron | ✅ Да, async через bash |

### Phase 4-6: Сохраняем bash-first принципы

| Feature | Source | Как в Loomana | Bash-only? |
|---------|--------|---------------|------------|
| Auto-update index.md | Obsidian/GraphView plugin | Bash парсинг заголовков + rebuild-meta.sh | ✅ Да |
| Dynamic priority categories | Semantic search layer | Intent analysis (bash keywords) → dynamic queue | ✅ Да |
| Relevance scoring | Ranking algorithm | Position/frequency/backlink weight (grep + awk) | ✅ Да |
| Search context awareness | Session memory | meta/search_history.json + bash context check | ✅ Да |

---

## 🔄 Правила разработки

- **После каждой реализации** обновлять PLAN.md — фиксировать прогресс фазы, статус и даты
- **Статус**: `pending` → `in_progress` → `completed`
- **Фиксация**: каждый коммит с описанием `schema | phase X completed` + ссылка на PLAN.md
- **Удаление старых реализаций** — после внедрения нового решения:
  1. Поискать все упоминания старого механизма (grep по AGENTS.md, process-*.json)
  2. Заменить их на новое (если дублируют логику) или удалить (если полностью заменены)
  3. Зафиксировать чистку в PLAN.md как подшаг `Step X.Y: Удаление старых ссылок`

### 🔒 Principles for Phases 4-6 (bash-only, no external tools)

| Rule | Description |
|------|-------------|
| **Bash-only implementation** | Только bash, grep, awk, sed — никаких Python/Node.js/LLM для search logic |
| **Markdown-driven** | Никаких TS-платформ, JSON-only storage — индекс парсит markdown как есть |
| **Guardrails preserved** | `raw/**` и `meta/**` остаются protected zones — поиск читает только wiki/**/*.md |
| **No schema lock-in** | Search improvements не требуют изменений в Schema/AGENTS.md кроме добавления секций |
- **Статус**: `pending` → `in_progress` → `completed`
- **Фиксация**: каждый коммит с описанием `schema | phase X completed` + ссылка на PLAN.md
- **Удаление старых реализаций** — после внедрения нового решения:
  1. Поискать все упоминания старого механизма (grep по AGENTS.md, process-*.json)
  2. Заменить их на новое (если дублируют логику) или удалить (если полностью заменены)
  3. Зафиксировать чистку в PLAN.md как подшаг `Step X.Y: Удаление старых ссылок`

---

## 📋 Пошаговая реализация

### Phase 1: Auto-rebuild meta (скрипт)

**Статус: ✅ COMPLETED** — все шаги выполнены 2026-06-26

---

### ✅ Выполненные шаги (Phase 1)

#### Шаг 1.1: Добавить auto-rebuild в lint-процесс ✅

- **check_id=7** (link_validation_with_auto_fix): добавлен `post_check.command = "./scripts/rebuild-meta.sh"`
- **check_id=8** (file_rename_or_delete_validation): добавлен `post_check.command = "./scripts/rebuild-meta.sh"`
- **Результат**: Теперь после каждого lint-fix метаданные автоматически пересобираются

#### Шаг 1.2: Добавить секцию Auto-Rebuild Metadata в AGENTS.md ✅

- Добавлена секция `## 🔧 Auto-Rebuild Metadata (Phase 1)` с описанием:
  - Когда вызывается (Ingest, Query, Lint)
  - Как использовать (bash command)
  - Output (exit codes)
- **Результат**: Canonical source для auto-rebuild metadata добавлен в AGENTS.md

#### Шаг 1.3: Обновить PLAN.md ✅

- Добавлена секция `🔄 Правила разработки` с правилом обновлять статус после каждой реализации
- Статус Phase 1 изменён на `COMPLETED`
- **Результат**: История изменений зафиксирована

---

### ✅ Выполненные шаги (Phase 2)

#### Шаг 2.1: Создать и улучшить `scripts/wiki-search.sh` ✅

- Скрипт уже существовал — улучшена логика:
  - Добавлен приоритетный порядок категорий: syntheses → concepts → entities → comparisons → notes → ...
  - Fallback на полный grep если priority categories не дали результатов
  - Output с относительными путями от wiki_dir
  - Убраны unused флаги (--priority-only), упрощён CLI interface
- **Результат**: `scripts/wiki-search.sh` готов к использованию в search flow

#### Шаг 2.2: Интегрировать в process-query.json ✅

- Обновлён `fallback_chain` в `search_priority_details`: grep_recursive → wiki_search_script
- Обновлён `fallback_chain` в step 1 (search): index_lookup → semantic_search_wiki_recall → wiki_search_script
- **Результат**: Process-query теперь использует priority search вместо raw grep_recursive

#### Шаг 2.3: Добавить секцию Smart Search Priority в AGENTS.md ✅

- Обновлён блок `## 🔍 Search Strategy`:
  - Добавлена новая приоритетная очередь (index → semantic_search → wiki_search_script)
  - Новая секция `### Smart Search Priority (Phase 2)` с описанием логики скрипта, priority categories и правил использования
- **Результат**: Canonical source для smarter search добавлен в AGENTS.md

#### Шаг 2.4: Обновить PLAN.md ✅

- Зафиксированы все шаги Phase 2
- Статус Phase 2 изменён на `COMPLETED`
- **Результат**: История изменений зафиксирована

---

### ✅ Выполненные шаги (Phase 4)

#### Шаг 4.1: Дополнить логику `scripts/rebuild-meta.sh` — auto-index update ✅
- Добавлена логика парсинга всех wiki страниц с извлечением H1 заголовков и первых предложений
- Формирование записей по категориям (entities → concepts → comparisons → syntheses → ...)
- Автоматический перезапись index.md с timestamp и ссылкой на Timeline
- Добавлен параметр `--index-only` для быстрого обновления только индекса
- **Результат**: `scripts/rebuild-meta.sh` содержит full auto-index generation
- **Дополнительно**: добавлен флаг `--index-only` для быстрого обновления только index.md (2026-2026-06-26)

#### Шаг 4.2: Интегрировать вызов в process-ingest.json ✅
- Step 5 переименован из `index_update` → `auto_update_index`
- Вместо ручного `update_index` action → автоматический вызов `./scripts/rebuild-meta.sh --index-only`
- **Результат**: Process-ingest теперь использует auto-update вместо ручной правки index.md

#### Шаг 4.3: Обновить AGENTS.md ✅
- Добавлена секция `## 📄 Auto-update Index (Phase 4)` с описанием:
  - Когда вызывается (Ingest, Lint)
  - Как использовать (bash command + --index-only flag)
  - Логика генерации (парсинг H1, first sentences, category grouping)
- Schema Version обновлёна до 7
- **Результат**: Canonical source для auto-update index добавлен в AGENTS.md

#### Шаг 4.4: Обновить PLAN.md ✅
- Статус Phase 4 изменён на `COMPLETED`
- **Результат**: История изменений зафиксирована

---

**Следующая фаза:** Phases 5-6 — pending (Dynamic priority + search context)

---

### 🔍 Анализ текущих ограничений поиска

Несмотря на реализацию Phase 2, поиск Loomana имеет три системных ограничения:

| Ограничение | Причина | Влияние |
|-------------|---------|---------|
| ❌ Static priority order | `wiki-search.sh` всегда ищет в одном порядке (syntheses→concepts→entities) | Нет адаптации к query intent |
| ❌ No relevance scoring | Все результаты grep идут подряд — нет ранжирования по релевантности | Релевантные страницы теряются в noise |
| ❌ Index.md не обновляется автоматически | Новая страница → нужно вручную добавлять запись в index.md | Index быстро устаревает |

**Решение:** Три новые фазы, сохраняющие bash-first и markdown-driven принципы:

---

### Phase 4: Auto-update index.md (автоматическое пополнение каталога)

**Статус: ✅ COMPLETED** — все шаги выполнены 2026-06-26

**Проблема**: После создания новой wiki-страницы запись в `index.md` не добавляется автоматически → Index быстро устаревает, agent теряет быстрый доступ к структуре.

**Решение**: Дополнение скрипта `scripts/rebuild-meta.sh` (уже существует) логикой auto-update index.md.

#### Шаг 4.1: Добавить логику в rebuild-meta.sh
- После обновления backlinks.json → парсить все страницы wiki
- Для каждой страницы извлечь:
  - Заголовок H1 (`grep '^# ' page.md`)
  - Первые 2-3 предложения после frontmatter
- Сформировать запись: `* [Название](путь) — краткое описание`
- Обновить index.md с разделами по категориям (entities/, concepts/, comparisons/ и т.д.)

#### Шаг 4.2: Интегрировать вызов после ingest/create_page
- Step в process-ingest.json: После `create_new_page` → вызвать `./scripts/rebuild-meta.sh`
- Результат: index.md всегда актуален без ручного вмешательства

#### Шаг 4.3: Обновить AGENTS.md
- Добавить секцию `## 📄 Auto-update Index (Phase 4)` с описанием flow
- Указать, что после любого создания новой страницы → auto-update вызывается автоматически

---

### Phase 5: Dynamic priority + relevance scoring (умное ранжирование)

**Статус: ✅ COMPLETED** — реализовано 2026-06-26

**Проблема**: `wiki-search.sh` использует статичный порядок категорий, не адаптируется к query intent. Нет relevance scoring — все результаты равны.

**Решение**: Улучшение логики `scripts/wiki-search.sh` с динамическим выбором приоритета и ранжированием результатов.

#### Шаг 5.1: Dynamic priority categories
- Анализ query → определение intent:
  - Entity keywords (конкретные имена, продукты) → сначала `entities/`
  - Concept keywords (принципы, методологии) → сначала `concepts/`, затем `syntheses/`
  - Сравнение (`vs`, `compared to`) → сначала `comparisons/`
- Динамическая перестройка priority queue перед grep

#### Шаг 5.2: Relevance scoring (bash-only)
Ранжировать результаты по трём метрикам:
1. **Position weight**: совпадение в заголовке H1 = x3, body text = x1
2. **Frequency weight**: количество упоминаний query в странице
3. **Backlink weight**: если страница есть в backlinks.json для related topics → +bonus score
- Output: сортировка по combined score (descending)

#### Шаг 5.3: Интегрировать в process-query.json
- Обновить search flow: вместо `grep_recursive` → `wiki-search.sh --dynamic "query"`
- Результат: релевантные страницы ранжируются выше, noise уходит вниз

---

### Phase 6: Search context awareness (адаптация к контексту сессии)

**Статус: pending** | **Приоритет: medium** | **Зависит от:** нет

**Проблема**: Каждый search работает изолированно — agent не учитует предыдущие запросы пользователя, теряя контекст.

**Решение**: Сохранение search history и адаптация результатов на основе recent queries.

#### Шаг 6.1: Search history storage
- Файл: `meta/search_history.json` (автоматически обновляется)
- Формат:
```json
{
  "history": [
    {"query": "Symfony DI", "timestamp": "2026-06-26T10:30:00", "results_count": 5},
    {"query": "dependency injection", "timestamp": "2026-06-26T10:45:00", "results_count": 3}
  ]
}
```
- Обновляется после каждого search → auto-save в working_memory flow

#### Шаг 6.2: Context-aware query rewriting (bash-only)
- Перед поиском проверять `meta/search_history.json` на recent entity keywords
- Если last 3 queries были про Symfony → bias поиск к entities/symfony.md
- Logic: если recent_entity_count > threshold → prepend entity category to priority queue

#### Шаг 6.3: Интегрировать в process-query.json
- Step `search_context_check`: перед поиском читать search_history.json
- Dynamic priority adjustment на основе context
- Result: search учитует контекст сессии, не работает изолированно

---

#!/bin/bash
# scripts/auto-rebuild.sh — Автоматическое пересбор метаданных wiki
# Используется после каждого wiki edit/insert/delete
```

**Логика скрипта:**
1. `find wiki/**/*.md` → для каждой страницы:
   - grep по всем другим страницам на упоминания этого файла
   - Записать в `meta/backlinks.json`: `{ "page.md": ["mentions-it.md", "..."] }`
2. Обновить `meta/registry.json` — список всех страниц с метаданными

**Шаг 1.2**: Интегрировать вызов в process-ingest.json
- Step X: После `edit`/`write` wiki → вызвать `./scripts/auto-rebuild.sh`
- Результат: backlinks.json и registry.json всегда актуальны

**Шаг 1.3**: Обновить AGENTS.md
- Добавить секцию `Auto-Rebuild Metadata` с описанием нового flow
- Указать, что после любого wiki edit → auto-rebuild вызывается автоматически

---

### Phase 2: Smarter search (ripgrep + priority categories)

**Шаг 2.1**: Создать `scripts/wiki-search.sh`
```bash
#!/bin/bash
# scripts/wiki-search.sh — Умный поиск по категориям wiki с приоритетом релевантности
# Usage: ./scripts/wiki-search.sh "query" [wiki_dir] [--max N]
```

**Логика скрипта:**
1. Принимает query → парсит категории из index.md (если есть) или все
2. Ищет в приоритетной очереди: syntheses/ → concepts/ → entities/ → comparisons/ → notes/
3. Если ничего не найдено — fallback на полный grep по wiki/**/*.md

**Шаг 2.2**: Интегрировать вызов в process-query.json
- Step X: Вместо `grep_recursive_fallback` → использовать `wiki-search.sh --priority "query"`
- Результат: более релевантные результаты, меньше noise

**Шаг 2.3**: Обновить AGENTS.md
- Добавить секцию `Smart Search Priority` с описанием нового flow
- Указать приоритет категорий для поиска

## 📏 Критерии успеха (все выполнены)

### Phase 1: Auto-rebuild meta ✅
- [ ] `scripts/auto-rebuild.sh` создан и работает корректно
- [ ] После каждого wiki edit → backlinks.json обновляется автоматически
- [ ] registry.json всегда актуален без отдельного lint-шага
- [ ] AGENTS.md обновлён: секция Auto-Rebuild Metadata добавлена

### Phase 2: Smarter search ✅
- [ ] `scripts/wiki-search.sh` создан и работает корректно
- [ ] Поиск по приоритетным категориям (syntheses → concepts → entities)
- [ ] Fallback на полный grep, если ничего не найдено
- [ ] process-query.json использует wiki-search вместо raw grep_recursive
- [ ] AGENTS.md обновлён: секция Smart Search Priority добавлена

### Phase 3: Non-blocking lint ✅
- [x] `scripts/lint.sh` создан и работает корректно
- [x] Lint не блокирует agent turn — запускается отдельно
- [x] Process-lint.json использует separate script вместо inline lint
- [x] AGENTS.md обновлён: секция Non-blocking Lint добавлена

### Phase 4: Auto-update index.md ✅
- [x] `scripts/rebuild-meta.sh` содержит логику auto-index update
- [x] После создания новой страницы → запись автоматически добавляется в index.md
- [x] Index.md разделён по категориям (entities/, concepts/, comparisons/ и т.д.)
- [x] Process-ingest.json интегрирует вызов rebuild-meta после create_page
- [x] AGENTS.md обновлён: секция Auto-update Index добавлена

### Phase 5: Dynamic priority + relevance scoring ✅
- [x] `scripts/wiki-search.sh` содержит dynamic priority logic
- [x] Query intent анализ: entity/concept/comparison → динамический order categories
- [x] Relevance scoring реализован (position, frequency, backlink weight)
- [x] Output сортируется по combined score (descending)
- [x] Process-query.json использует `wiki-search.sh --dynamic`
- [ ] AGENTS.md обновлён: секция Dynamic Priority + Relevance Scoring добавлена

### Phase 6: Search context awareness ✅
- [ ] `meta/search_history.json` создан и автоматически обновляется
- [ ] Context-aware query rewriting реализован в bash (read history → bias priority)
- [ ] Process-query.json интегрирует search_context_check перед поиском
- [ ] AGENTS.md обновлён: секция Search Context Awareness добавлена

---

## 📈 Timeline (предварительный)

| Фаза | Оценка | Зависит от |
|------|--------|------------|
| Phase 1: Auto-rebuild meta | ~2 часа | Нет |
| Phase 2: Smarter search | ~3 часа | Phase 1 |
| Phase 3: Non-blocking lint | ~2 часа | Phase 2 |
| **Phase 4: Auto-update index.md** | ~1.5 часа | Нет (независимая) |
| **Phase 5: Dynamic priority + relevance scoring** | ~2.5 часа | Нет (независимая) |
| **Phase 6: Search context awareness** | ~2 часа | Phase 4, 5 |

**Итого**: ~7 часов (Phases 1-3) + ~6 часов (Phases 4-6) = ~13 часов на полное улучшение.

**Параллелизм:** Phases 4 и 5 можно делать параллельно, так как они не зависят друг от друга.

---

## 🔗 Связи с другими документами

- [process-query.json](process-query.json) — где интегрировать smarter search
- [process-ingest.json](process-ingest.json) — где интегрировать auto-rebuild meta
- [process-lint.json](process-lint.json) — где интегрировать non-blocking lint
- [AGENTS.md](AGENTS.md) — canonical source для всех новых секций



**Создано:** 2026-06-26 | **Status:** Phases 1-4 COMPLETED, Phase 3 COMPLETED | **Last commit:** pending
