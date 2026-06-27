# 🔍 Аудит производительности скриптов Loom Wiki

**Дата:** 2026-06-27  
**Версия схемы:** 9

---

## 📊 Выявленные проблемы производительности

### 🔴 CRITICAL — Требуют немедленного внимания

#### 1. `orphan-pages.sh` — O(n²) алгоритм поиска бэклинков ⛔

**Текущая реализация:**
```bash
# Для КАЖДОЙ страницы делает полный grep по всей wiki
for file in $(find "$WIKI_DIR" -name "*.md"); do
    BACKLINK_COUNT=$(grep -rl "(\[$REL_PATH\)" "$WIKI_DIR/" --include="*.md" 2>/dev/null | wc -l)
done
```

**Сложность:** O(n²) — для 1000 страниц = ~1,000,000 операций grep

**Время выполнения (оценочное):**
| Кол-во страниц | Время |
|----------------|-------|
| 100 | ~2 сек |
| 500 | ~50 сек |
| 1000 | ~3+ минуты |
| 5000 | ~2.5 часа |

**Решение:** Использовать backlinks.json для O(1) проверки

```bash
# Оптимизированный вариант:
python3 << 'PYSCRIPT'
import json

with open("meta/backlinks.json") as f:
    backlinks = json.load(f)

orphans = []
for page in all_pages:
    if page not in backlinks or len(backlinks[page]) == 0:
        orphans.append(page)
PYSCRIPT
```

**Время выполнения:** O(n) — для 1000 страниц ~50мс

---

#### 2. `text-similarity.sh` — O(n²) сравнение всех пар ⛔

**Текущая реализация:**
```python
# Python скрипт внутри bash
for i in range(len(files)):
    for j in range(i+1, len(files)):
        # Сравнение всех пар
        compare_files(files[i], files[j])
```

**Сложность:** O(n²) — для 1000 страниц = ~500,000 сравнений

**Время выполнения (оценочное):**
| Кол-во страниц | Время |
|----------------|-------|
| 100 | ~2 сек |
| 500 | ~50 сек |
| 1000 | ~200 сек (3+ минуты) |
| 5000 | ~50 часов |

**Решение:** Использовать индексы и кэширование

```python
# Вариант 1: MinHash + LSH (Locality Sensitive Hashing)
from minhash import MinHash, LSH

# O(n log n) вместо O(n²)
minhashes = [MinHash(doc=read_file(f)) for f in files]
lsh = LSH(minhashes, threshold=0.8)
similar_pairs = lsh.query_all()  # Только похожие пары

# Вариант 2: SQLite FTS5 (full-text search)
import sqlite3

conn = sqlite3.connect('similarity.db')
conn.execute('''CREATE VIRTUAL TABLE IF NOT EXISTS pages 
                 USING fts5(content, content=pages)''')
# Поиск по query — O(log n) с бинарным поиском
```

**Время выполнения (оптимизировано):**
| Кол-во страниц | Время (MinHash+LSH) |
|----------------|---------------------|
| 100 | ~50мс |
| 500 | ~200мс |
| 1000 | ~500мс |
| 5000 | ~2 сек |

---

#### 3. `wiki-search.sh` — Неэффективный поиск по категориям ⚠️

**Текущая реализация:**
```bash
# Для КАЖДОЙ категории делает полный scan всех файлов
for cat in "${CAT_ARRAY[@]}"; do
    while IFS= read -r line; do
        filepath=$(echo "$line" | cut -d: -f1)
        matched_line=$(echo "$line" | cut -d: -f2-)
        score_page "$filepath" "$i" "$MAX_PRIORITY"
    done < <(find "$WIKI_DIR/$cat" -name "*.md")
done
```

**Сложность:** O(m × n) где m = количество категорий, n = файлов в категории

**Решение:** Использовать индексированный поиск

```bash
# Предварительная индексация:
python3 << 'PYSCRIPT'
import json
import re

index = {}
for cat in categories:
    index[cat] = []
    
with open("wiki/index.md") as f:
    content = f.read()

# Парсинг H1 заголовков и ключевых слов
for match in re.finditer(r'## (.*?)(?:\n|$)', content, re.DOTALL):
    title = match.group(1).strip()
    # Извлекаем ключевые слова из первого абзаца
    keywords = extract_keywords(title)
    for kw in keywords:
        index[kw].append(title)

with open("search_index.json", "w") as f:
    json.dump(index, f)
PYSCRIPT

# Поиск — O(k log n) с бинарным поиском
def search(query):
    results = []
    for kw in query.split():
        if kw in index:
            results.extend(index[kw])
    return list(set(results))  # Deduplicate
```

---

### 🟡 MEDIUM — Требуют оптимизации

#### 4. `duplicate-titles.sh` — O(n²) сравнение заголовков ⚠️

**Текущая реализация:**
```bash
# Сравнивает каждый файл с каждым другим
for file1 in files; do
    for file2 in files; do
        if [ "$file1" != "$file2" ]; then
            compare_titles "$file1" "$file2"
        fi
    done
done
```

**Решение:** Использовать hash-сет для O(n) проверки дублей

```bash
declare -A title_set
duplicates=()

for file in files; do
    title=$(get_title "$file")
    if [[ "$title" in "${title_set[@]}" ]]; then
        duplicates+=("$file")
    else
        title_set["$title"]="$file"
    fi
done
```

**Сложность:** O(n) вместо O(n²)

---

#### 5. `rebuild-meta.sh` — Неэффективное чтение всех файлов ⚠️

**Текущая реализация:**
```bash
# Чтение ВСЕХ markdown файлов для извлечения frontmatter
find "$WIKI_DIR" -name "*.md" -type f | while read file; do
    # Парсинг каждого файла
done
```

**Решение:** Использовать инкрементальное обновление

```bash
# Хранить индекс в памяти и обновлять только изменённые файлы
touch .meta_update_timestamp
if [ -f .meta_update_timestamp ]; then
    # Сравнить с предыдущим запуском
    changed=$(find "$WIKI_DIR" -name "*.md" -newer .meta_update_timestamp)
else
    changed=$(find "$WIKI_DIR" -name "*.md")
fi

# Обрабатывать только изменённые файлы
for file in $changed; do
    update_meta "$file"
done

touch .meta_update_timestamp
```

---

## 📊 Сравнение производительности (теоретическое)

| Скрипт | Текущее время | Оптимизированное | Улучшение |
|--------|---------------|------------------|-----------|
| `orphan-pages.sh` | O(n²) ~3 мин (1000 стр.) | O(n) ~50мс | **~36,000×** |
| `text-similarity.sh` | O(n²) ~200 сек (1000 стр.) | O(n log n) ~500мс | **~400×** |
| `wiki-search.sh` | O(m×n) ~10 сек (10 cat, 1000 стр.) | O(k log n) ~100мс | **~100×** |

---

## 🎯 Рекомендации по приоритетам

### Phase 1: CRITICAL — Перед масштабированием

| # | Скрипт | Проблема | Решение | Приоритет |
|---|--------|----------|---------|-----------|
| 1 | `orphan-pages.sh` | O(n²) grep | Использовать backlinks.json | 🔴 СРОЧНО |
| 2 | `text-similarity.sh` | O(n²) сравнение | MinHash+LSH или FTS5 | 🔴 СРОЧНО |

### Phase 2: HIGH — Перед ростом базы знаний

| # | Скрипт | Проблема | Решение | Приоритет |
|---|--------|----------|---------|-----------|
| 3 | `wiki-search.sh` | O(m×n) scan | Индексированный поиск | 🟠 Высокий |
| 4 | `duplicate-titles.sh` | O(n²) сравнение | Hash-set для дублей | 🟠 Высокий |

### Phase 3: MEDIUM — Оптимизация

| # | Скрипт | Проблема | Решение | Приоритет |
|---|--------|----------|---------|-----------|
| 5 | `rebuild-meta.sh` | Полный scan每次 | Инкрементальное обновление | 🟡 Средний |

---

## 🔬 Технические решения (детали)

### Решение 1: MinHash + LSH для similarity search

```python
# minhash.py
import hashlib
import random

class MinHash:
    def __init__(self, num_permutations=128):
        self.num = num_permutations
        self.minhashes = [float('inf')] * num_permutations
    
    def update(self, text):
        # Tokenize and hash
        tokens = text.lower().split()[:100]  # Top-100 tokens
        for token in tokens:
            h = int(hashlib.md5(token.encode()).hexdigest(), 16)
            for i in range(self.num):
                self.minhashes[i] = min(self.minhashes[i], h % (2**32))
    
    def distance(self, other):
        # Jaccard similarity
        matches = sum(1 for a, b in zip(self.minhashes, other.minhashes) if a == b)
        return matches / self.num

class LSH:
    def __init__(self, minhashes, threshold=0.8):
        self.minhashes = minhashes
        self.threshold = threshold
    
    def query(self, minhash):
        # Bucket by first k bands
        bands = 4
        band_size = len(minhash.minhashes) // bands
        key = tuple(minhash.minhashes[i:i+band_size] for i in range(0, len(minhash.minhashes), band_size))
        
        # Return all documents in same bucket with similarity > threshold
        results = []
        for doc_minhash in self.buckets[key]:
            if minhash.distance(doc_minhash) >= self.threshold:
                results.append(doc_minhash)
        return results
```

**Использование:**
```bash
# Предварительная индексация (один раз):
python3 scripts/build_similarity_index.py wiki/

# Поиск — быстрый:
python3 scripts/search_similarity.py "query" --index similarity.db
```

---

### Решение 2: SQLite FTS5 для full-text search

```sql
-- Создание индекса
CREATE VIRTUAL TABLE pages USING fts5(
    content,
    content=pages,
    tokenize='porter'
);

-- Индексация
INSERT INTO pages(content) SELECT read_file('wiki/page.md');

-- Поиск — O(log n):
SELECT * FROM pages WHERE pages MATCH 'keyword1 keyword2';
```

**Преимущества:**
- Бинарный поиск по индексу — O(log n)
- Поддержка stemming (porter tokenizer)
- Встроенная deduplication
- ACID compliance для consistency

---

### Решение 3: Backlinks индекс (уже существует!)

**backlinks.json уже содержит оптимизированные данные:**
```json
{
  "wiki/entities/openai.md": ["wiki/index.md", "wiki/overview.md"],
  "wiki/concepts/rag.md": ["wiki/syntheses/rag-vs-llm-wiki-pattern.md"]
}
```

**Использовать вместо grep:**
```bash
# Вместо:
grep -rl "(\[wiki/entities/openai.md\])" "$WIKI_DIR/"

# Использовать:
python3 << 'PYSCRIPT'
import json

with open("meta/backlinks.json") as f:
    backlinks = json.load(f)

# O(1) проверка — страница есть в индексе как ключ?
orphans = [page for page in all_pages if page not in backlinks]
PYSCRIPT
```

---

## 📝 План действий

### 1. Создать `scripts/performance/` с оптимизированными версиями

```bash
scripts/performance/
├── orphan-pages-optimized.py    # O(n) вместо O(n²)
├── similarity-index.py           # MinHash+LSH индексатор
├── search-index.py              # FTS5 индексатор
└── benchmark.sh                 # Бенчмарк производительности
```

### 2. Добавить кэширование результатов

```bash
# Кэш для text-similarity.sh
mkdir -p .similarity_cache
if [ -f .similarity_cache/ngrams.json ]; then
    source .similarity_cache/ngrams.json
else
    python3 scripts/generate_ngrams.py > .similarity_cache/ngrams.json
fi
```

### 3. Создать cron job для периодической индексации

```bash
# crontab -e
0 2 * * * cd /path/to/loomana && python3 scripts/performance/build_similarity_index.py >> logs/index.log 2>&1
0 3 * * * cd /path/to/loomana && python3 scripts/performance/update_backlinks.py >> logs/backlinks.log 2>&1
```

---

## 🎯 Итог

**Проблемы производительности — это отдельная группа issues**, требующая:
1. ✅ Выделения в отдельный трекер (issues.md)
2. ✅ Приоритизации по влиянию на масштабирование
3. ✅ Создания оптимизированных версий с индексами

**Рекомендация:** Создать `PERFORMANCE_ISSUES.md` для отслеживания этих задач отдельно от bug fixes.

---

*Аудит завершён: 2026-06-27*  
*Версия схемы: 9*
