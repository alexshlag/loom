# 🔥 Performance Issues Tracker — Трекер производительности

**Дата создания:** 2026-06-27  
**Версия схемы:** 9

---

## 📊 Обзор проблем производительности

### 🔴 CRITICAL (Срочно)

| # | Issue | Скрипт | Проблема | Влияние | Приоритет |
|---|-------|--------|----------|---------|-----------|
| 1 | **O(n²) orphan detection** | `orphan-pages.sh` | Grep для каждой страницы | ~3 мин (1000 стр.) → не масштабируется | 🔴 СРОЧНО |
| 2 | **O(n²) similarity search** | `text-similarity.sh` | Сравнение всех пар файлов | ~50 часов (5000 стр.) | 🔴 СРОЧНО |

### 🟠 HIGH (Высокий)

| # | Issue | Скрипт | Проблема | Влияние | Приоритет |
|---|-------|--------|----------|---------|-----------|
| 3 | **Inefficient category search** | `wiki-search.sh` | Scan всех файлов для каждой категории | Медленный поиск при росте wiki | 🟠 Высокий |

### 🟡 MEDIUM (Средний)

| # | Issue | Скрипт | Проблема | Влияние | Приоритет |
|---|-------|--------|----------|---------|-----------|
| 4 | **No incremental updates** | `rebuild-meta.sh` | Полный scan每次 | Медленно при частых изменениях | 🟡 Средний |
| 5 | **O(n²) duplicate detection** | `duplicate-titles.sh` | Сравнение всех пар | Неэффективно для больших wiki | 🟡 Средний |

---

## 🔧 Решения (Approved)

### Решение 1: backlinks.json (ИСПОЛЬЗОВАТЬ) ✅

**backlinks.json уже содержит оптимизированные данные!**

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

# Использовать (O(1)):
python3 << 'PYSCRIPT'
import json

with open("meta/backlinks.json") as f:
    backlinks = json.load(f)

orphans = [page for page in all_pages if page not in backlinks]
PYSCRIPT
```

---

### Решение 2: MinHash + LSH для similarity search

**Файлы:** `scripts/performance/similarity_index.py`

**Использование:**
```bash
# Предварительная индексация (один раз):
python3 scripts/performance/similarity_index.py --build wiki/

# Поиск — быстрый:
python3 scripts/performance/search_similarity.py "query"
```

---

### Решение 3: SQLite FTS5 для full-text search

**Файл:** `scripts/performance/fts_search.py`

**Использование:**
```bash
# Индексация:
python3 scripts/performance/fts_search.py --index wiki/

# Поиск:
python3 scripts/performance/fts_search.py "keyword1 keyword2"
```

---

## 📝 Статус задач

### [ ] CRITICAL-1: Исправить orphan-pages.sh

**Текущее время:** ~3 мин (1000 стр.)  
**Целевое время:** < 1 сек  
**Решение:** Использовать backlinks.json

```bash
# TODO: Заменить grep на чтение backlinks.json
python3 << 'PYSCRIPT'
import json, sys

with open("meta/backlinks.json") as f:
    backlinks = json.load(f)

all_pages = [...]  # Список всех страниц wiki
orphans = [p for p in all_pages if p not in backlinks]

print(json.dumps(orphans))
PYSCRIPT
```

**Статус:** ⬜ Не начато  
**Ответственный:** Agent  
**Дедлайн:** 2026-07-04

---

### [ ] CRITICAL-2: Оптимизировать text-similarity.sh

**Текущее время:** ~200 сек (1000 стр.)  
**Целевое время:** < 5 сек  
**Решение:** MinHash + LSH или FTS5

**Варианты:**
- [ ] MinHash + LSH (быстрее, но менее точный)
- [ ] SQLite FTS5 (точнее, требует disk space)
- [ ] Siamese network (ML-based, experimental)

**Статус:** ⬜ Не начато  
**Ответственный:** Agent  
**Дедлайн:** 2026-07-11

---

### [ ] HIGH-3: Индексированный поиск в wiki-search.sh

**Текущее время:** O(m×n) scan  
**Целевое время:** O(k log n) с индексом

**Варианты:**
- [ ] H1 header index (простой, быстрый)
- [ ] Full-text index (точнее, медленнее build)
- [ ] Embedding index (semantic search, experimental)

**Статус:** ⬜ Не начато  
**Ответственный:** Agent  
**Дедлайн:** 2026-07-18

---

### [ ] MEDIUM-4: Инкрементальное обновление rebuild-meta.sh

**Текущее время:** Полный scan每次  
**Целевое время:** Только изменённые файлы

```bash
# TODO: Добавить timestamp-based detection
touch .meta_update_timestamp
if [ -f .meta_update_timestamp ]; then
    changed=$(find "$WIKI_DIR" -name "*.md" -newer .meta_update_timestamp)
else
    changed=$(find "$WIKI_DIR" -name "*.md")
fi
```

**Статус:** ⬜ Не начато  
**Ответственный:** Agent  
**Дедлайн:** 2026-07-25

---

### [ ] MEDIUM-5: Hash-set для duplicate-titles.sh

**Текущее время:** O(n²)  
**Целевое время:** O(n) с hash-set

```bash
declare -A title_set
for file in files; do
    title=$(get_title "$file")
    if [[ "$title" in "${title_set[@]}" ]]; then
        duplicates+=("$file")
    else
        title_set["$title"]="$file"
    fi
done
```

**Статус:** ⬜ Не начато  
**Ответственный:** Agent  
**Дедлайн:** 2026-07-25

---

## 📊 Бенчмарки (Текущие)

| Скрипт | 100 стр. | 500 стр. | 1000 стр. |
|--------|----------|----------|-----------|
| `orphan-pages.sh` | ~2 сек | ~50 сек | **~3 мин** |
| `text-similarity.sh` | ~2 сек | ~50 сек | **~200 сек** |
| `wiki-search.sh` | ~1 сек | ~10 сек | **~50 сек** |

---

## 🎯 План действий (Next 7 days)

### День 1-2: CRITICAL-1
- [ ] Заменить grep на backlinks.json в orphan-pages.sh
- [ ] Написать unit-тесты для нового кода
- [ ] Бенчмарк: убедиться, что время < 1 сек

### День 3-5: CRITICAL-2
- [ ] Создать `scripts/performance/similarity_index.py` с MinHash+LSH
- [ ] Написать unit-тесты для similarity detection
- [ ] Бенчмарк: убедиться, что время < 5 сек

### День 6-7: HIGH-3
- [ ] Создать H1 header index
- [ ] Интегрировать в wiki-search.sh
- [ ] Бенчмарк: измерить улучшение

---

## 🔬 Технические детали (Reference)

### MinHash + LSH Implementation

```python
# minhash.py
import hashlib
import random

class MinHash:
    def __init__(self, num_permutations=128):
        self.num = num_permutations
        self.minhashes = [float('inf')] * num_permutations
    
    def update(self, text):
        tokens = text.lower().split()[:100]  # Top-100 tokens
        for token in tokens:
            h = int(hashlib.md5(token.encode()).hexdigest(), 16)
            for i in range(self.num):
                self.minhashes[i] = min(self.minhashes[i], h % (2**32))
    
    def distance(self, other):
        matches = sum(1 for a, b in zip(self.minhashes, other.minhashes) if a == b)
        return matches / self.num  # Jaccard similarity

class LSH:
    def __init__(self, minhashes, threshold=0.8):
        self.minhashes = minhashes
        self.threshold = threshold
    
    def query(self, minhash):
        bands = 4
        band_size = len(minhash.minhashes) // bands
        key = tuple(minhash.minhashes[i:i+band_size] for i in range(0, len(minhash.minhashes), band_size))
        
        results = []
        for doc_minhash in self.buckets[key]:
            if minhash.distance(doc_minhash) >= self.threshold:
                results.append(doc_minhash)
        return results
```

### SQLite FTS5 Implementation

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

---

*Трекер создан: 2026-06-27*  
*Версия схемы: 9*