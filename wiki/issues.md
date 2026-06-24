# Wiki Issues — Результаты lint-проверки

## Дата проверки: 2026-06-24

... (предыдущие пункты остаются без изменений) ...

## 🛠 Systemic Architecture Issues (Audit 2026-06-24)

| Issue ID | Description | Status |
|----------|-------------|--------|
| **#7** | **Cross-Context Lint Triggering**: Текущая система триггеров не позволяет вызывать `process-lint.md.json` из разных контекстов (query, ingest и т.д.) эффективно. Требуется глобальное правило в `AGENTS.md` для обеспечения надежной связи между смысловыми запросами пользователя («проверь порядок», «аудит») и линтовыми проверками. | **Pending** |

---

*Создано: 2026-06-24 | Status: Issues identified | Last commit: [current_timestamp]*
