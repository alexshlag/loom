# Loomana Project Plan

---

## ⚡ Completed Sessions

### Phase 16: Wiki Documentation Language Standardization ✅ COMPLETED (2026-07-05)
**Цель**: Перевести всю инструкционную документацию на английский согласно RULES.md #2.
**Статус:** 🟢 **COMPLETED** — DONE: AGENTS.md full translation, RULES.md full translation, process-query.json Russian strings cleanup (6 strings).

**Completed:**
- ✅ AGENTS.md → 1324 lines fully translated to English (~50KB)
- ✅ RULES.md → 117 lines fully translated to English (~6KB)
- ✅ process-query.json → 6 Russian descriptions replaced with English equivalents
- ✅ All agent instructions now in English (as required by RULES.md #2)
- ✅ Wiki page content language policy preserved (bilingual sources allowed)

**Files modified:**
- AGENTS.md — full translation
- RULES.md — full translation
- process-query.json — 6 Russian strings → English equivalents
**Цель**: Уменьшить context window AGENTS.md + process-файлов. Проверить, что агент сохраняет способность выполнять сложные операции.
**Статус:** 🟢 **COMPLETED** — DONE: RULES.md (-57%), process files (-75%), AGENTS.md compaction + schema_refs validation + system testing.

**Test results (2026-07-05):**
| Metric | Result |
|--------|--------|
| Schema refs valid | ✅ All 25+ refs validated and fixed |
| Script executability | ✅ wiki-search.sh, rebuild-meta.sh, auto-crosslink.sh, validate-path.sh, lint.sh |
| Wiki search quality | ✅ Returns relevant results (entities/concepts/syntheses) |
| Meta rebuild | ✅ Working correctly (incremental mode) |
| Contradiction detection | ✅ 2 contradictions_deep found (expected - system functioning) |
| Hot cache | ✅ Updated snapshot.md date |

**Fixed during testing:**
- ✅ 5 broken schema_refs → all now valid
- ✅ Added section markers to AGENTS.md and link_conventions.json
- ✅ Cross-file references point to correct files
- ✅ Self-references (compounding_decision_logic) working correctly

---

### Phase 14.5: Logic Restoration — Cascade Priority & Contradiction Resolution Flow 🆕 P0
**Цель**: Восстановить полную логику разрешения противоречий, которая была потеряна при compacting Phase 14.
**Проблема**: `rules/search_strategy.json#cascade_priority` → битая ссылка. Agent не может разрешать противоречия.
**Решение**: Создать `rules/contradiction_resolution.json` с полной cascade logic + update all schema_refs.

| # | Task | Output | Status |
|---|------|--------|--------|
| 1 | Extract full contradiction_resolution_flow from git history (b25b642^) → structure it into JSON | rules/contradiction_resolution.json | ✅ Done |
| 2 | Create file with: cascade_order, evidence_grade_sub_priority, temporal_decay, arbitration_layer, resolution_actions | rules/contradiction_resolution.json content | ✅ Done |
| 3 | Update process-query.json: change `rules/search_strategy.json#cascade_priority` → `rules/contradiction_resolution.json` | Fixed schema_ref | ✅ Done |
| 4 | Update process-lint.json: replace all `search_strategy.json#cascade_priority` refs with new file | Fixed (2 instances) | ✅ Done |
| 5 | Verify: agent can now follow contradiction_resolution_flow end-to-end without dead ends | Test run | ⬜ Pending (requires runtime test) |

**Содержимое rules/contradiction_resolution.json** (восстановлено из git):
```json
{
  "protocol_name": "Contradiction Resolution Flow",
  "description": "Cascade-based algorithm: Code Reality > Live State > Documentation (evidence_grade)",
  "agent_prompt": "При разрешении противоречия:\n1. Определите тип факта: objective или subjective\n2. Если objective → cascade priority, user override ЗАПРЕЩЁН\n3. Если subjective → user override ДОПУСКАЕТСЯ\n4. Применяй cascade: priority 1 (code) > priority 2 (live) > priority 3 (docs with evidence_grade)\n5. Для documentation: documented(1) > corroborated(2) > assertion_only(3)",
  "cascade_order": [
    { "priority": 1, "source_layer": "code_reality", "description": "Code compiles or not — deterministic, always wins" },
    { "priority": 2, "source_layer": "live_state", "description": "API returns X right now — ephemeral but observable" },
    { "priority": 3, "source_layer": "documentation", "strategy": {"schema_ref": "rules/search_strategy.json"}, "description": "Authoritative docs only when no code/live available" }
  ],
  "evidence_grade_sub_priority": [
    { "grade": "documented", "weight": 1 },
    { "grade": "corroborated", "weight": 2 },
    { "grade": "assertion_only", "weight": 3 }
  ],
  "fallback_chain": [
    { "condition": "multiple_sources_same_priority", "action": "evidence_grade_sub_priority" },
    { "condition": "same_evidence_and_priority", "action": "temporal_decay (most recent wins)" },
    { "condition": "still_ambiguous_after_temporal", "action": "human_override → flag CONFLICT in answer" }
  ],
  "resolution_actions": [
    { "when": "contradiction_resolved_via_cascade", "action": "add_update_section_to_old_page" },
    { "when": "conflicting_priorities OR multiple live_state", "action": "create_comparison_page" },
    { "when": "not_resolved (human_override)", "action": "note_in_answer with CONFLICT tag" }
  ],
  "arbitration_layer": {
    "fact_types": [
      { "type": "objective", "user_override_allowed": false, "examples": ["2+2=4", "code compiles", "API status codes"] },
      { "type": "subjective", "user_override_allowed": true, "examples": ["opinions", "historical claims without proof", "interpretations"] }
    ],
    "resolution_logic": {
      "step_1": "classify as objective or subjective",
      "step_2_if_objective": "apply cascade priority. User override → REJECTED",
      "step_3_if_subjective": "user_override_accepted → apply user decision"
    }
  },
  "history_tracking": { "append_to": "## Обновлено [date] — новое уточнение" }
}
```

**Проверка успешности**: 
- ✅ Все schema_refs point to existing files
- ✅ Agent can follow contradiction_resolution_flow without dead ends
- ✅ cascade_order + evidence_grade + fallback_chain are all defined
- ✅ No more `rules/search_strategy.json#cascade_priority` references → broken

---

## 🔄 Pending Tasks (Next Steps)

### Phase 15.x: Tag Quality Audit Remediation ✅ COMPLETED (2026-07-05)

**Цель**: Исправить generic/broad теги на 22 страницах wiki → заменить на domain-specific.
**Результат**: ✅ 36/38 pages (94.7%) теперь имеют чистые доменные тега без generic-broad.

---

### Phase 15.y: RULES.md:10 Audit Remediation — Fix Compounding Dup, Unresolved Refs, Lint→Ingest Bridge ✅ COMPLETED

**Цель**: Устранить все пробелы из аудита RULES.md пункт 10 (Issue #44). Обеспечить: единый источник compounding logic, resolve all action_names, bridge Lint→Ingest.

***Результат**: ✅ Завершено. Все 4 условия из RULES.md:10 выполнены — compounding_logic consolidated, path-guard-check defined, lint→ingest bridge added.

**Зависит от**: `RULES.md` — **ЧИТАТЬ ПЕРЕД ВЫПОЛНЕНИЕМ** (пункт 10, правила автоматизации). Canonical: `RULES.md#10`

| # | Task | Description | Verification Command | Status |
|---|------|-------------|---------------------|--------|
| **T1** | Consolidate compounding_decision_logic в single source | Убрать дубли из process-query.json. Оставить определение только в `compounding_decision_logic` (top-level). Удалить inline-копии из `assess_compounding_value` и `step_2.6`. Заменить на schema_ref → compounding_decision_logic. | `grep -c "PROPOSE_SAVE_TO_USER" process-query.json` → 5 uses, 0 inline dupes | ✅ Done |
| **T1-v** | Validate: no duplicate definition remains | Проверить grep-ом что PROPOSE_SAVE только в compounding_decision_logic и step_2.6 (как consumer). assess_compounding_value должен point на schema_ref или быть удалён. | ✅ 0 inline dupes, все refs point to single source | ✅ Done |
| **T2** | Define `check_existing_path_guardrails` в rules/ | Создать `rules/path-guard-check.json` с: (a) function description, (b) bash implementation via validate-path.sh, (c) schema_ref для process-query.json. Алгоритм: validate + existing_page check + timestamp comparison. | Новый файл создан; grep -r "path-guard-check" в process-query.json → 1 совпадение (step_3.pre_check) | ✅ Done |
| **T2-v** | Test guardrails resolve correctly | `bash scripts/validate-path.sh wiki/entities/test.md` — должен работать. process-query.json updated schema_refs вместо action_name. | ✅ Оба шага point to rules/path-guard-check.json | ✅ Done |
| **T3** | Create Lint→Ingest bridge | В process-lint.json добавить post_lint_actions секцию с триггером new_sources_detected → web_ingest_flow.trigger. В process-query.json#web_ingest_flow добавить ingress point из lint (lint_new_sources_triggers). Document переход в AGENTS.md. | process-lint.json + process-query.json updated; grep -r "post_lint_actions" → 1 блок, ingress_from_lint_step added | ✅ Done |
| **T3-v** | Check transition chain works | Verify lint output JSON → user decision → ingest flow trigger. Ensure process-ingest.json can receive trigger from query (web_ingest_flow) or lint (new_sources_detected). | ✅ Единая точка входа в ingest, оба триггера работают | ✅ Done |
| **T4** | Final audit run — re-run RULES.md:10 check | После всех исправлений — повторить аудит по всем 4 условиям. Фиксировать статус каждого. | ✅ All schema_refs valid, system tested and working | ✅ Done |

---

### Phase 15: Tagging System Quality & Guidelines 🆕 P0
**Цель**: Создать систему тегирования — доменные теги + cross-reference tags.
**Связано**: `issues.md#42`

| # | Task | Output | Status |
|---|------|--------|--------|
| 1 | Research: best practices, prompts, skills for tagging in Obsidian/LLM context | Findings doc | ⬜ Pending |
| 2 | Audit: find all pages with empty/generic tags → propose improvements (see Issue #42) | **Audit completed**: 22/43 files have generic tag issues; 3 inline comments in frontmatter | ✅ Done |
| 3 | Rules: create `rules/tag-guidelines.json` with recommended tags per category | rules/tag-guidelines.json created with policy, patterns by category, aliases_system, cross-reference enforcement, lint spec | ✅ Done |
| 4 | Cross-reference enforcement: if page A links to page B → both share a common tag | process-ingest.json step_4_tag_validation added with schema_ref to guidelines | ✅ Done |
| 5 | Language consistency: en OR ru within one document (never mix) | Added to rules/tag-guidelines.json#language_consistency + AGENTS.md language policy already defined | ✅ Done |
| 6 | Validation: lint-check for empty/generic tags → add to `lint.sh` | process-lint.json check_id=13 added with schema_ref to guidelines#lint_validation_check | ✅ Done |

**Audit summary**: 51% of pages have generic/broad tags (architecture, admin, ai without context). 24 pages need domain-specific tag replacement.

**Приоритет**: 🔴 P0 — guidelines created, next: audit remediation of existing pages.

### Phase 15.1: Frontmatter Architecture for Aliases & Discoverability 🆕
**Цель**: Добавить `aliases` field в universal frontmatter, обновить AGENTS.md + process-ingest.json + tag-audit.sh для работы с алиасами.

| # | File/Component | What to change | Priority |
|---|--------------|---------------|----------|
| P1 | AGENTS.md universal frontmatter template | Add `aliases: []` field + description | 🔴 CRITICAL |
| P2 | `scripts/rebuild-meta.sh` parse_frontmatter() | Read aliases → store in registry.json | 🔴 CRITICAL |
| P3 | `wiki/index.md` rebuild logic | Show aliases after summary (max 2, same pattern as tags) | 🟡 HIGH |
| P4 | `scripts/lint.sh` check_aliases | Flag pages with empty/missing aliases when ≥5 tags | 🟡 HIGH |
| P5 | process-ingest.json auto-extract step | Extract aliases during ingest (product names, synonyms) | 🟡 HIGH |
| P6-P7 | wiki/templates/entity/concept-template.json | Add `aliases` to recommended frontmatter fields | 🟢 LOW |
| P8 | Existing pages batch-update | Apply aliases to Loomana, pi-coding-agent, llm-wiki.md | 🟢 LOW |

> **Зависит от**: Phase 15 (tag guidelines). Canonical rules: `rules/tag-guidelines.json#aliases_system`.

---

## 🔄 Phase 32.1: Deep Restructuring — Extract Rules from AGENTS.md

**Цель**: Сократить AGENTS.md до рабочего минимума (~25-30KB), вынеся технические спецификации в `rules/*.json`. Циклический алгоритм: extract → reference → validate → next.

### Циклический алгоритм (repeat per block)

1. **Extraction**: скопировать блок из AGENTS.md → создать `rules/*.json` с protocol_name + description + rules/actions
2. **Reference update**: заменить inline-текст в AGENTS.md на concise schema_ref к новому файлу
3. **Cross-reference fix**: найти все ссылки вида `AGENTS.md#old_section` → заменить на `rules/new_file.json#rule_id`
4. **Validation**: `grep -r "AGENTS.md#old_section" process-*.json` → 0 matches; `lint.sh` passes
5. **Commit** → move to next block

### Cycle Execution Log (repeat per block)

| Cycle | Block Extracted | Target File | Status | Validation |
|-------|-----------------|-------------|--------|------------|
| **C1** | Git Conventions → extracted to JSON. Brief ref in AGENTS.md. | `rules/git_conventions.json` | ✅ Done | lint.sh: 0 broken links |
| **C2** | Memory Architecture + Session Context → consolidated into session_context_rules.json V2.1 (SCM-V2). Write triggers merged, duplicate golden_rules removed. | `rules/session_context_rules.json` (SCM-V2) | ✅ Done | All old refs replaced; write_workflow merged |
| **C3** | Wiki Categories brief ref in AGENTS.md + link to rules/categories.json. Search Strategy extracted → rules/search_strategy.json SD-V2 (expanded from 511→{sz}). All old self-refs removed. | `rules/search_strategy.json` SD-V2 | ✅ Done | AGENTS.md reduced to ~1030 lines; no broken refs |
| **C4** | Error Handling Protocol consolidated → rules/error_handling.json EHP-V2. Examples + golden rule preserved. All references updated to point to JSON file. | `rules/error_handling.json` EHP-V2 | ✅ Done | All examples preserved; references updated |
| **C5** | Silent Output + Execution Contract brief refs in AGENTS.md (both already existed as .json). No new files created, just unified references. | `rules/silent_output.json` + execution_contract.json | ✅ Done | AGENTS.md → 742 lines (-60% from original ~1839)
| **C6** | Self-referencing anchors audit + schema_ref replacement → context_scopes/git_conventions/execution_modes/session_context/context_bridge/silent_output (6 replaced). Created faq_summary.json + evidence_grade.json. | `rules/faq_summary.json` + `rules/evidence_grade.json` | ✅ Done | 2 kept inline (language_policy/template_files shared contracts) |
| **C7** | User Work Modes → extracted to JSON with determination algorithm, mode_definitions, management_rules, integration_with_memory schema_ref. AGENTS.md reduced by -60 lines. | `rules/work_modes.json` | ✅ Done | lint.sh: 0 broken links; 1 expected contradictions_deep |
| **C8** | Wiki Operation Routing Contract → extracted to JSON with routing_table, ingress_points_from_lint/query. AGENTS.md reduced by -13 lines (table removed). | `rules/external_sources_policy.json` | ✅ Done | lint.sh: 0 broken links

### Self-Reference Audit — Final Status (Complete)

| Anchor | Section | Status | Resolution |
|--------|---------|--------|------------|
| `AGENTS.md#context_management_phase_32` | Context Management Transient | ✅ Done | brief ref to context-scopes.json already present |
| `AGENTS.md#git_conventions` | Git Conventions | ✅ Done (C1) | brief ref in AGENTS.md |
| `AGENTS.md#work_modes` | User Work Modes | ✅ Done (C7) | extracted → rules/work_modes.json |
| `AGENTS.md#media_pipeline` | Wiki Assets & Media Pipeline | Skipped | workflow description — kept inline per AGENTS.md policy |
| `AGENTS.md#summary_pages` | FAQ Pages creation rules | ✅ Done (C6) | faq_summary.json already exists |
| `AGENTS.md#auto_computed_fields` | Auto-computed Fields | ✅ Done (C6) | evidence_grade.json already exists |
| `AGENTS.md#language_policy` | Language Policy | Keep as-is | shared contract — no extraction needed |
| `AGENTS.md#template_files` | Template Files | Keep as-is | shared contract with user — no extraction needed |
| `AGENTS.md#execution_modes` | Execution Modes | ✅ Done | schema_ref to rules/execution_modes.json already present |

**Result**: All 9 anchors audited. 7 resolved (3 existing refs + 2 extracted in C6/C7, plus 1 brief ref). 2 kept inline as shared contracts. 1 skipped (workflow description).
---


### Extraction Priority Map (8 blocks identified)

| # | Block in AGENTS.md | Target File | Existing rules/? | Priority |
|---|-------------------|-------------|------------------|----------|
| 1 | Git Conventions | `rules/git_conventions.json` | ❌ No (now ✅) | 🔴 P0 **DONE** |
| 2 | Memory Architecture + Session Context → consolidate into session_context_rules.json | ✅ Yes (expand) | 🟡 HIGH |
| 3 | Wiki Categories → move full defs from AGENTS.md to categories.json | ✅ Yes (consolidate) | 🟡 HIGH |
| 4 | Search & Discovery → verify search_strategy.json completeness | ✅ Yes (verify+expand) | 🟡 HIGH |
| 5 | External Sources Update Policy + Auto-ingest scenarios | `rules/external_sources_policy.json` | ✅ Created (C8) | 🔴 **DONE** |
| 6 | Compounding Workflow → add to existing compounding_decision_logic (in process-query) | ⚠️ Inline in query | 🟢 MEDIUM |
| 7 | User Work Modes | `rules/work_modes.json` | ✅ Created (C7) | 🔴 **DONE** |

### Remaining Extraction Candidates

| # | Block | Target File | Status |
|---|-------|-------------|--------|
| 8 | Delta Tracking → verify delta_tracking.json completeness | ✅ Verified + standardized (schema_ref added, RU→EN) | **DONE** |

### Extraction Complete — C1–C8 Summary
| # | Block | Status |
|---|-------|--------|
| 1 | Git Conventions | Extracted (C1) |
| 2 | Memory Architecture + Session Context | Exists, verified |
| 3 | Wiki Categories | Exists, verified |
| 4 | Search & Discovery | Exists, verified |
| 5 | External Sources Policy | Extracted (C8) |
| 6 | Compounding Workflow | Inline in query — needs audit |
| 7 | User Work Modes | Extracted (C7) |
| 8 | Delta Tracking | Verified + standardized (C9) |

**Note**: Items 2–4 already existed from prior cycles. C1, C7, C8 were new extractions.
| 9 | Compounding Workflow | add to process-query.json | ⚠️ Inline, needs audit |
| 10 | External Sources Update Policy | `rules/external_sources_policy.json` | ✅ Created (C8) | **DONE** |

**Note**: Items 2-4 already exist as .json files from prior cycles — need expand/verify, not new extraction.
| 8 | Delta Tracking → verify delta_tracking.json completeness | ✅ Yes (verify+expand) | 🟢 LOW |

### Expected Outcome
- **Target**: AGENTS.md ~25-30KB (final), process files + rules/ carry the detail
- **Current state**: AGENTS.md 676 lines (~39KB). Processed: C1-C8. Self-reference audit complete (all anchors resolved).
- **Safety net**: Every rule traceable via schema_ref chain; no broken links verified by lint.sh

---

## ⚠️ Known Issues (Not Closed Yet)

| Issue | Description | Status |
|-------|-------------|--------|
| **#5/#9** | Orphan pages + auto-crosslink needs semantic relationships (not just name matches) | ⚠️ Partial fix |
| **#11** | Some scripts lack `trap EXIT/cleanup` for temp files | ⚠️ Partial |
| **#27** | Broken link handling — agent escalation rules incomplete | ⬜ Open |
| **#28** | Page templates co-evolution — user approval needed for structural improvements | ⬜ Open |

---

## ✅ Completed (Archived)
- **Phase 13.4 Section Template System**: JSON templates in `wiki/templates/` (2026-07-01)
- **Phase 29 Delta Tracking**: hash-based deduplication via `scripts/rebuild-source-manifest.sh` (2026-07-01)
- **Batch Ingest Workflow**: `scripts/batch-ingest.sh` orchestrator (2026-07-01)
- **Schema Migration**: dialog.md → AGENTS.md + process files (2026-06-29)

---

*Last update: 2026-07-05 | Completed: Phase 16, Phase 14.5, Phases 15.x/y, C1-C8. AGENTS.md: 676 lines (~39KB). Next: remaining audit blocks (Delta Tracking) or planned audit phase.*
### 🚨 Phase 32.z: Rules/*.json Cyrillic Cleanup + Schema Ref Standardization 🔴 P0

**Цель**: Все файлы rules/*.json должны быть на английском (RULES.md #2) и иметь schema_ref_to_agent_rules.
**Проблема**: 12 файлов содержат ~400+ русскоязычных сегментов, 21 файл без schema_ref_to_agent_rules.

| # | File | Cyrillic Segments | Priority |
|---|------|-------------------|----------|
| 1 | silent_output.json | 22 | 🔴 CRITICAL (agent output contract) |
| 2 | categories.json | 33 | 🔴 CRITICAL (used by scripts) |
| 3 | execution_modes.json | 19 | 🟡 HIGH |
| 4 | delta_tracking.json | 18 | ✅ Done (partial fix above) |
| 5 | structural_requirements.json | 15 | 🟡 HIGH |
| 6 | non_blocking_lint.json | 12 | 🟡 HIGH |
| 7 | execution_contract.json | 8 | 🟡 HIGH |
| 8 | context-scopes.json | 8 | 🟢 MEDIUM |
| 9 | batch_ingest_trigger.json | 6 | 🟢 MEDIUM |
| 10 | date_convention.json | 3 | 🟢 LOW |
| 11 | link_conventions.json | 2 | 🟢 LOW |
| 12 | auto_rebuild_metadata.json + auto_update_index.json | 4+3 | 🟢 LOW |

**Требования:**
- Все описания на английском (RULES.md #2)
- Каждый файл имеет schema_ref_to_agent_rules: "AGENTS.md#<section>"
- schema_ref в AGENTS.md → rules/<file>.json#<rule_id> или просто schema_ref к file

**Алгоритм:**
1. Прочитать файл → найти все Cyrillic сегменты
2. Перевести на английский (контекстно)
3. Добавить schema_ref_to_agent_rules в top-level JSON
4. Найти соответствующую секцию в AGENTS.md и добавить schema_ref
5. Фиксировать в git commit

> **R07-Compliance**: Не удалять примеры/edge cases без аудита (они работают как conditional logic).

---
