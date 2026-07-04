# Loomana Project Plan

---

## ⚡ Current Task — ACTIVE

### Phase 14: Compact Rules & Process Files ✅ COMPLETED (2026-07-04)
**Цель**: Уменьшить context window process-файлов и RULES.md.
**Статус:** ✅ **COMPLETED** (ca6914b)

---

## 🔄 Pending Tasks (Next Steps)

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

- **Phase 14 Compact Rules**: process files -75%, RULES.md -57% (`ca6914b`, `d826d00`)
- **Phase 13.4 Section Template System**: JSON templates in `wiki/templates/` (2026-07-01)
- **Phase 29 Delta Tracking**: hash-based deduplication via `scripts/rebuild-source-manifest.sh` (2026-07-01)
- **Batch Ingest Workflow**: `scripts/batch-ingest.sh` orchestrator (2026-07-01)
- **Schema Migration**: dialog.md → AGENTS.md + process files (2026-06-29)

---

*Last update: 2026-07-04 | Current task: Phase 15 (Tagging System). Next: Phase 15.1 (Aliases).*
