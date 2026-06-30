# PLAN: Wiki Improvement Roadmap

---

## ✅ Completed (reference only)

| Phase | Feature | Commit |
|-------|----------|--------|
| 1-5 | Auto-rebuild meta, smarter search, non-blocking lint, index update, dynamic scoring | `1990a20` |
| 8 | Contradiction Deep Scan (Python-based) | `c368411` |
| 10 | Evidence-Based Priority System + frontmatter schema | `581b115` |
| 11.1 | Syndication Detection — `text-similarity.sh` | `258fa2c` |
| 12.1 | Decision Rules Framework — DR-1/DR-2/DR-3 | `c368411` |
| IF-1..IF-4 | Integration hooks: lint check_id=9, process refs, step_3c ingest scan | `b824a7` |
| S5 | Search analytics — async query frequency logging (`meta/search_analytics.json`) | `94c4fbe` |

**Resolved from 06-28 audit**: P1 (shebangs), P2 (atomic writes), P3 (tests), P4 (error handling),
P5 (temp files), P6 (link validator limit), P7 (path guardrails), P9 (debug prints),
P12 (logging standard), P13 (trap handlers), P15 (minor fixes).

**Resolved from 06-28 session**: P8/#21 (heredoc injection → env var passing), #H3 (system file exclusion in detect-contradications), Phase 12.3 D6 (rebuild-meta auto-trigger after link-fix).

---

## ⬜ Unresolved — From 06-28 Audit

### Script fixes needed

| ID | Issue | Plan | Priority |
|----|-------|------|----------|
| **Phase 11.2** | Causal Chain Analysis | After schema migration → future priority | 🟡 Low |

### Deferred (strategic)

| ID | Issue | Status |
|----|-------|--------|
| **P10** | Redundant wiki walks — 3 full walks per ingest, can be unified | Large refactor → deferred | ⬜ Deferred |
| **P11** | Manual JSON construction in bash scripts (`echo/printf` vs `jq`) | Scripts already use `json.dump()` for complex output; only echo-level needs migration | ⬜ Deferred |
| **P14** | Scripts documentation — no unified docs for 15+ scripts | Nice-to-have → deferred to onboarding work | ⬜ Deferred |

---

## 🔄 Pending Feature Phases (from original roadmap)

### Phase 11.2: Causal Chain Analysis
**Цель**: Agent prompt для "X wrote first, Y copied from X" — causal chain analysis на основе overlap данных из text-similarity.sh
**Приоритет**: Low (after schema migration + issue fixes)

### Phase 13: Wiki Page Templates Schema (#H4)
**Цель**: Единый, полный, не-разрозненный набор per-type format descriptions для всех типов wiki pages.
**Связан с**: `issues.md#H4`
**Проблемы:**
- Битые refs в AGENTS.md → process-ingest.json
- Нет per-type structure descriptions (Entity/Concept/Synthesis/Comparison/Notes)
- Summary pages: правила создания есть, но нет описания структуры страницы
- Фактические wiki-файлы показывают consistent patterns, но они не задокументированы

**Discussion context:** `context.md` — фиксация решений по Q1-Q4 (universal vs type-specific templates, summary structure, section naming, comparison format).

**Задачи:**
1. Убрать битые refs из AGENTS.md#page_templates
2. Добавить inline per-type structure descriptions в AGENTS.md (вместо process-ingest.json refs)
3. Зафиксировать фактические patterns: frontmatter → ## Контекст → ## Анализ → ## Выводы → ## Связи
4. Добавить Summary page structure description (sections, frontmatter type=faq_summary rules)
5. Обновить process-ingest.json step 3a/3b с конкретными секциями для каждого типа
**Приоритет**: Medium — требуется before any new ingest or synthesis creation

### Phase 12.2: Auto-Extract Assumptions
**Цель**: Агент автоматически экстрагирует assumptions из источников (источники с weak evidence помечать)
**Приоритет**: Future

---

## 🔄 Pending Phases

| Phase | Description | Priority |
|-------|-------------|----------|
| **S5** | Search analytics → popularity boost in `score_page()`. Read meta/search_analytics.json → add +frequency_boost to pages that appeared in popular queries. Soft signal only — never filters results. | High |
| **Local Indexes** | `index.md` в каждой категории для линейного поиска вместо O(n²) + root index → краткий формат (categories + links only). **Depends**: F1 research on unique file naming before implementation. | High |
| Graph-Based Crosslinks | `auto-crosslink.sh` rewrite с shared-source analysis и scoring | Medium |
| Wiki Scalability (1000+ pages) | Optimizations: ripgrep, incremental rebuild, skip full rebuild >100 pages | Medium |

---

## 📝 Future Improvements (linked to issues.md)

| ID | Issue ID | Description | Status |
|----|----------|-------------|--------|
| F1 | #F1 (issues.md) | Root index format: `wiki/index.md` → краткий (categories + links). Research Wikipedia naming conventions + unique file naming rules. | 📝 Planning — discussion required |
| F2 | #F2 (issues.md) | Local indexes in every category folder with keywords/tags/first sentences. Requires rebuild-meta.sh update. | 📝 Planned — depends on F1 research |

> **Note**: Файл `h1-index.py` + `rebuild-meta.sh` генерируют index.md автоматически, не вручную агентом.

---

## ✅ Schema Migration — Dialog.md → AGENTS.md + process-файлы (Phase 12.4)

**Status**: ✅ **COMPLETED** (06-29) — all rules embedded in AGENTS.md / process files.
> Note: `dialog.md` has been removed after migration. All references are now inline/embedded in target files.

### Completed actions:
| Step | Action | Result |
|------|---------|--------|
| D1-D2 | Link Conventions + EXT-LINK-V1 embedded, DR-EX1 removed | AGENTS.md updated |
| D3 | fetch_content_truncation.secondary_action cleaned (raw hierarchy example removed) | AGENTS.md cleaned |
| D4 | ZONE-DEF1 + META-DEF1 added to Protected Zones | AGENTS.md updated |
| D5 | EXT-RES1 embedded in process-ingest.json (EXT-1..EXT-4 merged into single rule) | process-ingest.json updated |
| D6 | BROKEN-REF1-v3 embedded, schema_ref fixed | process-query.json updated |
| D7 | check_id=7 reference fixed, fuzzy_matching removed from inline logic | process-lint.json updated |
| D8 | DUAL-MODE-LINT-1 modes added to lint_checks | process-lint.json updated |

### Cross-category exception:
- `../` allowed for cross-category wiki links (e.g. concepts/ ↔ syntheses/) as long as target exists under wiki/
- Updated in AGENTS.md Link Conventions section.


---

---

*Last update: 2026-06-29 | Schema migration plan corrected — Phase 12.4. All rules embedded, NOT referenced via schema_ref. Future improvements tracked (F1-F2 linked to issues.md).*
