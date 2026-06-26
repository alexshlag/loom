# PLAN: Wiki Improvement Roadmap (2026-06-26)

---

## ✅ Completed Phases

| Phase | Feature | Status | Commit |
|-------|---------|--------|--------|
| 1 | Auto-rebuild meta (`rebuild-meta.sh`) | ✅ Done | `c368411` |
| 2 | Smarter search (priority categories) | ✅ Done | `664358e` |
| 3 | Non-blocking lint (`lint.sh`) | ✅ Done | `c368411` |
| 4 | Auto-update index.md (`--index-only`) | ✅ Done | `f362a2d` |
| 5 | Dynamic priority + relevance scoring | ✅ Done | `1990a20` |

**Canonical sources**: All scripts in `scripts/`, process files reference them via `schema_ref`.

---

## 🟡 Pending: Phase 6 — Search Context Awareness

**Цель**: Сохранять search history → adapt priority queue based on recent queries.

| Шаг | Что | Файл |
|-----|-----|------|
| 6.1 | `meta/search_history.json` format + auto-save | New file |
| 6.2 | Context-aware query rewriting (bash: read history → bias priority) | `scripts/wiki-search.sh` |
| 6.3 | Integrate into process-query.json step before search | `process-query.json#context_bubble` |

**Приоритет**: Medium. Не блокирует работу, но повышает качество поиска.

---

## 📋 Next Actions

1. **Phase 6 implementation** — pending user approval
2. **Issue #4** — Authoritative Sources Criteria (see [issues.md](issues.md))
3. **AGENTS.md Phase 5 section** — missing link in Schema (checked, needs update)

---

## 🔄 Update Rules

- После каждой реализации → обновлять этот файл + git commit `schema | phase X completed`
- Устаревшие детали удалять при следующем чистке
- Live issues tracked in [issues.md](issues.md) — не дублировать здесь

*Last update: 2026-06-26 | Phases 1-5 done, Phase 6 pending.*
