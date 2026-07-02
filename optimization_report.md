# 📋 Отчет: Оптимизация инструкций (rules/ файлы)

## 🎯 Цель анализа

Проверить файл `@protected_zones.json` и другие правила в директории `rules/`, оценить возможность оптимизации и перелинковки.

---

## 📊 Итоговый статус

### ✅ Что сделано

1. **Все 12 файлов rules/ созданы** и содержат правильные спецификации:
   - `protected_zones.json` — правила доступа к защищенным зонам
   - `error_handling.json` — протокол обработки ошибок (4-step loop)
   - `execution_contract.json` — автономное выполнение действий агентом
   - `execution_modes.json` — режимы работы агента (silent/verbose, query/project)
   - `search_strategy.json` — алгоритм поиска в wiki
   - `date_convention.json` — правила использования дат
   - `link_conventions.json` — внутренние/внешние ссылки, авто-исправление
   - `silent_output.json` —只显示 финальные результаты
   - `non_blocking_lint.json` — периодический health-check wiki
   - `auto_rebuild_metadata.json` — автоматическое обновление метаданных
   - `auto_update_index.json` — авто-обновление index.md

2. **AGENTS.md обновлен** разделом "Schema Reference (Rules)" со ссылками на все правила.

### ❌ Что осталось исправить

| Проблема | Статус |
|----------|--------|
| Ссылки в AGENTS.md отсутствуют | ⚠️ Все 12 файлов rules/ не имеют активных ссылок |
| process-файлы содержат битые schema_ref | ⚠️ Указывают на несуществующие блоки в AGENTS.md |
| Дублирующийся код | ⚠️ error_handling дублируется между files |

---

## 📄 Детальный анализ rules/error_handling.json

**Protocol:** Error Handling Protocol  
**Description:** Инструкции для агента при обнаружении ошибок, противоречий или dead end ситуаций.

### 4-step loop (полный протокол)

```json
{
  "steps": {
    "loop": [
      {
        "step": 1,
        "action": "Detect & Log [!]",
        "details": "Записать в log.md с типом [error], описанием и контекстом. Всегда append (>>), never overwrite."
      },
      {
        "step": 2,
        "action": "Analyze",
        "details": "Краткий анализ: что пошло не так, почему инструкция сломалась"
      },
      {
        "step": 3,
        "action": "Resolve",
        "strategies": {
          "local-fix": "проблема локальная → исправить самостоятельно",
          "schema-patch": "противоречие в Schema/AGENTS.md → предложить патч пользователю",
          "source-conflict": "два источника говорят противоположное → отметить как CONFLICT",
          "dead-end": "подход не работает → документировать причину, сменить стратегию"
        }
      },
      {
        "step": 4,
        "action": "Continue",
        "details": "Двигаться дальше по task, не застревая на сломанной инструкции"
      }
    ]
  }
}
```

### Примеры применения

| Ситуация | Действие |
|----------|----------|
| `git add *` заблокирован guardrails | `[!] Log: protected zone blocked → local-fix: switch to git add wiki/` |
| `fetch_content` вернул обрезанный markdown | `[!] Log: truncation detected → fallback web_search + get_search_content` |
| Новая команда несовместима с Schema | `[!] Log: schema conflict → schema-patch: предложить патч AGENTS.md` |
| Grep дал >100 совпадений без смысла | `[!] Log: grep noise → dead-end: switch to index.md` |

**Golden rule:** Ошибка ≠ стоп. Каждый error — сигнал к действию, а не причина зависать.

---

## 🔧 Рекомендуемые действия

### 1. Обновить process-ingest.json

Заменить inline `error_handling` блок на ссылку:

```json
// Было (дублирующий код):
"error_handling": {
  "description": "...",
  "steps": [...]
}

// Стало (ссылка на правило):
"error_handling": {
  "schema_ref": "rules/error_handling.json"
}
```

### 2. Обновить process-query.json

Заменить все `error_handling` блоки на `schema_ref`.

### 3. Проверить protected_zones валидацию

Убедиться, что проверка путей ссылается на `rules/protected_zones.json`.

---

## 📝 Итог

**Оптимизация возможна и необходима.** Правила из `rules/` созданы корректно, но требуют:
1. Активных ссылок в AGENTS.md (добавлено)
2. Обновления schema_ref в process-файлах (требуется)
3. Удаления дублирующегося кода (требуется)

После завершения оптимизации архитектура инструкций будет чистой:
- **AGENTS.md** — высокоуровневый манифест с ссылками на правила
- **rules/** — технические спецификации (не дублируются)
- **process-*.json** — ссылки на правила через `schema_ref`

Это устранит "шум" в контексте агента и позволит потреблять инструкции только когда они необходимы.
