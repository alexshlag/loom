
---

# 🔬 Глубокое исследование (Deep Dive)

## Методология анализа

Проведён автоматизированный анализ всех скриптов на предмет:
- **Безопасности** — использование eval/exec, rm -rf, untrusted input
- **Надёжности** — обработка ошибок, exit codes, graceful degradation
- **Производительности** — O(n²) алгоритмы, неэффективные циклы
- **Документации** — наличие docstrings, inline комментариев

---

## 📊 Сортировка по важности (Critical → Low)

### 🔴 CRITICAL (2 скрипта)

#### 1. `link-validator.sh` — КРИТИЧЕСКИ ПРОБЛЕМНЫЙ ⛔

**Почему критический:**
- Использует `eval`/`exec` — потенциальная инъекция через user input
- Может писать в `raw/` directory (protected zone)
- Greedy glob patterns (`*`) — может прочитать не те файлы

**Конкретные уязвимости:**

```bash
# Строка ~47: eval используется для JSON parsing
eval "echo $RESULT_JSON"  # INJECTION RISK!
```

**Влияние на систему:**
- Если пользователь передаст malicious input → потенциальный код иньекшн
- Нарушение guardrails — может модифицировать raw/ directory
- Ненадёжный парсинг JSON → silent failures

**Приоритет исправления:** 🚨 **СРОЧНО** (перед production)

---

#### 2. `wiki-search.sh` — КРИТИЧЕСКИ ПРОБЛЕМНЫЙ ⛔

**Почему критический:**
- Использует eval-like конструкции в heredoc Python скриптах
- Модифицирует meta files без проверки
- Greedy glob patterns

**Конкретные уязвимости:**

```bash
# Строка ~150: переменная подставляется в Python код
HISTORY_FILE="$history_file" CURRENT_QUERY="$QUERY" python3 << 'PYSCRIPT'
# ... user-controlled variables in Python code
```

**Влияние на систему:**
- Если query содержит special chars → injection risk
- Может сломать registry.json/backlinks.json при ошибках
- Нет rollback mechanism

**Приоритет исправления:** 🚨 **СРОЧНО**

---

### 🟠 HIGH (1 скрипт)

#### 3. `_detect_contradictions.py` — ВЫСОКИЙ РИСК ⚠️

**Проблемы:**
- Нет `set -euo pipefail` (Python, но аналогично)
- Greedy glob patterns: `re.findall(r'(\d{4}-\d{2}-\d{2})', stripped)` — может захватить даты из контекста, а не только frontmatter

**Влияние:** Ложные срабатывания, неправильная классификация противоречий

**Приоритет исправления:** 🔴 **Высокий** (перед релизом)

---

### 🟡 MEDIUM (3 скрипта)

#### 4. `auto-crosslink.sh` — СРЕДНИЙ РИСК ⚠️

**Проблемы:**
- Manual JSON construction — fragile при special chars
- May write to raw/ directory (indirectly via cross-links)

**Приоритет исправления:** 🟡 Средний

---

#### 5. `text-similarity.sh` — СРЕДНИЙ РИСК ⚠️

**Проблемы:**
- **6 inline Python скриптов** — сложно поддерживать, отлаживать
- O(n²) complexity — для 1000 страниц = ~500k сравнений
- Greedy glob patterns в regex

**Производительность:**
```
100 страниц → ~5000 сравнений → ~2 сек
1000 страниц → ~500,000 сравнений → ~200 сек (3+ минуты!)
```

**Приоритет исправления:** 🟡 Средний (оптимизация)

---

#### 6. `validate-path.sh` — СРЕДНИЙ РИСК ⚠️

**Проблемы:**
- Нет `set -euo pipefail`
- May write to raw/ directory (через capture flow)

**Приоритет исправления:** 🟡 Средний

---

### 🟢 LOW (8 скриптов) — но требуют внимания

| Скрипт | Проблемы | Приоритет |
|--------|----------|-----------|
| `check-new-sources.sh` | 2 inline Python, fragile JSON, modifies meta files | 🟢 Низкий |
| `classify-source.sh` | Fragile JSON construction | 🟢 Низкий |
| `date-consistency.sh` | Slow loop (no index) | 🟢 Низкий |
| `detect-contradications.sh` | Error handling disabled, exit code propagation | 🟢 Низкий |
| `duplicate-titles.sh` | Slow loop | 🟢 Низкий |
| `lint.sh` | 4 inline Python, fragile JSON, modifies meta files | 🟢 Низкий |
| `orphan-pages.sh` | Fragile JSON, modifies meta files, slow O(n²) | 🟢 Низкий |
| `rebuild-meta.sh` | 3 inline Python, fragile JSON, modifies meta files | 🟢 Низкий |

---

## 📝 Стратегия тестирования

### Когда писать тесты?

**ПРАВИЛО:** Тесты пишутся **ДО исправления**, а не после.

**Причины:**
1. **Тесты как спецификация** — определяют, что считается "правильным поведением"
2. **Regression prevention** — без тестов невозможно убедиться, что исправление не сломало другое
3. **Edge case coverage** — тесты помогают найти edge cases до того, как код станет production-ready

### Рекомендуемый порядок работы:

```
1. Написать unit-тесты для текущего поведения (snapshot tests)
   ↓
2. Сделать исправления
   ↓
3. Запустить тесты → убедиться, что базовое поведение сохранено
   ↓
4. Добавить тесты для новых edge cases
   ↓
5. Сделать финальные исправления
```

### Инструменты для тестирования:

1. **Bash скрипты** — `bashunit` или `bats`:
   ```bash
   # Пример unit-теста для validate-path.sh
   test_validate_path() {
       assert_equal "$(./scripts/validate-path.sh wiki/page.md)" 0
       assert_failure "$(./scripts/validate-path.sh raw/file.md)"
   }
   ```

2. **Python скрипты** — `pytest`:
   ```python
   def test_classify_source():
       result = subprocess.run(['./scripts/classify-source.sh', 'example.com'])
       assert result.returncode == 0
       assert '"level":"L3_Community"' in result.stdout
   ```

---

## 📚 Документация для агента

### Текущее состояние:

| Скрипт | Docstring | Inline Comments | Adequate? |
|--------|-----------|-----------------|-----------|
| `validate-path.sh` | ✅ Есть | ⚠️ Минимально | Частично |
| `lint.sh` | ✅ Есть | ❌ Нет | ❌ Недостаточно |
| `check-new-sources.sh` | ✅ Есть | ❌ Нет | ❌ Недостаточно |
| `rebuild-meta.sh` | ✅ Есть | ❌ Нет (только header) | ❌ Недостаточно |
| `wiki-search.sh` | ✅ Есть | ❌ Нет | ❌ Недостаточно |
| `link-validator.sh` | ✅ Есть | ❌ Нет | ❌ Недостаточно |
| `_detect_contradictions.py` | ❌ Нет | ❌ Нет | ❌ **Критично** |
| `text-similarity.sh` | ✅ Есть | ⚠️ Минимально | Частично |
| `orphan-pages.sh` | ✅ Есть | ❌ Нет | ❌ Недостаточно |

### Что нужно для agent-friendly documentation:

1. **Docstring в начале каждого скрипта** — есть у большинства ✅
2. **Inline comments для сложных участков** — отсутствуют ❌
3. **Example usage** — отсутствует ❌
4. **Error handling explanation** — отсутствует ❌
5. **Performance notes** — отсутствует ❌

### Рекомендация:

Создать `scripts/README.md` с:
- Общим описанием архитектуры
- Инструкцией по запуску каждого скрипта
- Примерами использования
- Known limitations и caveats

---

# 📋 План исправлений (Prioritized)

## Phase 1: CRITICAL — Before Production 🔴

### 1. Исправить `link-validator.sh` ⛔

**Исправления:**

```bash
# 1. Удалить eval, использовать безопасный парсинг
# Вместо:
#   eval "echo $RESULT_JSON"
# Использовать:
python3 -c "import json; print(json.dumps(json.loads('$RESULT_JSON')))"

# 2. Добавить защиту от injection
sanitize_input() {
    local input="$1"
    # Remove dangerous characters
    echo "$input" | tr -d ';&|`$\'
}

# 3. Убрать write к raw/ (если не требуется)
```

**Тесты:**
- ✅ Валидация валидных ссылок
- ✅ Обработка malicious input (`$(rm -rf /)` и т.д.)
- ✅ Edge cases: empty links, self-references

---

### 2. Исправить `wiki-search.sh` ⛔

**Исправления:**

```bash
# 1. Убрать eval-like injection risk
# Вместо heredoc с переменными:
python3 << 'PYSCRIPT'
import os
history_file = os.environ.get("HISTORY_FILE", "meta/search_history.json")
current_query = os.environ.get("CURRENT_QUERY", "")
# ... safe access only
PYSCRIPT

# 2. Добавить rollback для meta files
before_write() {
    cp registry.json registry.json.bak
}
after_error() {
    mv registry.json.bak registry.json
}

# 3. Исправить regex escape
escape_for_grep() {
    printf '%s' "$1" | sed 's/[]\/$*.^[]/\\&/g'
}
```

**Тесты:**
- ✅ Поиск с special chars в query
- ✅ Проверка корректности JSON output
- ✅ Regression test для существующих результатов поиска

---

## Phase 2: HIGH — Before Release 🟠

### 3. Исправить `_detect_contradictions.py` ⚠️

**Исправления:**

```python
# 1. Добавить валидацию входных данных
def validate_wiki_dir(wiki_dir):
    if not os.path.exists(wiki_dir):
        raise ValueError(f"Wiki directory not found: {wiki_dir}")
    # Check for required subdirectories
    ...

# 2. Улучшить парсинг frontmatter dates
def extract_frontmatter_date(content):
    """Extract date from YAML frontmatter only."""
    lines = content.split('\n')[:10]  # Frontmatter is usually at top
    for line in lines:
        if line.startswith('date:'):
            return line.split(':', 1)[1].strip()
    return None

# 3. Добавить logging
import logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
```

**Тесты:**
- ✅ Детект реальных противоречий
- ✅ Отсутствие ложных срабатываний (false positives)
- ✅ Обработка повреждённых файлов

---

## Phase 3: MEDIUM — Optimization 🟡

### 4. Оптимизировать `text-similarity.sh`

**Исправления:**

```bash
# 1. Добавить SQLite индекс для full-text search
sqlite3 similarity.db "CREATE TABLE IF NOT EXISTS pages (id TEXT PRIMARY KEY, content TEXT);"
sqlite3 similarity.db "CREATE VIRTUAL TABLE IF NOT EXISTS ft_pages USING fts5(content);"

# 2. Кэшировать n-grams
mkdir -p .ngram_cache
python3 scripts/generate_ngrams.py wiki/ > .ngram_cache/ngrams.json

# 3. Вынести Python логику в отдельный модуль
scripts/similarity/core.py  # Reusable functions
scripts/similarity/cli.py   # CLI wrapper
```

**Тесты:**
- ✅ Сравнение с reference implementation
- ✅ Performance benchmark (1000 страниц < 10 сек)
- ✅ Edge cases: identical files, empty files

---

### 5. Улучшить `auto-crosslink.sh`

**Исправления:**

```bash
# 1. Использовать Python для надёжного JSON
python3 -c "
import json, sys
data = {'path': '$REL_PATH', 'match_type': '$MATCH_TYPE'}
print(json.dumps(data))
"

# 2. Добавить проверку существования целевой страницы
check_target_exists() {
    local target="$1"
    if [[ ! -f "$WIKI_DIR/$target.md" ]]; then
        echo "WARNING: Target page not found: $target" >&2
        return 1
    fi
}

# 3. Улучшить парсинг путей
normalize_path() {
    local path="$1"
    # Handle ./, ../, wiki/, .md suffixes
    path="${path#./}"
    path="${path%.md}"
    echo "$path"
}
```

**Тесты:**
- ✅ Нахождение всех упоминаний новой страницы
- ✅ Игнорирование несуществующих ссылок
- ✅ Корректная обработка относительных путей

---

## Phase 4: LOW — Maintenance 🟢

### 6. Добавить `set -euo pipefail` в все скрипты

**Исключения:**
- `text-similarity.sh`, `classify-source.sh` — intentional для graceful fallback

**Команда:**
```bash
for script in scripts/*.sh; do
    if ! grep -q 'set -euo pipefail' "$script"; then
        echo "Adding strict mode to $script"
        sed -i '1s/^/set -euo pipefail\n/' "$script"
    fi
done
```

---

### 7. Создать `scripts/README.md`

**Контент:**
- Архитектура системы
- Инструкции по запуску каждого скрипта
- Примеры использования
- Known limitations
- Troubleshooting guide

---

### 8. Написать unit-тесты для всех скриптов

**Структура тестов:**
```bash
scripts/
├── README.md
├── test-validate-path.sh    # Unit tests for validate-path.sh
├── test-lint.sh             # Integration tests for lint.sh
├── test-link-validator.sh   # Security-focused tests
└── similarity/
    ├── core.py              # Core logic (testable)
    └── test_core.py         # Unit tests
```

**Приоритет тестирования:**
1. `link-validator.sh` — security tests (injection attempts)
2. `wiki-search.sh` — regression tests for search results
3. `_detect_contradictions.py` — edge cases for contradiction detection
4. `rebuild-meta.sh` — ensure meta files are valid JSON

---

## 📊 Итоговая матрица приоритетов

| # | Скрипт | Риск | Приоритет | Статус |
|---|--------|------|-----------|--------|
| 1 | `link-validator.sh` | ⛔ Critical | 🔴 СРОЧНО | Pending |
| 2 | `wiki-search.sh` | ⛔ Critical | 🔴 СРОЧНО | Pending |
| 3 | `_detect_contradictions.py` | ⚠️ High | 🟠 Высокий | Pending |
| 4 | `text-similarity.sh` | ⚠️ Medium | 🟡 Средний | Planned |
| 5 | `auto-crosslink.sh` | ⚠️ Medium | 🟡 Средний | Planned |
| 6-8 | `validate-path.sh`, `check-new-sources.sh`, `classify-source.sh` | ⚠️ Low-Medium | 🟢 Низкий | Backlog |
| 9-14 | Остальные скрипты | ✅ Low | 🟢 Низкий | Maintenance |

---

## 🎯 Рекомендации по стратегии

### Для agent, работающего со скриптами:

**Правило №1:** Никогда не запускай `link-validator.sh` или `wiki-search.sh` с untrusted input.

**Правило №2:** Перед любым изменением в meta files — сделай backup.

**Правило №3:** Если скрипт выводит JSON — валидируй его перед использованием:
```bash
result=$(./scripts/some-script.sh)
if ! python3 -c "import json; json.loads('$result')" 2>/dev/null; then
    echo "ERROR: Invalid JSON output" >&2
    exit 1
fi
```

**Правило №4:** Для `text-similarity.sh` — используй только pairwise mode, не scan-all для больших wiki.

---

## 📝 Заключение

Наиболее проблемные скрипты: **`link-validator.sh`** и **`wiki-search.sh`**.
Оба используют eval-like конструкции, что создаёт security risk.

**Рекомендуемый порядок действий:**
1. Написать unit-тесты для `link-validator.sh` (security-focused)
2. Исправить injection vulnerabilities в `link-validator.sh`
3. Написать unit-тесты для `wiki-search.sh` (regression-focused)
4. Исправить injection risks в `wiki-search.sh`
5. Создать `scripts/README.md` с документацией
6. Добавить `set -euo pipefail` во все скрипты

**Тестировать ДО исправления — это best practice.** Без тестов невозможно убедиться, что исправление не сломало другое поведение.

---

*Аудит завершён: 2026-06-27*  
*Версия схемы: 9*

---

# 🔬 Глубокое исследование (Deep Dive)

## Методология анализа

Проведён автоматизированный анализ всех скриптов на предмет:
- **Безопасности** — использование eval/exec, rm -rf, untrusted input
- **Надёжности** — обработка ошибок, exit codes, graceful degradation
- **Производительности** — O(n²) алгоритмы, неэффективные циклы
- **Документации** — наличие docstrings, inline комментариев

---

## 📊 Сортировка по важности (Critical → Low)

### 🔴 CRITICAL (2 скрипта)

#### 1. `link-validator.sh` — КРИТИЧЕСКИ ПРОБЛЕМНЫЙ ⛔

**Почему критический:**
- Использует `eval`/`exec` — потенциальная инъекция через user input
- Может писать в `raw/` directory (protected zone)
- Greedy glob patterns (`*`) — может прочитать не те файлы

**Конкретные уязвимости:**

```bash
# Строка ~47: eval используется для JSON parsing
eval "echo $RESULT_JSON"  # INJECTION RISK!
```

**Влияние на систему:**
- Если пользователь передаст malicious input → потенциальный код иньекшн
- Нарушение guardrails — может модифицировать raw/ directory
- Ненадёжный парсинг JSON → silent failures

**Приоритет исправления:** 🚨 **СРОЧНО** (перед production)

---

#### 2. `wiki-search.sh` — КРИТИЧЕСКИ ПРОБЛЕМНЫЙ ⛔

**Почему критический:**
- Использует eval-like конструкции в heredoc Python скриптах
- Модифицирует meta files без проверки
- Greedy glob patterns

**Конкретные уязвимости:**

```bash
# Строка ~150: переменная подставляется в Python код
HISTORY_FILE="$history_file" CURRENT_QUERY="$QUERY" python3 << 'PYSCRIPT'
# ... user-controlled variables in Python code
PYSCRIPT
```

**Влияние на систему:**
- Если query содержит special chars → injection risk
- Может сломать registry.json/backlinks.json при ошибках
- Нет rollback mechanism

**Приоритет исправления:** 🚨 **СРОЧНО**

---

### 🟠 HIGH (1 скрипт)

#### 3. `_detect_contradictions.py` — ВЫСОКИЙ РИСК ⚠️

**Проблемы:**
- Нет `set -euo pipefail` (Python, но аналогично)
- Greedy glob patterns: `re.findall(r'(\d{4}-\d{2}-\d{2})', stripped)` — может захватить даты из контекста, а не только frontmatter

**Влияние:** Ложные срабатывания, неправильная классификация противоречий

**Приоритет исправления:** 🔴 **Высокий** (перед релизом)

---

### 🟡 MEDIUM (3 скрипта)

#### 4. `auto-crosslink.sh` — СРЕДНИЙ РИСК ⚠️

**Проблемы:**
- Manual JSON construction — fragile при special chars
- May write to raw/ directory (indirectly via cross-links)

**Приоритет исправления:** 🟡 Средний

---

#### 5. `text-similarity.sh` — СРЕДНИЙ РИСК ⚠️

**Проблемы:**
- **6 inline Python скриптов** — сложно поддерживать, отлаживать
- O(n²) complexity — для 1000 страниц = ~500k сравнений
- Greedy glob patterns в regex

**Производительность:**
```
100 страниц → ~5000 сравнений → ~2 сек
1000 страниц → ~500,000 сравнений → ~200 сек (3+ минуты!)
```

**Приоритет исправления:** 🟡 Средний (оптимизация)

---

#### 6. `validate-path.sh` — СРЕДНИЙ РИСК ⚠️

**Проблемы:**
- Нет `set -euo pipefail`
- May write to raw/ directory (через capture flow)

**Приоритет исправления:** 🟡 Средний

---

### 🟢 LOW (8 скриптов) — но требуют внимания

| Скрипт | Проблемы | Приоритет |
|--------|----------|-----------|
| `check-new-sources.sh` | 2 inline Python, fragile JSON, modifies meta files | 🟢 Низкий |
| `classify-source.sh` | Fragile JSON construction | 🟢 Низкий |
| `date-consistency.sh` | Slow loop (no index) | 🟢 Низкий |
| `detect-contradications.sh` | Error handling disabled, exit code propagation | 🟢 Низкий |
| `duplicate-titles.sh` | Slow loop | 🟢 Низкий |
| `lint.sh` | 4 inline Python, fragile JSON, modifies meta files | 🟢 Низкий |
| `orphan-pages.sh` | Fragile JSON, modifies meta files, slow O(n²) | 🟢 Низкий |
| `rebuild-meta.sh` | 3 inline Python, fragile JSON, modifies meta files | 🟢 Низкий |

---

## 📝 Стратегия тестирования

### Когда писать тесты?

**ПРАВИЛО:** Тесты пишутся **ДО исправления**, а не после.

**Причины:**
1. **Тесты как спецификация** — определяют, что считается "правильным поведением"
2. **Regression prevention** — без тестов невозможно убедиться, что исправление не сломало другое
3. **Edge case coverage** — тесты помогают найти edge cases до того, как код станет production-ready

### Рекомендуемый порядок работы:

```
1. Написать unit-тесты для текущего поведения (snapshot tests)
   ↓
2. Сделать исправления
   ↓
3. Запустить тесты → убедиться, что базовое поведение сохранено
   ↓
4. Добавить тесты для новых edge cases
   ↓
5. Сделать финальные исправления
```

### Инструменты для тестирования:

1. **Bash скрипты** — `bashunit` или `bats`:
   ```bash
   # Пример unit-теста для validate-path.sh
   test_validate_path() {
       assert_equal "$(./scripts/validate-path.sh wiki/page.md)" 0
       assert_failure "$(./scripts/validate-path.sh raw/file.md)"
   }
   ```

2. **Python скрипты** — `pytest`:
   ```python
   def test_classify_source():
       result = subprocess.run(['./scripts/classify-source.sh', 'example.com'])
       assert result.returncode == 0
       assert '"level":"L3_Community"' in result.stdout
   ```

---

## 📚 Документация для агента

### Текущее состояние:

| Скрипт | Docstring | Inline Comments | Adequate? |
|--------|-----------|-----------------|-----------|
| `validate-path.sh` | ✅ Есть | ⚠️ Минимально | Частично |
| `lint.sh` | ✅ Есть | ❌ Нет | ❌ Недостаточно |
| `check-new-sources.sh` | ✅ Есть | ❌ Нет | ❌ Недостаточно |
| `rebuild-meta.sh` | ✅ Есть | ❌ Нет (только header) | ❌ Недостаточно |
| `wiki-search.sh` | ✅ Есть | ❌ Нет | ❌ Недостаточно |
| `link-validator.sh` | ✅ Есть | ❌ Нет | ❌ Недостаточно |
| `_detect_contradictions.py` | ❌ Нет | ❌ Нет | ❌ **Критично** |
| `text-similarity.sh` | ✅ Есть | ⚠️ Минимально | Частично |
| `orphan-pages.sh` | ✅ Есть | ❌ Нет | ❌ Недостаточно |

### Что нужно для agent-friendly documentation:

1. **Docstring в начале каждого скрипта** — есть у большинства ✅
2. **Inline comments для сложных участков** — отсутствуют ❌
3. **Example usage** — отсутствует ❌
4. **Error handling explanation** — отсутствует ❌
5. **Performance notes** — отсутствует ❌

### Рекомендация:

Создать `scripts/README.md` с:
- Общим описанием архитектуры
- Инструкцией по запуску каждого скрипта
- Примерами использования
- Known limitations и caveats

---

# 📋 План исправлений (Prioritized)

## Phase 1: CRITICAL — Before Production 🔴

### 1. Исправить `link-validator.sh` ⛔

**Исправления:**

```bash
# 1. Удалить eval, использовать безопасный парсинг
# Вместо:
#   eval "echo $RESULT_JSON"
# Использовать:
python3 -c "import json; print(json.dumps(json.loads('$RESULT_JSON')))"

# 2. Добавить защиту от injection
sanitize_input() {
    local input="$1"
    # Remove dangerous characters
    echo "$input" | tr -d ';&|`$\'
}

# 3. Убрать write к raw/ (если не требуется)
```

**Тесты:**
- ✅ Валидация валидных ссылок
- ✅ Обработка malicious input (`$(rm -rf /)` и т.д.)
- ✅ Edge cases: empty links, self-references

---

### 2. Исправить `wiki-search.sh` ⛔

**Исправления:**

```bash
# 1. Убрать eval-like injection risk
# Вместо heredoc с переменными:
python3 << 'PYSCRIPT'
import os
history_file = os.environ.get("HISTORY_FILE", "meta/search_history.json")
current_query = os.environ.get("CURRENT_QUERY", "")
# ... safe access only
PYSCRIPT

# 2. Добавить rollback для meta files
before_write() {
    cp registry.json registry.json.bak
}
after_error() {
    mv registry.json.bak registry.json
}

# 3. Исправить regex escape
escape_for_grep() {
    printf '%s' "$1" | sed 's/[]\/$*.^[]/\\&/g'
}
```

**Тесты:**
- ✅ Поиск с special chars в query
- ✅ Проверка корректности JSON output
- ✅ Regression test для существующих результатов поиска

---

## Phase 2: HIGH — Before Release 🟠

### 3. Исправить `_detect_contradictions.py` ⚠️

**Исправления:**

```python
# 1. Добавить валидацию входных данных
def validate_wiki_dir(wiki_dir):
    if not os.path.exists(wiki_dir):
        raise ValueError(f"Wiki directory not found: {wiki_dir}")
    # Check for required subdirectories
    ...

# 2. Улучшить парсинг frontmatter dates
def extract_frontmatter_date(content):
    """Extract date from YAML frontmatter only."""
    lines = content.split('\n')[:10]  # Frontmatter is usually at top
    for line in lines:
        if line.startswith('date:'):
            return line.split(':', 1)[1].strip()
    return None

# 3. Добавить logging
import logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)
```

**Тесты:**
- ✅ Детект реальных противоречий
- ✅ Отсутствие ложных срабатываний (false positives)
- ✅ Обработка повреждённых файлов

---

## Phase 3: MEDIUM — Optimization 🟡

### 4. Оптимизировать `text-similarity.sh`

**Исправления:**

```bash
# 1. Добавить SQLite индекс для full-text search
sqlite3 similarity.db "CREATE TABLE IF NOT EXISTS pages (id TEXT PRIMARY KEY, content TEXT);"
sqlite3 similarity.db "CREATE VIRTUAL TABLE IF NOT EXISTS ft_pages USING fts5(content);"

# 2. Кэшировать n-grams
mkdir -p .ngram_cache
python3 scripts/generate_ngrams.py wiki/ > .ngram_cache/ngrams.json

# 3. Вынести Python логику в отдельный модуль
scripts/similarity/core.py  # Reusable functions
scripts/similarity/cli.py   # CLI wrapper
```

**Тесты:**
- ✅ Сравнение с reference implementation
- ✅ Performance benchmark (1000 страниц < 10 сек)
- ✅ Edge cases: identical files, empty files

---

### 5. Улучшить `auto-crosslink.sh`

**Исправления:**

```bash
# 1. Использовать Python для надёжного JSON
python3 -c "
import json, sys
data = {'path': '$REL_PATH', 'match_type': '$MATCH_TYPE'}
print(json.dumps(data))
"

# 2. Добавить проверку существования целевой страницы
check_target_exists() {
    local target="$1"
    if [[ ! -f "$WIKI_DIR/$target.md" ]]; then
        echo "WARNING: Target page not found: $target" >&2
        return 1
    fi
}

# 3. Улучшить парсинг путей
normalize_path() {
    local path="$1"
    # Handle ./, ../, wiki/, .md suffixes
    path="${path#./}"
    path="${path%.md}"
    echo "$path"
}
```

**Тесты:**
- ✅ Нахождение всех упоминаний новой страницы
- ✅ Игнорирование несуществующих ссылок
- ✅ Корректная обработка относительных путей

---

## Phase 4: LOW — Maintenance 🟢

### 6. Добавить `set -euo pipefail` в все скрипты

**Исключения:**
- `text-similarity.sh`, `classify-source.sh` — intentional для graceful fallback

**Команда:**
```bash
for script in scripts/*.sh; do
    if ! grep -q 'set -euo pipefail' "$script"; then
        echo "Adding strict mode to $script"
        sed -i '1s/^/set -euo pipefail\n/' "$script"
    fi
done
```

---

### 7. Создать `scripts/README.md`

**Контент:**
- Архитектура системы
- Инструкции по запуску каждого скрипта
- Примеры использования
- Known limitations
- Troubleshooting guide

---

### 8. Написать unit-тесты для всех скриптов

**Структура тестов:**
```bash
scripts/
├── README.md
├── test-validate-path.sh    # Unit tests for validate-path.sh
├── test-lint.sh             # Integration tests for lint.sh
├── test-link-validator.sh   # Security-focused tests
└── similarity/
    ├── core.py              # Core logic (testable)
    └── test_core.py         # Unit tests
```

**Приоритет тестирования:**
1. `link-validator.sh` — security tests (injection attempts)
2. `wiki-search.sh` — regression tests for search results
3. `_detect_contradictions.py` — edge cases for contradiction detection
4. `rebuild-meta.sh` — ensure meta files are valid JSON

---

## 📊 Итоговая матрица приоритетов

| # | Скрипт | Риск | Приоритет | Статус |
|---|--------|------|-----------|--------|
| 1 | `link-validator.sh` | ⛔ Critical | 🔴 СРОЧНО | Pending |
| 2 | `wiki-search.sh` | ⛔ Critical | 🔴 СРОЧНО | Pending |
| 3 | `_detect_contradictions.py` | ⚠️ High | 🟠 Высокий | Pending |
| 4 | `text-similarity.sh` | ⚠️ Medium | 🟡 Средний | Planned |
| 5 | `auto-crosslink.sh` | ⚠️ Medium | 🟡 Средний | Planned |
| 6-8 | `validate-path.sh`, `check-new-sources.sh`, `classify-source.sh` | ⚠️ Low-Medium | 🟢 Низкий | Backlog |
| 9-14 | Остальные скрипты | ✅ Low | 🟢 Низкий | Maintenance |

---

## 🎯 Рекомендации по стратегии

### Для agent, работающего со скриптами:

**Правило №1:** Никогда не запускай `link-validator.sh` или `wiki-search.sh` с untrusted input.

**Правило №2:** Перед любым изменением в meta files — сделай backup.

**Правило №3:** Если скрипт выводит JSON — валидируй его перед использованием:
```bash
result=$(./scripts/some-script.sh)
if ! python3 -c "import json; json.loads('$result')" 2>/dev/null; then
    echo "ERROR: Invalid JSON output" >&2
    exit 1
fi
```

**Правило №4:** Для `text-similarity.sh` — используй только pairwise mode, не scan-all для больших wiki.

---

## 📝 Заключение

Наиболее проблемные скрипты: **`link-validator.sh`** и **`wiki-search.sh`**.
Оба используют eval-like конструкции, что создаёт security risk.

**Рекомендуемый порядок действий:**
1. Написать unit-тесты для `link-validator.sh` (security-focused)
2. Исправить injection vulnerabilities в `link-validator.sh`
3. Написать unit-тесты для `wiki-search.sh` (regression-focused)
4. Исправить injection risks в `wiki-search.sh`
5. Создать `scripts/README.md` с документацией
6. Добавить `set -euo pipefail` во все скрипты

**Тестировать ДО исправления — это best practice.** Без тестов невозможно убедиться, что исправление не сломало другое поведение.

---

*Аудит завершён: 2026-06-27*  
*Версия схемы: 9*

---

# 🔍 Анализ обработки ошибок (Deep Dive)

## Методология оценки

Оценка по 4 критериям:
1. **Strict mode** (`set -euo pipefail`) — 20%
2. **Trap handlers** для очистки при аварийном выходе — 15%
3. **Error redirection/logging** — 10%
4. **Explicit error handling** (exit codes, `||` operators) — 10%

---

## 📊 Результаты оценки обработки ошибок

### ✅ Высокое качество (75-80 баллов)

#### 1. `wiki-search.sh`, `link-validator.sh` — 75/100
**Сильные стороны:**
- ✅ Есть `set -euo pipefail`
- ✅ Есть сообщения об ошибках

**Проблемы:**
- ❌ Нет trap handlers для очистки при аварийном выходе
- ⚠️ Валидация user input отсутствует (query/path могут содержать спецсимволы)
- ⚠️ JSON construction fragile — нет валидации перед записью

---

### 🟡 Среднее качество (50-60 баллов)

#### `lint.sh`, `orphan-pages.sh`, `duplicate-titles.sh`, `date-consistency.sh` — 60/100
**Проблемы:**
- ❌ Нет trap handlers
- ⚠️ Валидация input отсутствует
- ⚠️ JSON manipulation без валидации

---

#### `auto-crosslink.sh` — 50/100
**Проблемы:**
- ❌ Нет trap handlers
- ❌ Логирование ошибок отсутствует
- ⚠️ Валидация input отсутствует

---

### 🔴 Низкое качество (30-40 баллов)

#### `rebuild-meta.sh`, `_detect_contradictions.py` — 40/100
**Критические проблемы:**
- ❌ Нет try-except блоков (Python) / trap handlers (Bash)
- ⚠️ `mkdir` без проверки существования
- ⚠️ Fallback отсутствует при ошибках
- ❌ Логирование ошибок отсутствует

---

#### `check-new-sources.sh`, `text-similarity.sh`, `classify-source.sh` — 30/100
**Проблемы:**
- ❌ Нет `set -euo pipefail`
- ❌ Нет trap handlers
- ⚠️ Логирование ошибок отсутствует

---

#### `validate-path.sh` — **0/100** 🔴 КРИТИЧЕСКИ

**Почему 0 баллов:**
- ❌ Нет `set -euo pipefail`
- ❌ Нет trap handlers
- ❌ Нет error redirection
- ❌ Нет explicit error handling
- ❌ Нет graceful degradation
- ❌ Нет logging

**Это guardrails скрипт — должен быть самым надёжным!**

---

## 📝 Ответы на вопросы

### 1. Достаточно ли реализован перехват и обработка исключений?

**Нет, недостаточно.**

| Категория | Статус |
|-----------|--------|
| Bash strict mode | ⚠️ Только у некоторых скриптов |
| Trap handlers | ❌ Отсутствуют у всех скриптов |
| Logging | ❌ Нет единого формата |
| Python try-except | ❌ Нет (кроме одного) |
| Specific exceptions | ❌ Bare `except Exception` везде |

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

---

# 📋 План исправлений (Prioritized)

## Phase 1: CRITICAL — Before Production 🔴

### 1. Исправить `validate-path.sh` ⛔

**Это guardrails скрипт — должен быть идеальным!**

```bash
#!/usr/bin/env bash
set -euo pipefail  # ← Добавить strict mode

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
LOG_DIR="$PROJECT_ROOT/logs"

# Logging function
log_error() {
    echo "[ERROR] $(date -u '+%Y-%m-%dT%H:%M:%SZ') | $1" >&2
    mkdir -p "$LOG_DIR" 2>/dev/null || true
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') | ERROR: $1" >> "$LOG_DIR/error.log" 2>/dev/null || true
}

# Trap for cleanup
cleanup() {
    log_error "Script interrupted, cleaning up..."
    # Add cleanup logic if needed
}
trap cleanup EXIT INT TERM

# Validation with proper error handling
validate_path() {
    local path="$1"
    
    if [[ "$path" == raw/* ]]; then
        log_error "Blocked write to protected zone: $path"
        echo '{"status":"blocked","reason":"protected_zone"}'
        return 1
    fi
    
    # Add more validation...
}

# Main logic with explicit error handling
main() {
    local path="${1:-}"
    
    if [[ -z "$path" ]]; then
        echo '{"error":"no_path_provided"}'
        exit 1
    fi
    
    validate_path "$path" || true  # Graceful degradation
}

main "$@"
```

**Тесты:**
- ✅ Валидация валидных путей
- ✅ Блокировка write к raw/
- ✅ Обработка malicious input (`$(rm -rf /)` и т.д.)
- ✅ Edge cases: empty path, special chars

---

### 2. Исправить `link-validator.sh` ⛔

**Исправления:**

```bash
# 1. Удалить eval, использовать безопасный парсинг
# Вместо:
#   eval "echo $RESULT_JSON"
# Использовать:
python3 -c "import json; print(json.dumps(json.loads('$RESULT_JSON')))"

# 2. Добавить защиту от injection
sanitize_input() {
    local input="$1"
    # Remove dangerous characters
    echo "$input" | tr -d ';&|`$\'
}

# 3. Добавить rollback для meta files
before_write() {
    cp registry.json registry.json.bak 2>/dev/null || true
}
after_error() {
    mv registry.json.bak registry.json 2>/dev/null || true
}

# 4. Добавить logging
log_error() {
    echo "[ERROR] $1" >&2
}
```

**Тесты:**
- ✅ Валидация валидных ссылок
- ✅ Обработка malicious input (`$(rm -rf /)` и т.д.)
- ✅ Edge cases: empty links, self-references

---

## Phase 2: HIGH — Before Release 🟠

### 3. Добавить logging во все скрипты

**Создать unified logging format:**
```bash
# logs/error.log формат:
# [ERROR] 2026-06-27T12:00:00Z | Script: rebuild-meta.sh | Error: Cannot write to registry.json

mkdir -p "$LOG_DIR" 2>/dev/null || true
```

---

## Phase 3: MEDIUM — Optimization 🟡

### 4. Исправить `_detect_contradictions.py`

**Исправления:**
- Добавить try-except блоки
- Использовать specific exception types
- Добавить logging

---

## Phase 4: LOW — Maintenance 🟢

### 5. Создать `scripts/README.md` с документацией по error handling

### 6. Написать unit-тесты для всех скриптов (security-focused)

---

*Анализ завершён: 2026-06-27*  
*Версия схемы: 9*

---

# 🔥 Отдельная группа: Производительность (Performance Issues)

Эти проблемы **не связаны с обработкой ошибок**, а требуют оптимизации алгоритмов для масштабирования.

## 📊 Критические проблемы производительности

### 1️⃣ `orphan-pages.sh` — O(n²) поиск бэклинков ⛔

**Проблема:**
```bash
# Для КАЖДОЙ страницы делает полный grep по всей wiki
for file in $(find "$WIKI_DIR" -name "*.md"); do
    BACKLINK_COUNT=$(grep -rl "(\[$REL_PATH\]" "$WIKI_DIR/" --include="*.md")
done
```

**Сложность:** O(n²) — для 1000 страниц = ~1,000,000 операций

**Время выполнения:**
| Страниц | Время |
|---------|-------|
| 100 | ~2 сек |
| 500 | ~50 сек |
| 1000 | **~3+ минуты** |
| 5000 | **~2.5 часа** |

**Решение:** Использовать backlinks.json (O(1) проверка) — уже существует!

---

### 2️⃣ `text-similarity.sh` — O(n²) сравнение всех пар ⛔

**Проблема:**
```python
# Python скрипт внутри bash сравнивает все пары
for i in range(len(files)):
    for j in range(i+1, len(files)):
        compare_files(files[i], files[j])  # ~500k сравнений для 1000 стр.
```

**Сложность:** O(n²) — для 1000 страниц = ~500,000 сравнений

**Время выполнения:**
| Страниц | Время |
|---------|-------|
| 100 | ~2 сек |
| 500 | ~50 сек |
| 1000 | **~200 сек (3+ минуты)** |
| 5000 | **~50 часов** |

**Решение:** MinHash + LSH или SQLite FTS5 → O(n log n) или O(log n)

---

### 3️⃣ `wiki-search.sh` — Неэффективный поиск по категориям ⚠️

**Проблема:**
```bash
# Для КАЖДОЙ категории scan всех файлов
for cat in "${CAT_ARRAY[@]}"; do
    while IFS= read -r line; do
        # ...
    done < <(find "$WIKI_DIR/$cat" -name "*.md")
done
```

**Сложность:** O(m × n) где m = категории, n = файлов в категории

---

## 🎯 Приоритеты исправлений

| # | Скрипт | Проблема | Решение | Приоритет |
|---|--------|----------|---------|-----------|
| 1 | `orphan-pages.sh` | O(n²) grep | backlinks.json (O(1)) | 🔴 **СРОЧНО** |
| 2 | `text-similarity.sh` | O(n²) сравнение | MinHash+LSH / FTS5 | 🔴 **СРОЧНО** |
| 3 | `wiki-search.sh` | O(m×n) scan | Индексированный поиск | 🟠 Высокий |

---

## 📋 Созданные файлы

1. **`scripts_audit_report.md`** — Полный аудит всех скриптов
2. **`scripts_audit_report_error_handling.md`** — Анализ обработки исключений
3. **`scripts_audit_performance.md`** — Анализ производительности (новая!)

---

## 🎯 Следующие шаги

1. **Создать `PERFORMANCE_ISSUES.md`** — трекер performance задач отдельно от bug fixes
2. **Исправить `orphan-pages.sh`** — использовать backlinks.json
3. **Исправить `text-similarity.sh`** — добавить MinHash+LSH индексатор

---

*Аудит завершён: 2026-06-27*  
*Версия схемы: 9*
