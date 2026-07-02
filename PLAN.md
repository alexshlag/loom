# Loomana Project Plan

---

## 🔄 Pending Phases (Next Steps)

### Phase 14: Schema Optimization & Architecture Refinement 🆕
**Цель**: Реализация рекомендаций по упрощению манифеста и разделению данных.
**Этапы:**
1. **Conceptual Grouping**: Объединение разрозненных архитектурных слоев (Raw, Wiki, Assets) в единый блок "Knowledge Architecture".
2. **Error Handling Abstraction**: Замена детальных описаний каждой ошибки в AGENTS.md на высокоуровневую стратегию "Detect → Log → Resolve → Continue", со ссылками на `process-*.json`.
3. **Technical Detail Extraction**: Вынос специфических технических правил (например, детали парсинга JSON или специфических флагов bash) в директорию `rules/`.
4. **Verification**: Проверка того, что агент сохраняет способность выполнять сложные операции, несмотря на упрощение описаний.

**Статус:** ⬜ Open — планируется обсуждение и утверждение этапов.
**Связь**: `issues.md#39`

---

## ✅ Completed — 2026-07-02 Session

### Phase 14 (Partial): Schema References Migration ✅ COMPLETED
**Цель**: Устранить битые schema_refs в process-файлах.

**Результат:**
| Step | Task | Status |
|------|------|--------|
| **1** | Создана директория `rules/` с отдельными JSON-файлами для каждого правила | ✅ Done |
| **2** | Исправлены битые ссылки в process-ingest.json (7 refs) | ✅ Done |
| **3** | Создано новое правило `batch_ingest_trigger.json` | ✅ Done |

**Связано**: `issues.md#37-38`

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
| **1** | Design JSON schema for `*template.json` files | ✅ Done |
| **2** | Add step 2.5 to process-ingest.json: template read → section selection | ✅ Done |
| **3** | Define agent instructions: required fields vs editable sections | ✅ Done |

### Phase 13.3: Schema References Migration Fix ✅ COMPLETED (2026-07-01)
**Цель**: Устранить broken schema_refs в process-query.json, process-ingest.json, process-lint.json.

**Результат:** Все ссылки исправлены и ведут на существующие файлы правил.

### Phase 29: Delta Tracking — Implementation Plan ✅ COMPLETED (2026-07-01)
**Цель**: Реализовать delta tracking через `scripts/rebuild-source-manifest.sh` для предотвращения re-ingest duplicate sources.

**Результат:** Все компоненты созданы и интегрированы в ingest flow.

### Phase 13.2: Batch Ingest Workflow ✅ COMPLETED (2026-07-01)
**Цель**: Cross-reference между новыми источниками + bulk-update index/hot/log.

---

## 🔄 Pending Feature Phases

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
| D3 | fetch_content_truncation.secondary_action cleaned | AGENTS.md cleaned |
| D4 | ZONE-DEF1 + META-DEF1 added to Protected Zones | AGENTS.md updated |
| D5 | EXT-RES1 embedded in process-ingest.json | process-ingest.json updated |
| D6 | BROKEN-REF1-v3 embedded, schema_ref fixed | process-query.json updated |
| D7 | check_id=7 reference fixed, fuzzy_matching removed | process-lint.json updated |
| D8 | DUAL-MODE-LINT-1 modes added to lint_checks | process-lint.json updated |

### Cross-category exception:
- `../` allowed for cross-category wiki links (e.g. concepts/ ↔ syntheses/) as long as target exists under wiki/
- Updated in AGENTS.md Link Conventions section.


---

*Last update: 2026-07-02 | Phase 14 Schema Optimization planned, Phase 13.3 completed.*
