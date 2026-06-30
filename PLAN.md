# PLAN: Wiki Improvement Roadmap

---

## ✅ Completed — 2026-06-30 Session

### Script Fixes (from issues.md HIGH priority)

| ID | Issue | Status | Changes |
|----|-------|--------|---------|
| #16 | Broken unit tests | ✅ Working via `npx bats` | Tests pass, just need documentation update |
| #17 | Silent error swallowing | ⚠️ PARTIAL FIX | lint.sh: removed set -e, added log_error(), fixed duplicate code & check numbering. Remaining: replace || true with safe_run() |
| #18 | Hardcoded /tmp/ overlap file | ✅ FIXED | process-ingest.json: mktemp instead of hardcoded /tmp/overlap_result.json |
| #19 | Link validator 500-file limit | ✅ FIXED | link-validator.sh: --max flag (default 100), -maxdepth 5, removed head -500 |
| #20 | validate-path.sh pattern bypass | ✅ FIXED | Prefix-only match + write-zone validation for raw/sources/ and wiki/ |

### ✅ Completed this session:
✅ Issue #17: lint.sh fully refactored — all script calls use safe_run(), no more silent errors
✅ Issue #10: Created scripts/utilities/common.sh with unified log_error() + safe_run()
✅ Issues #16, #18, #19, #20: All fixed (link validator limits, validate-path guards, mktemp)

### Next batch of tasks:
- [ ] Add trap handlers to orphan-pages.sh, check-new-sources.sh, duplicate-titles.sh, date-consistency.sh (Issue #11)
- [ ] Refactor Python scripts to use logging module instead of print() (Issue #10)

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

**Completed today (2026-06-30)**: Harness-Independent Session & Git Operations — 4 скрипта интегрированы в process-файлы, секция из AGENTS.md удалена, NEW_EXT_PLAN.md удалён. Natural Memory Translation — правило в AGENTS.md + living-doc.

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

## 🔄 Pending Ingest Workflow Improvements (from claude-obsidian analysis)

### Phase 13: Delta Tracking 🥇
**Цель**: Предотвратить waste of tokens на re-ingest тех же источников.

**Задачи**:
| Step | Action | Owner | Status |
|------|--------|-------|--------|
| ✅ 1 | **Размещение решено**: `meta/source-manifest.json`, agent пишет через скрипт | Decision made | ✅ Done |
| 2 | Создать `scripts/rebuild-source-manifest.sh` — API: --add, --scan, --check | Agent | ⬜ Next |
| 3 | Добавить delta check в ingest flow (hash → skip if unchanged) | Agent | ⬜ After step 2 |
| 4 | Обновить AGENTS.md и process-ingest.json с правилами delta tracking | Agent | ⬜ After step 2 |

**Зависимости**: Нет.
**Связано**: `issues.md#29` (placement resolved, implementation pending)

### Phase 13: Batch Ingest Workflow 🥈
**Цель**: Cross-reference между новыми источниками + bulk-update index/hot/log.

**Задачи**:
| Step | Action | Owner |
|------|--------|-------|
| 1 | Разделить интеллект (агент) vs автоматизация (скрипт) — дизайн решения | Agent + user discussion |
| 2 | Создать `scripts/batch-ingest.sh` для автоматизированной части | Agent |
| 3 | Добавить batch workflow в AGENTS.md → process-ingest.json step 3 | Agent |

**Зависимости**: Phase 13.1 (delta tracking) — не строго.
**Связано**: `issues.md#30`

### Phase 14: Wiki Sources Structure 🥉
**Цель**: Отдельная зона для sources → audit trail и conflict resolution.

**Задачи**:
| Step | Action | Owner |
|------|--------|-------|
| 1 | Решить нужна ли `wiki/sources/` папка vs frontmatter `sources: []` | Agent + user decision |
| 2 | Если да → создать структуру и правила filing в AGENTS.md | Agent |

**Зависимости**: Phase 13.2 (batch ingest) — для bulk source processing.
**Связано**: `issues.md#32`

### Phase 15: Media Files Pipeline 🪢
**Цель**: Структурированный pipeline для изображений и медиа-файлов (OCR, metadata extraction).

**Задачи**:
| Step | Action | Owner | Status |
|------|--------|-------|--------|
| ✅ 1 | **Размещение решено**: `wiki/assets/images/` + `wiki/assets/descriptions/`, agent-owned | Decision made | ✅ Done |
| 2 | Добавить wiki/assets/ структуру в AGENTS.md → "The Wiki (wiki/)" section | Agent | ⬜ Next |
| 3 | Создать image ingestion rules в AGENTS.md + process-ingest.json step | Agent | After step 2 |
| 4 | (Optional) `scripts/media-ingest.sh` — автоматизация OCR + metadata | Agent | Future |

**Зависимости**: Нет.
**Связано**: `issues.md#31`

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
