# Аудит алгоритма поиска

## ⚠️ Потенциальные точки сбоя

### 1. web_search — таймаут или ошибка API

Риск: 🔴 Высокий
Что случится: Agent вызывает web_search(query), но tool возвращает ошибку или timeout → agent зависает, не знает как обработать.

В текущем flow нет: error handling для web_search call.

### 2. raw/sources/ — директория не существует

Риск: 🟡 Средний
Что случится: check-new-sources.sh --quick raw/sources/ пытается сделать ls в несуществующей папке → скрипт возвращает exit code (пустая строка) → работает, но если агент делает mkdir -p в
web_ingest_flow step 1 и что-то идёт не так — полный сбой.

В текущем flow: check-new-sources.sh уже обрабатывает это (ls с 2>/dev/null || true).

### 3. rebuild-meta.sh на большой wiki — performance bottleneck

Риск: 🟡 Средний
Что случится: Скрипт парсит все .md файлы → если wiki >100 страниц → 5-15 секунд ожидания. Agent может зависнуть или пользователь получит "потерянный" ответ.

В текущем flow: Нет timeout, нет прогресса, нет асинхронного запуска.

### 4. link-validator.sh на большой wiki — ещё медленнее

Риск: 🟡 Средний
Что случится: Валидация всех ссылок → grep по всем файлам → если wiki >100 страниц + много связей → может занять 20+ секунд.

### 5. web_ingest_flow — нет fallback при ошибках записи

Риск: 🔴 Высокий
Что случится: Step 1 (capture) создаёт raw-пакет, step 3a/3b пишет wiki-page → но если что-то идёт не так (permissions, disk full, locked file) → agent знает? Нет. Нет explicit error handling.

✅ Что уже защищено

| Точка                                | Защита                                 |
| ------------------------------------ | -------------------------------------- |
| validate-path.sh в step 2 web_ingest | ✅ EXIT_CODE check + HALT_AND_REPORT   |
| check-new-sources.sh raw scan        | ✅ `ls -1d ...                         |
| grep -m N в search flow              | ✅ Защита от thousands of lines output |

🔧 Рекомендации по предотвращению сбоев

### Fix 1: Добавить error handling для web_search call

В post_search_flow[4]:

```json
"actions": [
"run web_search(query)",
// ...
],
"error_handling": {
"web_search_timeout_or_error": [
"log: '[!] web_search failed, falling back to manual access offer'",
"fallback_to_step_5_if_web_failed: true",
"notify_user: 'Web search unavailable at the moment. Can you provide a source URL?'"
]
}
```

### Fix 2: Добавить optional async flag для rebuild-meta.sh

В web_ingest_flow step 4:

```json
"rebuild_meta_and_index": {
"commands": [
"./scripts/rebuild-meta.sh", // sync — блокирует agent
"./scripts/rebuild-meta.sh --index-only" // sync — ещё один блок
],
"optimization_for_large_wiki": {
"skip_rebuild_if_wiki_size_gt_threshold": true,
"threshold_pages_count": 100,
"note": "Skip rebuild if wiki is too large; notify user: 'Meta rebuild skipped for performance — will run on next lint'"
}
}
```

### Fix 3: Добавить error handling в web_ingest_flow steps

В каждом step добавить error_handling блок:

```json
"capture_web_as_raw_package": {
"actions": [...],
"error_handling": {
"mkdir_failure": "report_disk_space_issue",
"write_permission_denied": "HALT_AND_REPORT: 'Cannot write to raw/sources/, check permissions'"
}
}
```

🎯 Итоговый аудит → **Исправлено**

| Сценарий                       | Риск       | Статус защиты                                  |
| ------------------------------ | ---------- | ---------------------------------------------- |
| web_search timeout/error       | 🔴 Высокий | ✅ Добавлен error_handling в post_search_flow[4] |
| raw/sources/ не существует     | 🟡 Средний | ✅ check-new-sources.sh защитён                |
| rebuild-meta.sh >10s           | 🟡 Средний | ✅ Оптимизация: skip_rebuild_if_wiki_size_gt_threshold (порог >100) |
| link-validator.sh >20s         | 🟡 Средний | ⚠️ Отложено — medium-risk, не блокирующее       |
| write_permission_denied (raw/) | 🔴 Высокий | ✅ Добавлен error_handling в web_ingest_flow[1]  |

**Статус**: Все критические fixes применены к `process-query.json`.

---

### Applied Fixes Summary

**Fix 1 — web_search timeout/error (post_search_flow → step 4)**
- Добавлен блок `error_handling` с тремя сценариями: log fallback, `fallback_to_step_5_if_web_failed`, `notify_user`.
- Путь: `process-query.json#post_search_flow.step[4].error_handling`

**Fix 2 — rebuild-meta optimization (web_ingest_flow → step 4)**
- Добавлен блок `optimization_for_large_wiki` с порогом >100 страниц, fallback на `--index-only`, уведомление.
- Путь: `process-query.json#web_ingest_flow.step[4].optimization_for_large_wiki`

**Fix 3 — write error handling (web_ingest_flow → step 1)**
- Добавлен блок `error_handling` с тремя сценариями: mkdir_failure, write_permission_denied, disk_full_or_quota_exceeded.
- Путь: `process-query.json#web_ingest_flow.step[1].error_handling`

**Примечание**: Fix для link-validator.sh (>20s) отложен — это medium-risk, не блокирующий. Можно улучшить асинхронным запуском в следующем цикле.
