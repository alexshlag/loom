# Research 2 — Comparative Studies

## [2026-06-30] Ingest Workflow Comparison: Claude-obsidian vs Loomana

**Цель**: Изучить ingest архитектуру claude-obsidian и выявить заимствуемые решения.

**Найдено**: Dual-path ingest (URL → `.raw/articles/`, autoresearch → direct-to-wiki), mode-based routing через Python script, transport abstraction layer (CLI→MCP→filesystem), advisory file locking с flock.

**Ключевые заимствования для Loomana**:
- Mode-based routing → `wiki-mode.py` для маршрутизации по категориям
- Transport abstraction → fallback chain для future MCP support  
- Advisory locking → `scripts/wiki-lock.sh` для safe concurrent writes
- Delta tracking → `.raw/.manifest.json` аналог для skip unchanged sources
- Image ingestion pipeline → `.raw/images/` + `_attachments/`

**Результат**: Создана wiki страница [ingest-workflow-comparison](../wiki/concepts/ingest-workflow-comparison.md)

---

*Первое исследование — сравнение ingest архитектур.*
