# PLAN: Wiki Improvement Roadmap (2026-06-26)

---

## ✅ Completed Phases

| Phase | Feature | Status | Commit |
|-------|---------|--------|------|
| 1 | Auto-rebuild meta (`rebuild-meta.sh`) | ✅ Done | `c368411` |
| 2 | Smarter search (priority categories) | ✅ Done | `664358e` |
| 3 | Non-blocking lint (`lint.sh`) | ✅ Done | `c368411` |
| 4 | Auto-update index.md (`--index-only`) | ✅ Done | `f362a2d` |
| 5 | Dynamic priority + relevance scoring | ✅ Done | `1990a20` |
| 7.1 | Auto-crosslink script (`auto-crosslink.sh`) | ✅ Done | pending |

**Canonical sources**: All scripts in `scripts/`, process files reference them via `schema_ref`.

---

## 🟡 Pending Phases (sorted by priority)

### Phase 6: Search Context Awareness — High Priority
**Цель**: Сохранять search history → adapt priority queue based on recent queries.

| Шаг | Что | Файл |
|-----|-----|------|
| 6.1 | `meta/search_history.json` format + auto-save | New file |
| 6.2 | Context-aware query rewriting (bash: read history → bias priority) | `scripts/wiki-search.sh` |
| 6.3 | Integrate into process-query.json step before search | `process-query.json#context_bubble` |

### Phase 7: Auto-crosslink — High Priority 🆕
**Цель**: Автоматизировать cross-linking после создания новой страницы (agent grep вручную → скрипт).

| Шаг | Что | Файл | Приоритет |
|-----|-----|------|-----------|
| 7.1 | `scripts/auto-crosslink.sh` — парсит H1, grep по всем wiki на упоминания | ✅ Done (tested) | ✅ Complete |
| 7.2 | Интегрировать в process-ingest.json post_check (auto-update existing pages) | In progress | Medium |

### Phase 8: Contradiction Deep Scan — Medium Priority 🆕
**Цель**: Автоматизировать deep comparison фактов из разных страниц (версии, цифры, даты).

| Шаг | Что | Файл | Приоритет |
|-----|-----|------|-----------|
| 8.1 | `scripts/detect-contradications.sh` — парсит frontmatter.date + ключевые факты, строит матрицу | New script | Medium (soft check) |
| 8.2 | Интегрировать в process-query.json step 2 (pre-synthesis check) | `process-query.json#synthesis` | Low |

### Phase 9: Summary Extraction → WM — Low Priority 🆕
**Цель**: Автоматизировать извлечение key_facts + contradictions для working_memory.

| Шаг | Что | Файл | Приоритет |
|-----|-----|------|-----------|
| 9.1 | `scripts/extract-summary.sh` — H1 + first 3 sentences → structured JSON | New script | Low (token saving) |

---

## 📋 Next Actions

1. **Phase 7.2: Интеграция в process-ingest.json** — auto-update existing pages после создания новой
2. **Phase 6 implementation** — pending user approval
3. **Issue #4** — Authoritative Sources Criteria (see [issues.md](issues.md))
4. **AGENTS.md Phase 5 section** — missing link in Schema (checked, needs update)

---

## 🔄 Update Rules

- После каждой реализации → обновлять этот файл + git commit `schema | phase X completed`
- Устаревшие детали удалять при следующем чистке
- Live issues tracked in [issues.md](issues.md) — не дублировать здесь
- **Rule**: new phases sorted by priority (High → Medium → Low)

*Last update: 2026-06-27 | Phase 7.1 done, 7.2 integration in progress.*
