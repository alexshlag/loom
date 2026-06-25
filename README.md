# LLM Wiki — Compounding Knowledge Base

## Что это такое

Это **LLM-powered personal knowledge base** — база знаний, которая растёт с каждым источником и вопросом. Вместо стандартного RAG (где LLM каждый раз заново извлекает фрагменты документов), здесь знания **компилируются один раз** и **поддерживаются актуальными**.

*Идея: [Andrej Karpathy](https://karpathy.ai/). Референс: [LLM Wiki gist](https://gist.github.com/karpathy/ed8f284379605148297b7a8be01eb580).*

### LLM Wiki vs RAG

| | RAG / NotebookLM | LLM Wiki Pattern |
|--|------------------|------------------|
| Знания каждый запрос | 🔴 Rediscover from scratch | 🟢 Compounding (растёт) |
| Cross-references | ❌ Нет | ✅ Явные ссылки |
| Contradictions | ❌ Не ловит | ✅ Flagging при каждом ingest |
| Сложные вопросы | 5+ документов каждый раз | Wiki уже синтезировала ответы |

**Когда использовать:** долгосрочный research, deep-dive за недели/месяцы, team internal wiki.
**Когда не нужен:** ad-hoc queries, one-shot analysis, когда есть готовая база.

---

## Архитектура: три слоя

```
raw/**          ← Immutable sources (не трогаем)
  └── sources/  ← Загруженные статьи, документы
  └── github/   ← Forked repos с исходниками

wiki/**         ← Markdown pages (LLM пишет)
  ├── entities/     ← Конкретные объекты: люди, компании, технологии
  ├── concepts/     ← Абстрактные идеи, принципы
  ├── syntheses/    ← Глубокий анализ, объединяющий источники
  ├── comparisons/  ← Сравнительный анализ
  ├── overview.md   → Текущая картина знаний
  └── log.md      → Хронологический журнал действий

scripts/        ← Guardrails (валидация путей, rebuild meta)
AGENTS.md       → Schema: конвенции, форматы страниц, workflows
```

### Почему так?

* **Raw** — immutable. LLM не пишет туда напрямую, только через capture flow.
* **Wiki** — LLM владеет полностью. Создаёт страницы, обновляет их, поддерживает cross-references.
* **AGENTS.md** — живая схема, co-evolves между человеком и LLM.

---

## Три рабочих процесса

### Ingest — добавление источника

1. Пользователь предоставляет источник (URL, файл, текст)
2. Агент создаёт пакет в `raw/sources/SRC-YYYY-MM-DD-NNN/`
3. Читает, обсуждает ключевые тезисы с пользователем
4. Пишет summary → wiki, обновляет index.md и entity/concept страницы
5. Записывает entry в log.md

### Query — ответ на вопрос

1. Агент читает `index.md` по релевантным категориям
2. Семантический поиск (wiki_recall) или grep-fallback
3. Читает найденные страницы, синтезирует ответ с фактами и ссылками
4. Если ответ содержит novel insight → предлагает сохранить как новую страницу wiki

### Lint — поддержание здоровья базы

1. Периодическая проверка: противоречия, orphan-страницы, broken links
2. Agent получает готовый сухой остаток — не читает всё подряд
3. Resolution flow (fixing contradictions) — зона ingest/query

---

## Как начать

### Шаг 1: Развернуть wiki из INIT.md

Весь проект — это один файл `INIT.md`, который содержит:
* Все инструкции (AGENTS.md, process-ingest.md, process-query.md, process-lint.md)
* Скрипты guardrails в base64-формате (`validate-path.sh`, `.git/hooks/pre-commit`)
* Чек-листы и bash-команды для создания структуры каталогов

Для установки просто попросите ии-агента выполнить инструкции `INIT.md`

Проверьте, что создан файл `.git/hooks/pre-commit` следующего содержания:

```bash
#!/bin/bash
# .git/hooks/pre-commit — Guardrails финальный контроль
# Блокирует commit, если staged-файлы попадают в protected zones (raw/**, meta/**)

PROTECTED_PATTERNS=("raw/" "meta/")
STAGED_FILES=$(git diff --cached --name-only)

for PATTERN in "${PROTECTED_PATTERNS[@]}"; do
  if echo "$STAGED_FILES" | grep -q "^$PATTERN"; then
    echo "⛔ BLOCKED: staged files detected in protected zone '$PATTERN'" >&2
    echo "Protected zones: raw/**, meta/** — these must never be edited directly." >&2
    exit 1
  fi
done

# All clear
exit 0
```

Он дополнительно будет защищать ваши raw-файлы от повреждения ии-агентами

После инициализации wiki готова для использования.

### Шаг 2: Добавить материал в wiki

**Три способа, как пользователь даёт агенту информацию:**

1. **Ссылка на интернет-ресурс** — `https://example.com/article`, `https://docs.example.com/...`
2. **Локальный файл** — `.pdf`, `.md`, `.txt` — в любом виде
3. **Текст напрямую** — копипаст, транскрипт встречи, заметки

Агент сам:
* Загружает и парсит источник
* Сохраняет в `raw/sources/` через capture flow
* Классифицирует: entity / concept / notes
* Пишет summary → wiki, обновляет index.md
* Связывает с существующими страницами

Всё по инструкциям из `process-ingest.json`. Пользователю не нужно ничего делать руками.

### Шаг 3: Задавать вопросы и искать информацию

**Пользователь задаёт вопрос — агент ищет в wiki.**

Агент сам:
* Ищет по index.md → semantic search → grep-fallback
* Читает найденные страницы
* Синтезирует ответ с фактами, ссылками, цитатами
* Обнаруживает противоречия → разрешает по приоритету (authoritative > temporal > user_review)
* Если ответ содержит novel insight — предлагает сохранить как новую страницу wiki

Всё по инструкциям из `process-query.json`.

### Шаг 4: Периодическая проверка здоровья

Агент сам запускает **lint-проверки** при:
* Замеченной стагнации (не было новых страниц несколько дней)
* Накоплении противоречий
* Появлении orphan-страниц

Находит проблемы → предлагает решения → user review.

Всё по инструкциям из `process-lint.json`.

---

## Wiki максимально самостоятельна

Пользователь **даёт материал** (ссылка, файл, текст) или **задаёт вопрос**. Агент делает всё остальное: классифицирует, пишет страницы, поддерживает связи, обновляет index.md, ловит противоречия. База знаний растёт сама.

---

## Автоматическое обслуживание wiki

* **Хранение, git-commit** — агент делает всё автоматически. По запросу пользователя — branch для экспериментов с структурой.
* **Guardrails (validate-path.sh)** — защита `raw/**` и `meta/**`. Agent сам вызывает перед любой write.
* **Schema co-evolution** — AGENTS.md обновляется совместно с пользователем по мере роста wiki.

* **Git commit** после каждого значимого действия (ingest, query с новой страницей, lint-fix)
* **Сообщения:** `[действие] [краткое описание]` — `ingress | added entity pi-coding-agent`, `query | synthesis on RAG vs databases`, `lint | fixed orphan pages`
* **Branch для экспериментов** со структурой → согласовать с пользователем → merge.

---

## Текущее состояние wiki (как пример)

| Категория | Страниц |
|-----------|---------|
| Сущности | Pi Coding Agent, Andrej Karpathy, AI Factory, Nvidia |
| Концепты | LLM Wiki Pattern, AI Factory vs Pi, Python на NixOS |
| Синтезы | RAG vs LLM Wiki Pattern, Python Dev Environments |
| Schema | AGENTS.md (v4), process-ingest.json, process-query.json, process-lint.json |

**Итог:** 14 страниц по трём темам. Работает ingest, query, lint. Guardrails валидируют пути. Schema co-evolves.

---

## Дальнейшие шаги (Roadmap)

### Управление контекстом и памятью агента

Ключевая проблема: LLM-агент с ограниченным контекстным окном (особенно локальные модели). Без управления памятью — токенольное выгорание при росте wiki. Мы обсудили эту проблему в [mem.md](../mem.md) — вот что планируем:

* **`working_memory.json`** — мост между сессиями. Агент читает при старте, перезаписывает при завершении.
* **CONTEXT_BUBBLE + Delta-Scoping** — не более 3 активных страниц в контексте одновременно. Чтение через графовое соседство (1-й круг wikilinks).
* **Grep-контракт в JSON-инструкциях** — запрет на `cat` крупных файлов, обязательный `-m` для grep.
* **Скриптовая автоматизация** — lint, backlinks-checks, orphan-detection — bash/python задачи. Агент получает готовый сухой остаток.

### Остальные шаги

* [ ] Настроить `working_memory.json` и внедрить CONTEXT_BUBBLE в JSON-инструкции ролей
* [ ] Добавить bash-скрипт поиска (FTS5) вместо чтения index.md целиком
* [ ] Автоматизировать lint через cron/bash — агент получает готовый отчёт
* [ ] Перейти на MCP-сервер при росте wiki (>100 страниц)

---

## Связи

* [AGENTS.md](AGENTS.md) — полная schema и конвенции
* [wiki/overview.md](wiki/overview.md) — текущая картина знаний
* [wiki/log.md](wiki/log.md) — журнал всех действий
* [mem.md](mem.md) — руководство по управлению контекстом и памятью агента (проект)
