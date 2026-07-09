# Schema Ref Examples — Broken Link Fixing Practice

## Practical examples (extracted from RULES.md for compactness)

### 1. raw_corrected_zone (исправлено)
- Было: `schema_ref: AGENTS.md#raw_corrected_zone` → битая ссылка
- Найдено: `rules/protected_zones.json` содержит правила доступа к зонам
- Действие: Исправить на `rules/protected_zones.json`

### 2. batch_ingest_trigger (исправлено)
- Было: `schema_ref: AGENTS.md#batch_ingest_trigger` → битая ссылка
- Найдено: правила перенесены в `rules/batch_ingest_trigger.json`
- Действие: Исправить на `rules/batch_ingest_trigger.json`

### 3. link-conventions (исправлено)
- Было: `schema_ref: rules/link-conventions` → неправильное имя файла
- Реальное имя: `rules/link_conventions.json` (с дефисом в названии)
- Действие: Исправить путь

### 4. Delta Tracking (удалено)
- Реализовано в `scripts/rebuild-source-manifest.sh`
- Было: `schema_ref: AGENTS.md#delta_tracking` → **Удалено**
- Причина: скрипт сам является документацией
