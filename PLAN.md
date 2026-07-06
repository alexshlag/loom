# Loomana Project Plan

---

## 🔄 Active / Pending Phases

### Phase 15: Tagging System Quality & Guidelines 🔴 P0
**Цель:** Создать систему тегирования — доменные теги + cross-reference tags.
**Связано:** `issues.md#42`

| # | Task | Output | Status |
|---|------|--------|--------|
| 1 | Research: best practices for tagging in Obsidian/LLM context | Findings doc | ⬜ Pending |
| 2 | Audit remediation: generic tags → domain-specific | ✅ 36/38 pages (94.7%) fixed | 🟢 Done |
| 3 | Rules: `rules/tag-guidelines.json` with policy, patterns, aliases_system | ✅ Created | 🟢 Done |
| 4 | Cross-reference enforcement | process-ingest.json step_4_tag_validation | 🟢 Done |
| 5 | Validation: lint-check for empty/generic tags | process-lint.json check_id=13 | 🟢 Done |

**Remaining:** Task #1 (research) — low priority, can be deferred.

### Phase 15.1: Frontmatter Architecture for Aliases & Discoverability 🆕
**Цель:** Добавить `aliases` field в universal frontmatter + integration across scripts.

| # | Component | What to change | Priority |
|---|-----------|---------------|----------|
| P1 | AGENTS.md universal frontmatter template | Add `aliases: []` field | 🔴 CRITICAL |
| P2 | `scripts/rebuild-meta.sh` parse_frontmatter() | Read aliases → store in registry.json | 🔴 CRITICAL |
| P3 | `wiki/index.md` rebuild logic | Show aliases after summary (max 2) | 🟡 HIGH |
| P4 | `scripts/lint.sh` check_aliases | Flag empty/missing aliases when ≥5 tags | 🟡 HIGH |
| P5 | process-ingest.json auto-extract step | Extract aliases during ingest | 🟡 HIGH |
| P6-P7 | wiki/templates/entity/concept-template.json | Add `aliases` to recommended fields | 🟢 LOW |
| P8 | Existing pages batch-update | Apply aliases (Loomana, pi-coding-agent, llm-wiki.md) | 🟢 LOW |

> **Зависит от:** Phase 15. Canonical rules: `rules/tag-guidelines.json#aliases_system`.

### Phase 16.1: Agent Memory Layer Architecture 🔴 P0
**Цель:** Отделить memory management в background subsystem (`scripts/memory/`), PRF-enhanced recall, trajectory capture → distillation pipeline.

| # | Task | Output | Status |
|---|------|--------|--------|
| 1 | Research: agent memory techniques (zero-dependency) | `wiki/concepts/agent-memory-management.md` | ✅ Done |
| 2 | Current state audit | Documented gaps — inline hooks, lexical-only recall | ✅ Done |
| 3 | PRF-enhanced recall engine | `scripts/memory/recall.sh` with stage_1_rank() | ✅ Done |
| 4 | Hot cache optimization | `scripts/memory/hot-cache-update.sh`, process-query.json step_0.25 | ✅ Done |
| 5 | Memory hooks extraction | `memory_hooks` in all process files, `traj-capture.sh`, `distill.sh` | ✅ Done |
| 6 | Trajectory capture | `scripts/memory/traj-capture.sh` | ✅ Done |
| 7 | Distillation pipeline | Skill/case generation, duplicate detection, check-undistilled mode | ✅ Done |
| 8 | PRF extraction & scoring | TF-IDF extractor + stopwords.txt + boost phase | ✅ Done |

**Design principles:** Background processing (async hooks), separation of concerns, zero dependencies.

---

## ⚡ Next Tasks — Phase 17: Script Architecture Hardening 🔴 P0-2 🆕

| # | Task | Description | Priority | Est. Time |
|---|------|-------------|----------|-----------|
| **T2** | Fix JSON safety (#45/#24) → `jq/python` | ✅ Completed — replaced all manual echo/printf with Python json.dumps() in classify-source.sh, auto-crosslink.sh, link-validator.sh, text-similarity.sh. Zero remaining manual JSON constructions. | 🔴 P0 CRITICAL | 1h |
| **T3** | Standardize `set -euo pipefail` (#46) | Add errexit to remaining scripts: `batch-ingest.sh`, `check-structural.sh`, `detect-contradications.sh`, `lint.sh`, `raw-correct.sh`, `rebuild-source-manifest.sh`. classify-source.sh already fixed. Where `set +e` intentional → comment why. | 🟡 P1 HIGH | 30m |
| **T4** | Unified walk in `rebuild-meta.sh` (#47) | Merge triple os.walk() (lines 99, 187, 358) into single pass like `unified-pass.sh`. Expected savings: -66% disk I/O. | 🟡 P2 MEDIUM | 45m |
| **T5** | Batch JSON reads (#48) → single python3 call | Consolidate N+1 calls in `lint.sh` (8+), `text-similarity.sh`. One Python process per script instead of fork-heavy loops. Expected savings: +2-5s/run. | 🟡 P2 MEDIUM | 1h |
| **T6** | Cleanup temp files via lib.sh | Integrate `cleanup_temp_files()` from lib.sh — currently dead code. Replace individual trap handlers with centralized cleanup_add(). | 🟢 P3 LOW | 30m |

> **Dependencies:** T5 requires T2 complete (prerequisite done).
> **Rollback plan:** All changes are additive/structural — safe to revert individual scripts.

---

## ✅ Completed Sessions (Archived)

- **Phase 16** (2026-07-05): Wiki Documentation Language Standardization → AGENTS.md + RULES.md fully translated, process files cleaned
- **Phase 14.5** (2026-07-05): Logic Restoration — Cascade Priority & Contradiction Resolution Flow → `rules/contradiction_resolution.json` created
- **Phase 13.4**: Section Template System → JSON templates in `wiki/templates/`
- **Phase 29** (2026-07-01): Delta Tracking → hash-based deduplication via `scripts/rebuild-source-manifest.sh`
- **Batch Ingest Workflow** (2026-07-01): `scripts/batch-ingest.sh` orchestrator
- **Schema Migration** (2026-06-29): dialog.md → AGENTS.md + process files

---

*Last update: 2026-07-06 | Active: Phase 15, Phase 15.1, Phase 16.1. Next: Phase 17 T2-T5 — script architecture hardening.*
