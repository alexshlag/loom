### Phase 14: Schema Optimization & Architecture Refinement 🆕
**Цель**: Реализация рекомендаций по упрощению манифеста и разделению данных (Architecture Refinement).
**Этапы:**
1. **Conceptual Grouping**: Объединение разрозненных архитектурных слоев (Raw, Wiki, Assets) в единый блок "Knowledge Architecture".
2. **Error Handling Abstraction**: Замена детальных описаний каждой ошибки в AGENTS.md на высокоуровневую стратегию "Detect → Log → Resolve → Continue", со ссылками на `process-*.json`.
3. **Technical Detail Extraction**: Вынос специфических технических правил (например, детали парсинга JSON или специфических флагов bash) в директорию `rules/` (например, `rules/lint_details.json`).
4. **Verification**: Проверка того, что агент сохраняет способность выполнять сложные операции, несмотря на упрощение описаний.

**Статус:** ⬜ Open — планируется обсуждение и утверждение этапов.
**Связь**: `issues.md#33`

---

## ✅ Completed — 2026-07-01 Session

### Phase 13.3: Schema References Migration Fix ✅ COMPLETED
**Цель**: Устранить broken schema_refs в process-query.json, process-ingest.json, process-lint.json.

**Результат:**
| Step | Task | Status |
|------|------|--------|
| **1** | Добавить 6 missing headings в AGENTS.md | ✅ Done |
| **2** | Заменить broken schema_ref → note в process-query.json (2 refs) | ✅ Done |
| **3** | Заменить broken schema_ref → note в process-ingest.json (2 refs) | ✅ Done |
| **4** | Исправить JSON corruption в process-lint.json (2 refs + trailing commas) | ✅ Done |

**Связано**: `issues.md#37`, `issues.md#38`

---

### Phase 13.2: Batch Ingest Workflow ✅ COMPLETED (2026-07-01)
**Цель**: Cross-reference между новыми источниками + bulk-update index/hot/log.
**Статус:** Завершён, задачи перенесены в issues.md как resolved. Связано: `issues.md#30`

---

### Phase 29: Delta Tracking — Implementation Plan ✅ COMPLETED (2026-07-01)
**Цель**: Реализовать delta tracking через `scripts/rebuild-source-manifest.sh` для предотвращения re-ingest duplicate sources.

**Архитектура:**
```bash
# Layer 1: Originals (immutable)
raw/SRC-*/original.md

# Layer 2: Delta manifest (agent writes via script only)
meta/source-manifest.json — hash-based tracking, rebuilt by scripts/rebuild-source-manifest.sh

# Layer 3: Wiki pages reference corrected copies
wiki/**/*.md: sources: ["raw/corrected/SRC-*/file.md"]
```

**Этапы реализации:**
| Step | Task | Status | Details |
|------|------|--------|---------|
| **1** | API design `scripts/rebuild-source-manifest.sh` | ✅ Done | --add <path> content, --scan, --check <path>, hash_original + status:processed |
| **2** | Update `validate-path.sh`: add raw/corrected/ to ALLOWED_WRITE_ZONES | ✅ Done (Phase 23) | Script bypasses guardrails internally via validate_path() check |
| **3** | Create `scripts/raw-correct.sh` safe write wrapper | ✅ Done (Phase 23) | Validates path prefix, JSON format for .json files |
| **4** | Update process-ingest.json: add post-processing step after capture | ✅ Done | Step 4 (step_4_corrected_copy): agent reads original → creates corrected copy in raw/corrected/ + delta check Step 2 (step_2_delta_check) |
| **5** | Update AGENTS.md: delta tracking integration rules | ✅ Done (Phase 23) | Document manifest.json generation + contradiction resolution flow |

**Зависимости:** Sequential (1→2→3→4→5). Все шаги завершены.

**Результат:**
| Component | Status | Notes |
|-----------|--------|-------|
| `scripts/rebuild-source-manifest.sh` | ✅ Created | Python-based, handles hash comparison and manifest generation |
| `scripts/raw-correct.sh` | ✅ Exists | Safe write wrapper with path validation |
| `validate-path.sh` | ✅ Updated | raw/corrected/ in ALLOWED_WRITE_ZONES |
| process-ingest.json Step 2 (step_2_delta_check) | ✅ Added | Hash-based deduplication before ingest |
| process-ingest.json post_operations (Step 3a/3b) | ✅ Updated | Rebuild manifest after page creation/update |

**Backfill Detection & Flow (Phase 29 extension):**
| Component | Status | Notes |
|-----------|--------|-------|
| process-lint.json check_id=12 | ✅ Added | Source manifest backfill detection — scans unprocessed/stale + wiki references |
| process-ingest.json cross_process_triggers (backfill_existing_wiki_references) | ✅ Added | Backflow for existing wiki pages referencing raw/sources/ without corrected copies. Триггерится из process-lint.json, не входит в ingest flow. |
| All sources backfilled | ✅ Done (2026-07-01) | SRC-2025-06-24-002 (2 pages), SRC-2026-06-25-SYMFONY-001 (15+ pages) — corrected copies created + frontmatter updated |

> **Canonical:** `AGENTS.md#raw_corrected_zone` — canonical source for raw/corrected/ zone rules.
> **Schema refs:** `process-ingest.json#step_2_delta_check`, `process-lint.json#check_id_12`, `process-ingest.json#cross_process_triggers.backfill_existing_wiki_references`
**Связано:** `issues.md#29`, `AGENTS.md#raw_corrected_zone`

---

### Phase 13.4: Section Template System ✅ COMPLETED (2026-07-01)
**Цель:** Agent-driven recommended section names for wiki pages — JSON templates in `wiki/templates/<category>-template.json`.

**Архитектура:**
```bash
# Per-category template files (optional, agent-managed)
wiki/templates/entity-template.json
wiki/templates/concept-template.json
wiki/templates/synthesis-template.json
wiki/templates/comparison-template.json
```

**Этапы реализации:**
| Step | Task | Status |
|------|------|--------|
| **1** | Design JSON schema for `*template.json` files (category, version, updated, sections[]) | ✅ Done |
| **2** | Add step 2.5 to process-ingest.json: template read → section selection → agent write | ✅ Done |
| **3** | Define agent instructions: required fields vs editable sections, validation rules | ✅ Done |

> **Schema refs:** `process-ingest.json#step_2.5`, `issues.md` Section Template System entry
**Связано:** `PLAN.md Phase 13 (Wiki Page Templates Schema)` — partial closure via agent-driven approach

---

## 🔄 Pending Feature Phases (from original roadmap)

### Phase 13: Wiki Page Templates Schema (#H4) 🥈
**Цель**: Единый, полный, не-разрозненный набор per-type format descriptions для всех типов wiki pages.
**Связан с:** `issues.md#H4`
**Приоритет:** Medium — требуется before any new ingest or synthesis creation

### Phase 12.2: Auto-Extract Assumptions 🥉
**Цель**: Агент автоматически экстрагирует assumptions из источников (источники с weak evidence помечать)
**Приоритет:** Future

---

## 🔄 Pending Phases

| Phase | Description | Priority |
|-------|-------------|----------|
| **S5** | Search analytics → popularity boost in `score_page()`. Read meta/search_analytics.json → add +frequency_boost to pages that appeared in popular queries. Soft signal only — never filters results. | High |
| **Local Indexes** | `index.md` в каждой категории для линейного поиска вместо O(n²) + root index → краткий формат (categories + links only). **Depends:** F1 research on unique file naming before implementation. | High |
| Graph-Based Crosslinks | `auto-crosslink.sh` rewrite с shared-source analysis и scoring | Medium |
| Wiki Scalability (1000+ pages) | Optimizations: ripgrep, incremental rebuild, skip full rebuild >100 pages | Medium |

---


### Phase 29 Deep-Dive Analysis — Summary

**Current problem:** wiki pages reference external URLs without audit trail for contradiction resolution.

**Proposed architecture:**
```bash
# Layer 1: Originals (immutable)
raw/SRC-*/original.md

# Layer 2: Corrected copies (agent rw via scripts)
raw/corrected/SRC-*/file.md

# Layer 3: Wiki pages reference Layer 2
wiki/**/*.md: sources: ["raw/corrected/SRC-*/file.md"]
```

**Impact assessment:**
| Aspect | Before | After |
|--------|--------|-------|
| Audit trail | None | Full chain via manifest.json |
| Contradiction resolution | Blind cascade priority | Source re-read via original_path |
| Delta tracking | No hash check | Hash-based deduplication |

**Risks:** Agent accidentally modifying originals → mitigated by validate-path.sh. Malformed JSON → mitigated by raw-correct.sh validation.

## ✅ Schema Migration — Dialog.md → AGENTS.md + process-файлы (Phase 12.4)

**Status:** ✅ **COMPLETED** (06-29) — all rules embedded in AGENTS.md / process files.
> Note: `dialog.md` has been removed after migration. All references are now inline/embedded in target files.

### Completed actions:
| Step | Action | Result |
|------|---------|--------|
| D1-D2 | Link Conventions + EXT-RES1 embedded, DR-EX1 removed | AGENTS.md updated |
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

*Last update: 2026-07-01 | Phase 13.3 Schema Refs Migration Fix completed, Phase 29 Delta Tracking fully implemented (backflow done). Pending: Phase 12.2 (auto-extract assumptions), S5 (search analytics).*

