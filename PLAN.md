# PLAN: Унификация скриптов link validation + Schema cleanup

## ✅ Статус: ЗАКРЫТО (all phases complete)

Все задачи выполнены, все вопросы закрыты. Этот документ сохранён как история решений и архитектурные конвенции.

---

## 📋 Исходная задача (исторический контекст)

Сейчас в wiki было **три** связанных, но дублирующих друг друга скрипта для работы с внутренними ссылками wiki:

| Скрипт | Назначение | Проблема |
|--------|-----------|----------|
| `scripts/broken-links.sh` | Полное сканирование всех wiki-файлов на сломанные внутренние ссылки `[text](path)` | Выводил список, но не предлагал auto-fix логически. Agent должен сам делать sed-редактирование по каждому файлу. |
| `scripts/post-op-link-scan.sh` | Сканировал wiki на упоминания конкретного паттерна (old_path / имя страницы). Помечал links как auto-fixable через regex. | Дублировал логику поиска broken links, но с входным параметром. Не делал sed автоматически — только помечал. |
| `scripts/validate-path.sh` | Guardrails: блокировка записи в protected zones (meta/, raw/) | **Не связан** с link validation — отдельный guardrail для protected zones. Трогать не нужно. |

Также правила из AGENTS.md `Post-Operation Link Validation` описывали протокол в JSON, но ни один скрипт не реализовал этот протокол полностью. Вызовы были размазаны по `process-ingest.json` и `process-lint.json`.

## 🎯 Цель (выполнено)

Создан **единый** универсальный скрипт `scripts/link-validator.sh`, который:
1. ✅ Работает в двух режимах: `--full` (полная проверка всех wiki) и `<pattern>` (сканирование на упоминания паттерна).
2. ✅ Выводит machine-readable результат для каждого broken link: файл, строка, старый путь, новый путь.
3. ✅ Интегрируется с Auto-Fix Protocol из AGENTS.md.
4. ✅ Заменил оба существующих скрипта (`broken-links.sh`, `post-op-link-scan.sh`).

## 📊 Решение (Phase 1: Script creation & integration)

Создан единый `scripts/link-validator.sh` с двумя режимами:

```bash
# Полная проверка всех wiki на сломанные ссылки
./scripts/link-validator.sh --full [wiki_dir] [--max N]

# Сканирование на упоминания конкретного паттерна (old_path / имя)
./scripts/link-validator.sh <pattern> [wiki_dir] [max_matches]
```

**Выходные данные:**
- Exit 0 = all valid / no references found.
- Exit 1 = broken links found.
- **Stdout: JSON array** — LLM парсит JSON надёжнее, типизированные поля не ломаются на escape-символах в путях.
  ```json
  [
    {"file": "wiki/entities/foo.md", "line": 42, "link": "[text](old/path.md)", "target_path": "old/path.md"},
    ...
  ]
  ```
- **Stderr: человеко-читаемый лог** — как сейчас (с `[✓]`, `[!]` префиксами).

**Логика:**
1. `--full`: find all *.md → grep для `[text](path)` → parse target path → проверить существование целевого файла.
2. `<pattern>`: grep -rn "$pattern" wiki/ → извлечь markdown-ссылку → проверить, существует ли целевой файл.

## ✅ Фактические изменения (Phase 2 + Phase 3)

### Process-файлы обновлены

**process-lint.json:**
- check_id=7: `broken-links.sh` → `link-validator.sh --full`
- check_id8 rename_or_move: `post-op-link-scan.sh` → `link-validator.sh "${OLD_PATH}"`
- check_id=8 delete_detected: `post-op-link-scan.sh` → `link-validator.sh "${DELETED_FILE}"`

**process-ingest.json:**
- step 3a post_operations: `post-op-link-scan.sh ${OLD_ORIGINAL_NAME} 50` → `link-validator.sh "${NEW_ENTITY_CONCEPT_NAME}" --max 50`
- step 3b post_operations: `post-op-link-scan.sh ${NEW_CONCEPT_OR_ENTITY} 50` → `link-validator.sh "${NEW_CONCEPT_OR_ENTITY}" --max 50`

**AGENTS.md:**
- ✅ Секция `Post-Operation Link Validation` обновлена: grep заменён на вызов скрипта, добавлен парсинг JSON из stdout.
- ✅ Добавлена ссылка на `process-ingest.json#post_operation_link_validation`.
- ✅ Убраны все упоминания `broken-links.sh` и `post-op-link-scan.sh`. Оставлен только `### Link Format Standards`.

**Старые скрипты удалены:**
```bash
rm scripts/broken-links.sh scripts/post-op-link-scan.sh
```

## ✅ Working Memory Schema: inline в AGENTS.md (коммит e88f316)

- ❌ `mem.md` удалён — это был временный файл разработки.
- ✅ Формат `working_memory.json` перенесён inline в AGENTS.md (раздел Context Bridge).
- ✅ README.md очищен от ссылок на mem.md.
- ✅ Ни один process-файл не ссылается на mem.md — все инструкции по working_memory.json в process-query.json.

## 📝 Закрытые вопросы

### 1. Формат вывода JSON ✅ ЗАКРЫТО
Решение: stdout = `[ {file, line, link, target_path} ]`, stderr = человеко-читаемый лог. LLM парсит JSON надёжнее — типизированные поля, escape-символы в путях не ломают разделители.

### 2. Max_matches default ✅ ЗАКРЫТО
Скрипт ставит default = **100**. Инструкции ingest явно задают `--max 50` — при создании/обновлении страницы достаточно просканировать до 50 упоминаний в одной категории wiki. Lint-проверки (полный скан, rename/move) используют дефолт 100. Env var не нужен — значения фиксируются в скрипте и явно задаются инструкциями.

### 3. Auto-fix логика ✅ ЗАКРЫТО
`link-validator.sh` выводит JSON из stdout. Agent парсит JSON → применяет auto-fix. AGENTS.md Auto-Fix Protocol: "rewrite_to_wiki_relative" / "create page or remove link". Скрипт не генерирует sed-команды — agent сам делает edit по JSON выходу (через `edit` или `bash`).

### 4. validate-path.sh ✅ ЗАКРЫТО
Оставлен отдельно как guardrail для protected zones (meta/, raw/). Не связан с link validation, разные зоны ответственности.

---

## 📏 Критерии успеха (все выполнены)

- [x] Единый `link-validator.sh` создан и работает в обоих режимах (`--full`, `<pattern>`).
- [x] Все вызовы `broken-links.sh` заменены на `link-validator.sh --full`.
- [x] Все вызовы `post-op-link-scan.sh` заменены на `link-validator.sh <pattern> [--max N]`.
- [x] AGENTS.md обновлён: Post-Operation Link Validation перенесено в process-*.json, старые названия скриптов убраны.
- [x] Старые скрипты удалены (broken-links.sh, post-op-link-scan.sh).
- [x] Git diff показывает: только изменения process-*.json и AGENTS.md + замена 2 файлов на 1.
- [x] mem.md удалён, working_memory формат инлайнен в AGENTS.md.

---

*Создано: 2026-06-25*
*Статус: ✅ Closed — all phases complete.*
*Финальный коммит: e88f316 "schema | remove mem.md references, inline working_memory format in AGENTS.md"*
