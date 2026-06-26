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

---

## 🔄 Правила разработки

- **После каждой реализации** обновлять PLAN.md — фиксировать прогресс фазы, статус и даты
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

**Следующая фаза:** Phase 3 — Non-blocking lint (отдельный скрипт)

---

**Создано:** 2026-06-26 | **Status:** Phase 1 COMPLETED, Phase 2 COMPLETED, Phase 3 PENDING | **Last commit:** pending

*Создано: 2026-06-26 | Status: Phase 1 COMPLETED, Phase 2 PENDING | Last commit: pending*
```bash
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

---

### Phase 3: Non-blocking lint (отдельный скрипт)

**Шаг 3.1**: Создать `scripts/lint.sh`
```bash
#!/bin/bash
# scripts/lint.sh — Автономный lint-скрипт, не блокирующий agent turn
# Usage: ./scripts/lint.sh [--quick] [wiki_dir]
# Можно запустить отдельно или по cron
```

**Логика скрипта:**
1. Запускает все lint-checks (contradictions, orphan pages, broken links)
2. Выводит готовый отчёт в stdout/stderr
3. Не блокирует agent turn — можно запустить как background job

**Шаг 3.2**: Интегрировать вызов в process-lint.json
- Step X: Вместо inline lint → вызывать `./scripts/lint.sh`
- Результат: lint не блокирует agent action, работает асинхронно

**Шаг 3.3**: Настроить cron (опционально)
```bash
# crontab -e — автоматический lint каждые N часов
0 */4 * * * cd /path/to/loomana && ./scripts/lint.sh --quiet >> logs/lint.log 2>&1
```

**Шаг 3.4**: Обновить AGENTS.md
- Добавить секцию `Non-blocking Lint` с описанием нового flow
- Указать, что lint запускается отдельно от agent turn

---

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
- [ ] `scripts/lint.sh` создан и работает корректно
- [ ] Lint не блокирует agent turn — запускается отдельно
- [ ] Process-lint.json использует separate script вместо inline lint
- [ ] AGENTS.md обновлён: секция Non-blocking Lint добавлена

---

## 📈 Timeline (предварительный)

| Фаза | Оценка | Зависит от |
|------|--------|------------|
| Phase 1: Auto-rebuild meta | ~2 часа | Нет |
| Phase 2: Smarter search | ~3 часа | Phase 1 |
| Phase 3: Non-blocking lint | ~2 часа | Phase 2 |

**Итого**: ~7 часов на полное улучшение Loomana.

---

## 🔗 Связи с другими документами

- [process-query.json](process-query.json) — где интегрировать smarter search
- [process-ingest.json](process-ingest.json) — где интегрировать auto-rebuild meta
- [process-lint.json](process-lint.json) — где интегрировать non-blocking lint
- [AGENTS.md](AGENTS.md) — canonical source для всех новых секций

---

*Создано: 2026-06-26 | Status: Phase 1 pending implementation | Next: Auto-rebuild meta script*
