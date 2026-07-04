# Loomana Project Plan

---

## ⚡ Priority Task — IMMEDIATE

### Phase 14: Schema Optimization & Architecture Refinement 🔴 P0
**Цель**: Реализация рекомендаций по упрощению манифеста и разделению данных.
**Статус**: 🟥 **HIGH PRIORITY** — requires session refresh before implementation.

---

## 🔄 Pending Phases (Next Steps)

### Phase 15: Tagging System Quality & Guidelines 🆕
**Цель**: Создать систему тегирования wiki — обязательные доменные теги + cross-reference tags.
**Этапы:**
1. **Research**: Поиск best practices, промптов, скиллов по tagging в Obsidian/LLM-контексте
2. **Audit**: Найти все страницы с пустыми/generic тегами → предложить улучшения (см. Issue #42)
3. **Rules**: Создать `rules/tag-guidelines.json` с рекомендуемыми тегами для каждой категории:
   - Entity: `[entity, domain-keyword, framework/tools]`
   - Concept: `[concept, domain, related-entity-tags]`  
   - Synthesis: `[synthesis, topic, cross-reference-tags]`
4. **Cross-reference enforcement**: Если страница A ссылается на страницу B → обе имеют общий tag
5. **Language consistency**: en OR ru в рамках одного документа (не смешивать)
6. **Validation**: lint-check для пустых/generic тегов → add to `lint.sh`

**Статус:** ⬜ Open — требует research + proposal.
**Связано**: `issues.md#42`, `wiki-search.sh` tag-match bonus, AGENTS.md#free-form-tags.

### Phase 14: Schema Optimization & Architecture Refinement 🆕
**Цель**: Реализация рекомендаций по упрощению манифеста и разделению данных.
**Этапы:**
1. **Conceptual Grouping**: Объединение разрозненных архитектурных слоев (Raw, Wiki, Assets) в единый блок "Knowledge Architecture".
2. **Error Handling Abstraction**: Замена детальных описаний каждой ошибки в AGENTS.md на высокоуровневую стратегию "Detect → Log → Resolve → Continue", со ссылками на `process-*.json`.
3. **Technical Detail Extraction**: Вынос специфических технических правил (например, детали парсинга JSON или специфических флагов bash) в директорию `rules/`.
4. **Compact Rules Implementation**: Внедрение 6 правил компактизации инструкций из `RULES.md#9` — schema_ref вместо дублей, progressive disclosure, recency bias. Инструмент: `.pi/skills/compact/SKILL.md` для автоматического рефакторинга verbose JSON → constraints + if_broken.
5. **Verification**: Проверка того, что агент сохраняет способность выполнять сложные операции, несмотря на упрощение описаний.

**Статус:** ⬜ Open — планируется обсуждение и утверждение этапов.
**Связь**: `issues.md#39`

---

---

### Phase 15.1: Frontmatter Architecture for Aliases & Discoverability 🆕
**Цель**: Добавить `aliases` field в universal frontmatter, обновить AGENTS.md + process-ingest.json + tag-audit.sh для работы с алиасами.
**Контекст**: Теги (tags) = domain keywords для поиска. Алиасы (aliases) = discoverability synonyms — слова которые user реально печатает в query. Без aliases страница не находится по поиску (search-by-synonym).

**Этапы реализации:**
| Step | Task | Output |
|------|------|--------|
| **1** | Обновить AGENTS.md: добавить `aliases` к universal frontmatter template + language policy для bilingual aliases | AGENTS.md updated |
| **2** | Обновить process-ingest.json: step ingest → auto-extract aliases (product names, synonyms, author references) | process-ingest.json updated |
| **3** | Обновить tag-audit.sh / lint.sh: check_aliases — если страница имеет 0 aliases, flag для agent review | scripts updated |
| **4** | Обновить wiki templates (entity-template.json, concept-template.json): добавить `aliases` в recommended frontmatter fields | templates updated |
| **5** | Batch-update existing pages with high search-potential: Loomana, pi-coding-agent, llm-wiki.md | Domain tags + aliases applied |

**Связано**: `rules/tag-guidelines.json`, `issues.md#42`
**Зависит от**: Phase 15 (tag guidelines)

### Phase 15.1 Execution Plan — Pending Review

| # | File/Component | What to change | Priority |
|---|--------------|---------------|----------|
| **P1** | AGENTS.md universal frontmatter template | Add `aliases: []` field + description (after category, before sources) | 🔴 CRITICAL |
| **P2** | `scripts/rebuild-meta.sh` parse_frontmatter() | Read aliases from YAML → store in registry.json as page['aliases'] | 🔴 CRITICAL |
| **P3** | `wiki/index.md` rebuild logic (in rebuild-meta.sh) | Show aliases after summary: `[alias] [alias] [alias]` (max 2, same pattern as tags) | 🟡 HIGH |
| **P4** | `scripts/lint.sh` check_aliases | Add check_id=13b: flag pages with empty/missing aliases when they have ≥5 tags |
| **P5** | process-ingest.json auto-extract step | Add aliases extraction during ingest (product names, synonyms, author refs) | 🟡 HIGH |
| **P6** | wiki/templates/entity-template.json | Add `aliases` to recommended frontmatter fields |
| **P7** | wiki/templates/concept-template.json | Same as entity template |
| **P8** | Existing pages batch-update | Apply aliases to Loomana (already done), pi-coding-agent, llm-wiki.md, symfony.md |

> **Связано**: Phase 15.1 → execution sub-steps P1-P8. Canonical rules already exist in `rules/tag-guidelines.json#aliases_system`.

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

### Phase 14 (Full): Schema Optimization & Architecture Refinement — Workflow Cleanup ✅ COMPLETED (2026-07-02)
**Цель**: Исправить структурные аномалии в process-файлах после schema cleanup.

**Результат:**
| Step | Task | Status |
|------|------|--------|
| **1** | Исправлены битые schema_refs (7 cases) → все refs valid | ✅ Done |
| **2** | Устранен duplicate step_id "0.5" в process-query.json (`query_intent_decoder` vs `new_sources_quick_check`) | ✅ Done — renamed to 0.76 |
| **3** | Добавлены descriptions для steps 8a/8b (integration_new_page, integration_update_existing_page) | ✅ Done |
| **4** | Обновлен stale trigger reference (`step_05` → `step_076`) | ✅ Done |

**Validation:** ✅ All JSON valid. ✅ No duplicate IDs. ✅ All steps documented.

**Связано**: `issues.md#40`, `issues.md#41`

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

### Phase 14 (Full): Schema Cleanup & Consolidation 🆕
**Цель**: Восстановить чистую архитектуру инструкций после хаоса, вызванного некорректной рекурсией слабой LLM модели.
**Контекст**: Временная модель удалила дубликаты из AGENTS.md при создании новых файлов (ARCHITECTURE.md, DOCUMENTATION.md, TEMPLATES.md, WORK_MODES.md), но создала битые ссылки и потеряла информацию. Состояние восстановлено — теперь нужно убрать артефакты.

**Этапы:**
| Step | Task | Decision Criteria |
|------|------|-------------------|
| **1** | Verify AGENTS.md has all content from files to delete (ARCHITECTURE.md, DOCUMENTATION.md, TEMPLATES.md, WORK_MODES.md) | Compare each file section-by-section. If missing → restore before deletion |
| **2** | Delete new instruction files from root directory | Remove 4 .md files once verified AGENTS.md is complete |
| **3** | Audit process-*.json for broken schema_refs | Each case analyzed individually — fix or log as issue |
| **4** | Restore overall logic consistency | Check for remaining duplicates/anomalies, write found issues to issues.md |

**Status:** ⬜ Open — awaiting execution.

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

*Last update: 2026-07-02 | Phase 14 (Full) Schema Cleanup planned, Phase 13.3 completed.*
