# Loomana — Wiki System Documentation

## Что такое Loomana?

**Loomana** (внутреннее имя `loom`) — это **LLM-powered personal knowledge base**, где знания компандятся с каждым новым источником и вопросом. Внутренняя философия: вместо стандартного RAG, который каждый раз заново извлекает фрагменты документов, здесь знания **компилируются один раз** и **поддерживаются актуальными**.

*Идея: [Andrej Karpathy](entities/andrej-karpathy.md). Референс: [LLM Wiki gist](https://gist.github.com/karpathy/ed8f284379605148297b7a8be01eb580).*

---

## LLM Wiki vs RAG — ключевые различия

| Критерий | RAG / NotebookLM | LLM Wiki Pattern (Loomana) |
|----------|------------------|----------------------------|
| Знания каждый запрос | 🔴 Rediscover from scratch | 🟢 **Compounding** (растёт с каждым шагом) |
| Cross-references | ❌ Нет | ✅ Явные ссылки между страницами |
| Contradictions | ❌ Не ловит | ✅ Flagging при каждом ingest |
| Сложные вопросы | 5+ документов каждый раз | Wiki уже синтезировала ответы |

**Когда использовать Loomana:** долгосрочный research, deep-dive за недели/месяцы, team internal wiki.  
**Когда не нужен:** ad-hoc queries, one-shot analysis, когда есть готовая база.

---

## Архитектура: три слоя

### 1. Raw Sources (`raw/`) — Immutable
- **sources/** — загруженные статьи, документы
- **github/** — forked repos с исходниками
- **Правило:** LLM не пишет туда напрямую, только через capture flow
- Все изменения проходят через: `capture → ingest → delete`

### 2. Wiki (`wiki/`) — LLM owns this layer
Логическая структура:

| Папка | Назначение |
|-------|------------|
| `entities/` | Конкретные объекты: люди, компании, технологии, инструменты |
| `concepts/` | Абстрактные идеи, принципы, методологии |
| `comparisons/` | Сравнительный анализ сущностей и концептов |
| `syntheses/` | Глубокий анализ, объединяющий несколько источников |
| `notes/` | Личные заметки, транскрипты встреч, наблюдения |
| `meetings/` | Встречи с решениями, action items |
| `projects/` | Текущие и завершённые проекты со статусами |
| `bibliography/` | Книги, статьи, исследования |
| `resources/` | Подборки инструментов, плагинов, библиотек |

Root файлы:
- `index.md` — каталог всех страниц wiki
- `log.md` — хронологический журнал действий
- `overview.md` — текущая картина знаний
- `snapshot.md` — одностраничный срез актуальных фактов из всех страниц

### 3. Schema & Processes
- **AGENTS.md** — живая схема: конвенции, форматы страниц, рабочие процессы
- **process-ingest.json** — workflow добавления источников
- **process-query.json** — ответы на вопросы через wiki
- **process-lint.json** — проверка здоровья базы

---

## Три рабочих процесса

### Ingest — добавление источника

```
┌─────────────┐     источник      ┌──────────────┐
│  Пользователь ─────────────────▶  raw/sources/ │
└─────────────┘                   └──────────────┘
                                    ↓
                              capture → integrate flow
                                    ↓
                    читает, обсуждает тезисы с пользователем
                                    ↓
              пишет summary → wiki, обновляет index.md
                                    ↓
                            записывает entry в log.md
```

**Правила:**
- Raw sources — только чтение. Новые версии → новые пакеты, не перезапись
- Все изменения через capture flow (никогда прямые правки)
- Agent сам классифицирует: entity / concept / notes

### Query — ответ на вопрос

```
┌─────────────┐     вопрос      ┌──────────────────┐
│  Пользователь ───────────────▶  index.md lookup  │
└─────────────┘                   └──────────────────┘
                                    ↓
                          semantic search (wiki_recall)
                                    ↓
                           grep-fallback по категориям
                                    ↓
                    читает найденные страницы (max 3 concurrent)
                                    ↓
              синтезирует ответ с фактами, ссылками, цитатами
                                    ↓
        если novel insight → предлагает сохранить как новую страницу
```

**Search priority:** `index_lookup → semantic_search → wiki-search.sh`

### Lint — поддержание здоровья базы

- Периодическая проверка: противоречия, orphan-страницы, broken links
- Agent получает готовый сухой остаток — не читает всё подряд
- Resolution flow (fixing contradictions) — зона ingest/query

**Checks:**
1. Contradictions — soft scan `## Обновлено`
2. Orphan pages — страницы без ссылок
3. New sources unprocessed — необработанные пакеты
4. Duplicate titles — дубликаты заголовков
5. Date inconsistencies — несоответствия дат
6. Broken links — битые ссылки

---

## Guardrails & Безопасность

### Protected Zones

| Зона | Правило | Почему защищена |
|------|---------|-----------------|
| `raw/**` | ⛔ Только чтение | Источник правды, immutable |
| `meta/**` | ⛔ Автогенерация | registry.json, backlinks.json — не трогаем вручную |

### Validation flow

1. **validate-path.sh** — вызывается ДО любого `edit`/`write` на защищённых зонах
   - Проверяет путь → если попадает в `raw/**` или `meta/**` → exit 1 (блокировка)
2. **pre-commit hook** — финальный контроль при git commit
   - Сканирует staged-файлы → если есть изменения в protected zones → reject

### Error Handling Protocol

При обнаружении ошибки, противоречия или dead end:

1. **Detect & Log** `[!]` → записать в `log.md` с типом и контекстом
2. **Analyze** → краткий анализ корня проблемы
3. **Resolve** → выбрать стратегию:
   - `local-fix`: проблема локальная → исправить самостоятельно
   - `schema-patch`: противоречие в Schema → предложить патч пользователю
   - `source-conflict`: два источника говорят противоположное → отметить как CONFLICT
   - `dead-end`: подход не работает → документировать, сменить стратегию
4. **Continue** → двигаться дальше, не застревая

---

## Memory Architecture

### Context Bridge (`working_memory.json`)

Файл-мост между сессиями — сохраняет фокус, open_pages, dead_ends, next_steps_todo.

**Clear & Rewrite Rule:** Never append to JSON files. Always read the entire file → modify in memory → write back the complete document. Это предотвращает дубликаты ключей.

### Context Bubble

- **Ограничение:** не более 3 активных страниц в контексте одновременно
- При превышении: dismiss наименее важную страницу из контекста
- Отслеживание статусов: `reading`, `updating`, `read`

---

## Schema Co-evolution

AGENTS.md — живая схема, которая **co-evolves** между человеком и LLM по мере роста wiki. Новые правила добавляются через диалог, каждый rule получает ID для traceability (например, `DR-1`, `DR-2`).

---

## Git Conventions

- **Commit format:** `<type> | <scope>: <description>`
  - type: `ingest`/`query`/`lint`/`schema`/`fix`
  - description: lowercase, краткое описание
- **Allowed:** `git status --short`, `git add wiki/`, `git rm --cached`
- **Prohibited:** `git add *` (system junk), `git commit -a`

---

## Текущее состояние

**Итог:** ~36 страниц по трём темам:
1. LLM Wiki Pattern / Pi Coding Agent
2. Python на NixOS
3. Symfony

**Структура:**
- 5 entity pages (AI Factory, Andrej Karpathy, Nvidia, Pi Coding Agent, Symfony)
- ~18 concept pages
- 2 synthesis pages
- 2 comparison pages

**Работает:** ingest, query, lint, Error Handling Protocol. Guardrails валидируют пути.

---

## Roadmap

### ✅ Реализовано

| Компонент | Статус |
|-----------|--------|
| `working_memory.json` — Context Bridge | ✅ |
| CONTEXT_BUBBLE + Delta-Scoping | ✅ |
| Grep-контракт (разрешённые/запрещённые паттерны) | ✅ |
| Error Handling Protocol (4-step loop) | ✅ |

### 🔜 В очереди

* [ ] Bash-скрипт поиска (FTS5 или ripgrep) вместо чтения index.md целиком
* [ ] Автоматизировать lint через cron/bash — агент получает готовый отчёт
* [ ] Перейти на MCP-сервер при росте wiki (>100 страниц)
* [ ] Оптимизация Schema: AGENTS.md растёт, нужна модулизация

---

## Связи

| Страница | Описание |
|----------|----------|
| [LLM Wiki Pattern](concepts/llm-wiki.md) | Основная концепция compounding knowledge base |
| [RAG vs LLM Wiki Pattern](syntheses/rag-vs-llm-wiki-pattern.md) | Сравнение с традиционными подходами |
| [Loomana vs pi-llm-wiki](comparisons/llm-wiki-implementations.md) | Сравнение реализаций |
| [Andrej Karpathy](entities/andrej-karpathy.md) | Автор идеи LLM Wiki Pattern |

---

*Created: 2026-06-28 — первая версия статьи о самой wiki*