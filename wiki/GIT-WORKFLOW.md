# Git Workflow for Loomana Wiki

## 📋 Overview

Этот документ описывает правильные практики работы с git для проекта Loomana.

---

## 🔖 Commit Format

**Format**: `<type> | <scope>: <description>`

| Type | Когда использовать | Пример |
|------|-------------------|--------|
| `ingest` | Добавление/обновление wiki-страницы из источника | `ingest | added entity symfony with 14 concept pages` |
| `query` | Ответ на вопрос пользователя, создание synthesis | `query | synthesis on RAG vs LLM Wiki Pattern` |
| `lint` | Исправление проблем, обнаруженных lint-проверкой | `lint | fixed orphan pages and broken links` |
| `schema` | Изменения в AGENTS.md, process-файлах, схемах | `schema | updated compounding_decision logic` |
| `fix` | Исправление багов, критических ошибок | `fix | resolved memory leak in text-similarity.sh` |

**Description rules**:
- Lowercase, краткое описание
- Без заглавных букв в начале предложений
- Максимум 50 слов

---

## ✅ Allowed Operations

```bash
# Проверка статуса
git status --short

# Добавление файлов (только из разрешённых зон)
git add wiki/
git add scripts/*.sh
git add AGENTS.md
git add process-*.json
git add README.md

# Удаление из индекса
git rm --cached <file>

# ⚠️ Принудительное добавление — используйте ТОЛЬКО с разрешения пользователя
# Это может нарушить правила проекта (protected zones)
git add -f <file>
```

---

## ❌ Prohibited Operations

```bash
# ЗАПРЕЩЕНО:
git add *              # Добавляет системные файлы
git commit -a         # Нет staged commits — всегда проверяй перед коммитом
git commit --amend    # Не переписывай историю без причины
git reset --hard      # Не сбрасывай рабочую область без разрешения
git clean             # Не удаляй неслеженные файлы
```

---

## 🛡 Protected Zones & .gitignore

| Зона | Статус | Почему |
|------|--------|--------|
| `raw/**` | ⛔ Игнорируется | Immutable sources — никогда не коммитить оригиналы |
| `meta/**` | ⛔ Игнорируется | Автогенерируемые файлы (registry.json, backlinks.json) |
| `.obsidian/` | ⛔ Игнорируется | Локальные настройки Obsidian |
| `tracking/similarity_cache.json` | ⚠️ Игнорируется | Большой кэш (100KB+), регенерируется автоматически |

**Важно**: Если нужно коммитить изменения в защищённые зоны — сначала получи разрешение пользователя.

---

## 🔄 Workflow Before Commit

1. **Проверь статус**: `git status --short`
2. **Добавь изменения**: `git add <files>` (указывай конкретные файлы)
3. **Создай коммит** с правильным типом:
   ```bash
   git commit -m "type | scope: description"
   ```
4. **Если есть ошибки** — сначала исправь, затем коммить.

---

## 🚨 Error Handling

| Ситуация | Решение |
|----------|---------|
| `fatal: path is ignored` | Файл в .gitignore — проверь, нужно ли его коммитить |
| `error: commit message is empty` | Всегда указывай сообщение для коммита |
| `pre-commit hook failed` | Проверь `.git/hooks/pre-commit` — блокирует изменения в protected zones |

---

## 🌿 Branching Strategy

- **Main branch**: всегда стабильная, с рабочей wiki
- **Temporary branches**: для экспериментов со структурой (согласовывать с пользователем)
- **Tagging**: `v0.1`, `v0.2` при достижении значимых вех (например, 50+ страниц)

---

## 📊 Post-Commit Verification

После коммита проверь:
```bash
git log -1 --stat      # Проверка добавленных файлов
git status             # Должно быть чисто
diff --cached          # Просмотр изменений перед пушем (если нужно)
```

---

## 📝 Example Commits

```bash
# Правильно:
git commit -m "ingest | added entity symfony with 14 concept pages"
git commit -m "query | synthesis on RAG vs LLM Wiki Pattern"
git commit -m "lint | fixed orphan pages and broken links"
git commit -m "schema | updated compounding_decision logic"

# Неправильно:
git commit -m "Added symfony entity"           # Нет типа
git commit -m "FIXED BUG"                      # Заглавные буквы
git commit                                    # Пустое сообщение
```
