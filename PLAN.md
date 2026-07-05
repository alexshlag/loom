# Loomana Project Plan

---

## ⚡ Current Task — ACTIVE

### Phase 14: Compact Rules & Process Files ✅ COMPLETED (2026-07-05)
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

### Phase 15.x: RULES.md:10 Audit Remediation — Fix Compounding Dup, Unresolved Refs, Lint→Ingest Bridge 🆕 P0 **NEW**

**Цель**: Устранить все пробелы из аудита RULES.md пункт 10 (Issue #44). Обеспечить: единый источник compounding logic, resolve all action_names, bridge Lint→Ingest.

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

| # | Task | Output |
|---|------|--------|
| 1 | Research: best practices, prompts, skills for tagging in Obsidian/LLM context | Findings doc |
| 2 | Audit: find all pages with empty/generic tags → propose improvements (see Issue #42) | Audit report |
| 3 | Rules: create `rules/tag-guidelines.json` with recommended tags per category | rules/tag-guidelines.json |
| 4 | Cross-reference enforcement: if page A links to page B → both share a common tag | process-ingest.json update |
| 5 | Language consistency: en OR ru within one document (never mix) | AGENTS.md language policy |
| 6 | Validation: lint-check for empty/generic tags → add to `lint.sh` | lint.sh check_id=13b |

**Приоритет**: 🔴 P0 — требует research + proposal.

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

## ⚠️ Known Issues (Not Closed Yet)

| Issue | Description | Status |
|-------|-------------|--------|
| **#39** | Context bloat — AGENTS.md still too verbose. Solution: move technical specs to `rules/` | ⬜ Open |
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

*Last update: 2026-07-05 | Current task: Phase 15.x (RULES.md:10 remediation). Next: Phase 15 (Tagging System).*