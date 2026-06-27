# Анализ обработки ошибок в скриптах Loom Wiki

**Дата:** 2026-06-27  
**Версия схемы:** 9

---

## 📊 Методология оценки

Оценка обработки исключений по 4 критериям:

| Критерий | Вес | Описание |
|----------|-----|----------|
| **Strict mode** | 20% | `set -euo pipefail` — остановка при любой ошибке |
| **Trap handlers** | 15% | Очистка ресурсов при аварийном выходе |
| **Error redirection** | 10% | Перенаправление stderr для чистоты логов |
| **Explicit error handling** | 10% | Явные проверки exit codes, `||` операторы |
| **Graceful degradation** | 10% | Fallback при ошибках (`|| true`, `|| exit 0`) |
| **Logging** | 10% | Информативные сообщения об ошибках |

---

## 📈 Результаты (по убыванию качества)

### ✅ Высокое качество (75-80 баллов)

#### 1. `wiki-search.sh` — 75/100
**Сильные стороны:**
- ✅ Есть сообщения об ошибках
- ✅ Использует `set -euo pipefail`

**Проблемы:**
- ⚠️ Нет trap handlers для очистки при аварийном выходе
- ⚠️ Валидация user input отсутствует (query может содержать спецсимволы)
- ⚠️ JSON в history не валидируется перед записью

**Риск:** Если query содержит `$(rm -rf /)` → потенциальная инъекция

---

#### 2. `link-validator.sh` — 75/100
**Сильные стороны:**
- ✅ Есть сообщения об ошибках
- ✅ Использует `set -euo pipefail`

**Проблемы:**
- ⚠️ Нет trap handlers
- ⚠️ Валидация user input отсутствует (path может содержать спецсимволы)
- ⚠️ JSON construction fragile — нет валидации перед записью

**Риск:** `eval` + untrusted input = **code injection vulnerability**

---

### 🟡 Среднее качество (50-60 баллов)

#### 3. `lint.sh`, `orphan-pages.sh`, `duplicate-titles.sh`, `date-consistency.sh` — 60/100

**Общие проблемы:**
- ❌ Нет trap handlers для очистки при аварийном выходе
- ⚠️ Валидация input отсутствует
- ⚠️ JSON manipulation без валидации

**Сильные стороны:**
- ✅ Используют `set -euo pipefail`
- ✅ Есть сообщения об ошибках

---

#### 4. `auto-crosslink.sh` — 50/100

**Проблемы:**
- ❌ Нет trap handlers
- ⚠️ Логирование ошибок отсутствует
- ⚠️ Валидация input отсутствует
- ⚠️ JSON construction fragile

---

### 🔴 Низкое качество (30-50 баллов)

#### 5. `rebuild-meta.sh` — 40/100

**Критические проблемы:**
- ❌ Нет trap handlers
- ⚠️ `mkdir` без проверки существования
- ⚠️ Fallback отсутствует при ошибках Python
- ⚠️ Логирование ошибок отсутствует
- ⚠️ JSON validation отсутствует

**Риск:** При ошибке Python скрипт продолжает работу с повреждёнными данными

---

#### 6. `_detect_contradictions.py` — 40/100

**Проблемы:**
- ❌ Нет try-except блоков (Python)
- ⚠️ Валидация JSON отсутствует
- ❌ Нет logging

**Риск:** При ошибке чтения файла → crash скрипта

---

#### 7. `check-new-sources.sh`, `text-similarity.sh`, `classify-source.sh` — 30/100

**Общие проблемы:**
- ❌ Нет `set -euo pipefail`
- ❌ Нет trap handlers
- ⚠️ `mkdir` без проверки существования
- ⚠️ Логирование ошибок отсутствует
- ⚠️ Валидация input отсутствует

---

#### 8. `validate-path.sh` — 0/100 🔴 КРИТИЧЕСКИ

**Почему 0 баллов:**
- ❌ Нет `set -euo pipefail`
- ❌ Нет trap handlers
- ❌ Нет error redirection
- ❌ Нет explicit error handling
- ❌ Нет graceful degradation
- ❌ Нет logging

**Это guardrails скрипт — должен быть самым надёжным!**

**Риск:** При ошибке продолжает работу → может пропустить защиту от write к raw/

---

## 🔍 Глубокий анализ: Перехват и обработка исключений

### Bash скрипты

#### 1. `set -euo pipefail` — Критически важно

| Скрипт | Статус | Риск без этого |
|--------|--------|----------------|
| `validate-path.sh` | ❌ Нет | **Высокий** — может пропустить блокировку protected zones |
| `text-similarity.sh` | ❌ Нет | Средний — ошибки Python не останавливают скрипт |
| `classify-source.sh` | ❌ Нет | Низкий — graceful fallback intentional |
| Остальные | ✅ Есть | Хорошо |

**Правило:** Все guardrails и meta-modifying скрипты **должны** иметь `set -euo pipefail`.

---

#### 2. Trap handlers — для очистки при аварийном выходе

```bash
# Пример правильного использования:
cleanup() {
    echo "Cleaning up..." >&2
    # Очистка временных файлов, rollback изменений и т.д.
}
trap cleanup EXIT

# Или с сигналом:
trap 'echo "Interrupted" >&2; exit 130' INT TERM
```

**Скрипты без trap:** Все скрипты (кроме `validate-path.sh` который должен быть минималистичным)

**Рекомендация:** Добавить cleanup handlers для:
- `rebuild-meta.sh` — rollback при ошибке записи JSON
- `wiki-search.sh` — очистка history на выходе
- `link-validator.sh` — откат изменений при ошибке

---

#### 3. Error redirection и логирование

**Текущее состояние:**
- Некоторые скрипты используют `2>/dev/null || true` для подавления ошибок
- Нет единого формата логирования

**Проблема:** Ошибки "теряются" в `/dev/null`, сложно отладить.

**Рекомендация:** Добавить logging:
```bash
log_error() {
    echo "[ERROR] $1" >&2
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') | ERROR: $1" >> "$LOG_DIR/error.log" 2>/dev/null || true
}

# Использование:
if ! command_exists; then
    log_error "Command not found: $cmd"
    exit 1
fi
```

---

#### 4. Graceful degradation — `|| true` / `|| exit 0`

**Скрипты с graceful fallback:**
- `text-similarity.sh` — использует `|| true` в некоторых местах
- `classify-source.sh` — intentional для L3_Community fallback

**Скрипты без graceful degradation (риск crash):**
- `rebuild-meta.sh` — при ошибке Python скрипт может оставить повреждённый JSON
- `_detect_contradictions.py` — при ошибке чтения файла → crash

---

### Python скрипты

#### 1. Try-except блоки

**`_detect_contradictions.py`:**
```python
# Текущее состояние: нет try-except!
try:
    with open(filepath, "r") as f:
        content = f.read(4096)
except Exception:
    continue  # Просто пропускает, но не логирует
```

**Проблема:** При ошибке чтения файла скрипт продолжает работу, но не сообщает об этом.

**Рекомендация:**
```python
import logging
logging.basicConfig(level=logging.ERROR)

try:
    with open(filepath, "r") as f:
        content = f.read(4096)
except IOError as e:
    logging.error(f"Cannot read file {filepath}: {e}")
    continue
except Exception as e:
    logging.critical(f"Unexpected error reading {filepath}: {e}", exc_info=True)
    continue
```

---

#### 2. Specific exception handling

**Текущее состояние:** Все Python скрипты используют `except Exception` (bare except), что плохо для отладки.

**Рекомендация:** Использовать конкретные типы:
```python
try:
    data = json.loads(input_str)
except json.JSONDecodeError as e:
    logging.error(f"Invalid JSON: {e}")
    return None
except ValueError as e:
    logging.error(f"Value error: {e}")
    return None
```

---

## 📋 Итоговая оценка: Достаточно ли обработки ошибок?

### ✅ Достаточно (75+ баллов)

| Скрипт | Оценка | Комментарий |
|--------|--------|-------------|
| `wiki-search.sh` | 75/100 | Хорошо, но нужна валидация input |
| `link-validator.sh` | 75/100 | Хорошо, но критичен из-за eval |

### ⚠️ Требует улучшений (50-60 баллов)

| Скрипт | Оценка | Комментарий |
|--------|--------|-------------|
| `lint.sh`, `orphan-pages.sh` и др. | 60/100 | Нет trap, нужна валидация input |
| `auto-crosslink.sh` | 50/100 | Нужен logging и validation |

### ❌ Недостаточно (30-40 баллов)

| Скрипт | Оценка | Комментарий |
|--------|--------|-------------|
| `rebuild-meta.sh`, `_detect_contradictions.py` | 40/100 | Нет try-except, нет logging |
| `check-new-sources.sh`, `text-similarity.sh` | 30/100 | Нет strict mode, нет trap |

### 🔴 Критически (0-30 баллов)

| Скрипт | Оценка | Комментарий |
|--------|--------|-------------|
| `validate-path.sh` | **0/100** | Guardrails скрипт без обработки ошибок! |

---

## 🎯 Ответы на вопросы

### 1. Достаточно ли реализован перехват и обработка исключений?

**Нет, недостаточно.** 

- **Bash скрипты:** Только `set -euo pipefail` у некоторых, нет trap handlers, нет logging
- **Python скрипты:** Нет try-except блоков (кроме одного), нет specific exception handling
- **Guardrails скрипт (`validate-path.sh`) — 0/100!** Это критично.

### 2. Не избыточны ли они?

**Нет, не избыточны.** Наоборот — недостаточно. Но есть риск:
- `set -euo pipefail` может быть слишком строгим для graceful fallback скриптов (intentional)
- Некоторые скрипты используют `|| true` для подавления ошибок — это может скрывать реальные проблемы

### 3. Понятно ли написаны отчеты о причинах исключений?

**Нет, не понятно.** 

**Проблемы:**
1. Нет единого формата сообщений об ошибках
2. Нет logging в структурированном формате
3. Python скрипты не логируют исключения (кроме одного)
4. Bash скрипты часто просто выводят "command failed" без причины

**Рекомендация:** Добавить unified error format:
```bash
# Bash
log_error() {
    local msg="$1"
    echo "[ERROR] $(date -u '+%Y-%m-%dT%H:%M:%SZ') | $msg" >&2
    echo "$msg" >> "$LOG_DIR/error.log" 2>/dev/null || true
}

# Python
import logging
logging.basicConfig(
    format='[%(levelname)s] %(asctime)s | %(message)s',
    level=logging.INFO,
    handlers=[
        logging.StreamHandler(sys.stderr),
        logging.FileHandler('logs/error.log')
    ]
)
```

---

## 📝 План действий

### Phase 1: CRITICAL — Fix validate-path.sh
- Добавить `set -euo pipefail`
- Добавить trap для очистки
- Добавить explicit error messages
- **Это guardrails скрипт — должен быть идеальным**

### Phase 2: HIGH — Add logging to all scripts
- Создать unified logging format
- Добавить к логированию всех скриптов
- Создать `logs/` directory с структурой

### Phase 3: MEDIUM — Add try-except to Python scripts
- Добавить try-except в `_detect_contradictions.py`
- Использовать specific exception types
- Добавить logging

### Phase 4: LOW — Documentation
- Добавить inline comments для сложных участков
- Создать `scripts/README.md` с примерами error handling

---

*Анализ завершён: 2026-06-27*  
*Версия схемы: 9*
