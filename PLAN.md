# Loomana Project Plan

---

## ✅ Completed Phases

### Phase 15: Tagging System Quality & Guidelines ✅ Done
- Tags remediated: 36/38 pages (94.7%) fixed
- `rules/tag-guidelines.json` created with policy, patterns, aliases_system
- Cross-reference enforcement in process-ingest.json step_4_tag_validation
- Validation lint-check in process-lint.json check_id=13

### Phase 15.1: Frontmatter Architecture for Aliases & Discoverability ✅ Done
- `aliases` field added to universal frontmatter (AGENTS.md)
- Integration across scripts (rebuild-meta.sh, wiki/index.md)
- Batch-update applied to existing pages

### Phase 16.1: Agent Memory Layer Architecture ✅ Done
- PRF-enhanced recall engine (`scripts/memory/recall.sh`)
- Hot cache optimization (`hot-cache-update.sh`, `load-hot-cache.sh`, `restore-hot-cache.sh`)
- Memory hooks extraction in all process files, trajectory capture + distillation pipeline

### Phase 17: Script Architecture Hardening ✅ Done (T2-T4 complete)
- T2: JSON safety — replaced manual echo/printf with Python json.dumps() ✓
- T3: Standardize `set -euo pipefail` across all scripts ✓
- T4: Unified walk in rebuild-meta.sh — merged registry + backlinks ✓

### Phase 18: Documentation & Manual Support System ✅ Done (D1-D5 complete)
- docs-template.json created with sections hierarchy + navigation pattern
- `rules/categories.json` updated with "docs" category
- process-ingest.json branching for framework clusters → wiki/docs/ routing
- Structural requirements for docs pages in rules/structural_requirements.json
- scripts/docs-audit.sh implemented

### Phase 19: Wiki Naming Collision Audit ✅ Done (N1-N5 complete)
- Exception list added to naming_conventions.json
- filename-audit.sh created with JSON output
- Lint integration via check_id=6 (filename_collision_audit)
- 10 violations flagged — awaiting user approval for rename

### Phase 20: Wiki Skills System Integration ✅ Done (S1-S5 complete)
- Skill format spec in rules/skill_format.json
- Bootstrap integration via session_bootstrap.json
- Auto-generation trigger in process-ingest.json memory_hooks
- Query awareness in process-query.json
- Export script: scripts/export-skill.sh

### Phase 20.2: Distillation Pipeline Fix & Auto-Trigger ✅ Done (D1-D3 complete)
- Fixed distill.sh naming convention ({slug}-skill.md)
- Auto-distillation trigger added after capture in memory_hooks
- Duplicate detection logic updated with slug regex

### Phase 20.1: External Skill Search & Cross-Linking ✅ Done (S6-S9 complete)
- rules/skill_search_sources.json — curated sources list
- rules/skill_safety_check.json — safety validation before import
- process-query.json skill search fallback chain updated
- skill_format.json → added related_docs field with auto-suggestion logic

### Phase 21: Project Documentation System ✅ Done (G1-G6 complete)
- getting-started.md, architecture.md, wiki-structure.md
- scripts-guide.md, rules-reference.md, api-conventions.md

### Phase 22: User-Facing Documentation (Release Docs) ✅ Done
- troubleshooting.md, security-guide.md, extending-wiki.md added
- All docs release-ready, modular, no duplication of AGENTS.md

### Phase 23: Advanced Documentation Gaps ✅ Done (G1-G5 complete)
- session-lifecycle.md — full session flow (bootstrap → sync → end)
- advanced-query.md — topic continuity bias, compounding decision logic
- batch-ingest.md — cluster detection algorithm + manual initiation
- memory-hooks.md — trajectory capture → distillation pipeline
- snapshot-lifecycle.md — wiki snapshot lifecycle & active projects

---

### Phase 25: Memory Scripts Consolidation & Schema Ref Migration ✅ Done (H1-H4 complete)

**Problem resolved:** load-hot-cache.sh and restore-hot-cache.sh were identical. --check-only flag was unused. Inline calls scattered across process files.

| # | Task | Description | Priority | Status |
|---|------|-------------|----------|--------|
| **H1** ✅ | Remove restore-hot-cache.sh | Merged into load-hot-cache.sh (both identical) |
| **H2** ✅ | Clean hot-cache-update.sh --check-only flag | Default mode is check-only; removed unused flag and all calls with it |
| **H3** ✅ | Replace inline calls in process-*.json → schema_ref | session_context_rules.json#write_triggers instead of direct commands |
| **H4** ✅ | Update docs/ and wiki/docs/ references | Point to consolidated script names and schema_ref pattern |

> **Result:** 2 scripts for hot cache (load, update-check), unified contract via schema_ref.

---

### Phase 24: Memory Sync Contract Unification ✅ Done (M1-M4 complete)

**Problem resolved:** WM/hot.md sync logic was duplicated across RULES.md §8/§11, process-*.json memory_hooks, git_conventions.json#memory_sync_on_dev_commit, and rules/memory-sync-at-task-end.md.

| # | Task | Description | Priority | Status |
|---|------|-------------|----------|--------|
| **M1** ✅ | Add PROCESS_COMPLETE trigger to session_context_rules.json#write_triggers | Extend existing HOT-SAVE-ACTION-V1 contract; add process_complete → ref rule_id pattern |
| **M2** ✅ | Remove rules/memory-sync-at-task-end.md | Duplicates session_context_rules.json#write_triggers — user docs are in docs/ |
| **M3** ✅ | Clean up RULES.md §8/§11 | Replace inline sync commands with schema_ref to session_context_rules.json#write_triggers |
| **M4** ✅ | Clean up process-*.json memory_hooks | Remove inline hot-cache/auto-refresh calls; replace with schema_ref |

> **Result:** One source of truth (`session_context_rules.json#write_triggers`), zero duplication, schema_ref everywhere.

---

## 🔄 Active / Pending Phases

### Phase 17 (Continued): Remaining Script Hardening

| # | Task | Description | Priority | Status |
|---|------|-------------|----------|--------|
| **T5** | Batch JSON reads (#48) → single python3 call | Consolidate N+1 calls in lint.sh, text-similarity.sh | 🟡 P2 MEDIUM | ⬜ Pending |

### Phase 19 (Continued): Filename Collision Auto-Fix

| # | Task | Description | Priority | Status |
|---|------|-------------|----------|--------|
| **N6** | User approval → rename 10 wiki/concepts/ pages | Apply suggested prefixes: symfony-*, twig-*, etc. | 🔴 P0 CRITICAL | ⬜ Awaiting user approval |

### Phase 52: Discovery Step Integration — Schema Patch Required 🆕

| # | Task | Description | Priority | Status |
|---|------|-------------|----------|--------|
| **D1** | Add discovery step to RULES.md §9 R01 | "BEFORE writing → scan rules/ scripts/" | 🔴 P0 CRITICAL | ⬜ Awaiting schema-patch approval |

> **Related:** issues.md#52 — Missing Discovery Step in Development Workflow
> **Proposed fix:** Add single sentence to R01 or step 3.5 between Plan and Implementation in §11

---

## 📐 Current Architecture Gaps (Low Priority)

| Gap | Status | Note |
|-----|--------|------|
| Contradiction resolution in practice | ⚠️ Partially covered | Cascade theory exists; real-world scenarios could be added to troubleshooting.md later |
| Error handling deep dive | ✅ Covered | rules/error_handling.json#resolution_actions includes 4 concrete situations |

---

> Last update: 2026-07-08 | Pending tasks: T5 (batch JSON reads), N6 (rename pages), D1 (discovery step integration).
