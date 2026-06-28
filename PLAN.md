# PLAN: Wiki Improvement Roadmap

---

## ✅ Completed Phases & Fixes

| Phase | Feature | Status | Commit |
|-------|----------|--------|--------|
| 1-5 | Auto-rebuild meta, smarter search, non-blocking lint, index update, dynamic scoring | ✅ Done | `1990a20` |
| 8 | Contradiction Deep Scan (Python-based) | ✅ Done | `c368411` |
| 10 | Evidence-Based Priority System — cascade (`code > live > docs`) + frontmatter schema | ✅ Done | `581b115` |
| 11.1 | Syndication Detection — `text-similarity.sh` (n-gram pairwise scan) | ✅ Done | `258fa2c` |
| 12.1 | Decision Rules Framework — DR-1/DR-2/DR-3 in AGENTS.md | ✅ Done | `c368411` |
| IF-1..IF-4 | Integration hooks: lint check_id=9, process refs, step_3c ingest scan | ✅ Done | `b824a7` |

---

## 🟡 Remaining Work

### Phase 11.2: Causal Chain Analysis
**Цель**: Agent prompt для "X wrote first, Y copied from X" — causal chain analysis на основе overlap данных из text-similarity.sh
**Приоритет**: Low

### Phase 12.2: Auto-Extract Assumptions
**Цель**: Агент автоматически экстрагирует assumptions из источников (источники с weak evidence помечать)
**Приоритет**: Future

---

## 🔄 Pending Phases

| Phase | Description | Priority |
|-------|-------------|----------|
| Local Indexes | `index.md` в каждой категории для линейного поиска вместо O(n²) | High |
| Graph-Based Crosslinks | `auto-crosslink.sh` rewrite с shared-source analysis и scoring | Medium |
| Wiki Scalability (1000+ pages) | Optimizations: ripgrep, incremental rebuild, skip full rebuild >100 pages | Medium |

---

*Last update: 2026-06-28 | All phases 1-5, 8-12 complete. IF-1..IF-4 integrated.*
