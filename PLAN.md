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
| 7.2 | Integration in process-ingest.json | ✅ Done | pending |
| 6.1 | Search history + auto-save (`meta/search_history.json`) | ✅ Done | pending |
| 6.2 | Context-aware search bias (`wiki-search.sh` Phase 6) | ✅ Done | pending |

**Canonical sources**: All scripts in `scripts/`, process files reference them via `schema_ref`.

---

## 🟡 Pending Phases (sorted by priority)

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

1. **Phase 8: detect-contradications.sh** — реализация auto-contrast scan
2. **Issue #4** — Authoritative Sources Criteria (see [issues.md](issues.md))
3. **AGENTS.md Phase 5 section** — missing link in Schema (checked, needs update)

### 🧠 Future Architecture Discussions (Phase 6 extensions)
See [PLAN_PHASE_6_FUTURE.md](PLAN_PHASE_6_FUTURE.md) for:
- Context bubbles (3 active pages strategy)
- Wiki as swap space for context overflow  
- Relevance markers + auto-compaction rules
- Topic reset triggers

---

## 🔄 Update Rules

- После каждой реализации → обновлять этот файл + git commit `schema | phase X completed`
- Устаревшие детали удалять при следующем чистке
- Live issues tracked in [issues.md](issues.md) — не дублировать здесь
- **Rule**: new phases sorted by priority (High → Medium → Low)

*Last update: 2026-06-27 | Phases 1-5, 6.1+6.2, 7.1+7.2 done; Phase 8 pending.*

### Phase 8: Contradiction Deep Scan — Medium Priority ✅ Done 🆕
**Цель**: Автоматизировать deep comparison фактов из разных страниц (версии, цифры, даты).

| Шаг | Что | Файл | Приоритет |
|-----|-----|------|-----------|
| 8.1 | `scripts/detect-contradications.sh` — Python-based deep scan | ✅ Done | ✅ Complete |
| 8.2 | Интегрировать в lint.sh (check_id=8) | ✅ Done in lint.sh | ✅ Complete |


*Last update: 2026-06-27 | Phases 1-5, 6.1+6.2, 7.1+7.2, 8 done.*
