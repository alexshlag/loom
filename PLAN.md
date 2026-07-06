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

## 🆕 Phase 18: Documentation & Manual Support System 🔴 P0
**Цель:** Расширить wiki на long-form documentation (user manuals, API references) и пакетную обработку кластеров источников в docs.

---

### 📐 Текущая Архитектура — Gap Analysis

| Компонент | Статус | Применимость к docs |
|-----------|--------|---------------------|
| **Ingest flow** (step_6_discussion) | ✅ Работает | Branching: entity_or_concept / update_existing — нет «doc» ветки |
| **Template system** (wiki/templates/) | ✅ 4 шаблона | entity/concept/synthesis/comparison — нет docs-template.json |
| **Categories** (categories.json) | ✅ 10 категорий | Нет «docs» категории |
| **Auto-crosslink** | ✅ Multi-level scoring | Работает для всех wiki pages — routing к wiki/docs/ не настроен |
| **rebuild-meta.sh → index.md** | ✅ Category-based index | Пока не генерирует docs section (нет docs в categories.json) |
| **Structural requirements** (FIRST-BLOCK-V1) | ✅ Mandatory body_text | Не подходит для docs — у них intro paragraph, а не «body_text между H1 и ##» |

#### Gaps

| # | Gap | Impact | Fix Required |
|---|-----|--------|--------------|
| **G1** | Нет `docs` category в categories.json | Pages в wiki/docs/ не индексируются, auto-crosslink routing не знает путь | Добавить «docs» → update auto_crosslink.sh routing |
| **G2** | DETERMINE_INTEGRATION_TYPE branching — нет «doc page» ветки | Agent создаёт entity/concept вместо docs при ≥3 framework sources | Добавить branch: `framework_cluster_detected → wiki/docs/<name>.md` |
| **G3** | Нет docs-template.json | Структура документации не стандартизирована | Создать шаблон с sections hierarchy + navigation pattern |
| **G4** | FIRST-BLOCK-V1 паттерн конфликтует с docs page | docs имеют intro paragraph, но не требуют body_text между H1 и ## | Добавить conditional rule для docs category |

---

### 🧠 Алгоритм: State Machine Routing (из aif-docs)

Вместо одного «create page» — **state-aware routing**:

```
STATE A: wiki/docs/ не существует → Generate framework overview + nav skeleton
         → docs-template.json с getting-started, architecture, api sections
         → Создать wiki/docs-index.md как landing для docs section
         → Обновить categories.json (docs category)

STATE B: wiki/docs/ существует, но pages orphaned → Audit & restructure
         → Запустить audit (broken links, missing crosslinks, stale content)
         → Предложить пользователю: merge duplicates, add navigation, fix broken links

STATE C: Mature wiki/docs/ → Deep-dive topics only
         → Только новые deep-dives (не overview — overview уже есть)
         → Suggest merges если pages are overlapping
```

#### Routing Logic

Плоская структура `wiki/docs/<name>.md` — **без вложенных директорий**. Префиксы (`php-api.md`, `php-cli.md`) решают группировку без изменения скриптов.

```json
{
  "rule_id": "DOC-ROUTING-V1",
  "routing_table": [
    { "source_type": "framework_overview_cluster",    "target_path": "wiki/docs/<framework>.md" },
    { "source_type": "api_reference_cluster",         "target_path": "wiki/docs/<framework>-api.md" },
    { "source_type": "cli_tool_cluster",              "target_path": "wiki/docs/<tool>-commands.md" }
  ]
}
```

Agent auto-detects type by source analysis (API docs → `-api` suffix, CLI docs → `-commands` suffix). No hardcoded paths.

---

### 🔧 Tasks

| # | Component | Description | Dependencies | Status |
|---|-----------|-------------|--------------|--------|
| **D1** | `wiki/templates/docs-template.json` | Шаблон для документации: Getting Started, API Reference, CLI Commands, Configuration. Sections hierarchy + navigation header/footer pattern + crosslinking к entities/concepts. | None | ✅ Done |
| **D2** | `rules/categories.json` → add "docs" category | `"docs": "Long-form technical documentation, user manuals, guides (not entity profiles)"`. Auto-crosslink.sh routing обновится автоматически (он read categories.json). | D1 | ✅ Done |
| **D3** | `process-ingest.json` step_6_discussion: docs branching | Agent decision tree: framework cluster → state-aware action. Branching к STATE A/B/C. Добавить condition в action_name `DETERMINE_DOCS_INTEGRATION_TYPE`. | D2, template D1 | ✅ Done |
| **D4** | `rules/structural_requirements.json` → DOC-PAGE-V1 | Pattern для docs pages: intro paragraph вместо body_text между H1 и ##; navigation header mandatory (prev/next/index); See Also section required. | D3 | ✅ Done |
| **D5** | `scripts/docs-audit.sh` — audit mode | Check for: broken links in wiki/docs/, missing nav headers, orphaned docs pages, duplicate/overlapping content. Run on STATE B detection. | None | ✅ Done |

#### Execution Order

```
✅ D1 (template) → ✅ D2 (categories.json) → ✅ D3 (process-ingest branching)
    ↓
✅ D4 (structural requirements for docs) ← depends on D2+D3
    ↓
✅ D5 (docs-audit.sh) — optional, can be parallel with D4
```

#### Implementation Notes

- **STATE A ready**: `wiki/docs/` не существует → при next ingest с framework cluster agent запустит STATE A routing (overview generation + docs-index.md)
- **Auto-crosslink routing**: categories.json обновлён, auto_crosslink.sh автоматически начнёт использовать wiki/docs/ path для docs category
- **docs-audit.sh**: Tested — correctly detects STATE A and exits clean. Will run on STATE B detection during ingest workflow.

---

### 📚 Источники Информации

| Источник | Что из него взяли | Применимость |
|----------|-------------------|--------------|
| [aif-docs SKILL.md](https://github.com/lee-to/ai-factory/blob/2.x/skills/aif-docs/SKILL.md) | State machine (A/B/C), navigation header/footer pattern, prev/next links + See Also footer | ✅ Highly applicable — state-aware routing + nav pattern |
| [wiki-page-writer (Microsoft)](https://skills.sh/microsoft/agent-skills/wiki-page-writer) | Evidence-based deep-dive pages, source repository resolution | ⚠️ Partially — для entity/concept generation лучше, чем docs |

---

> **Зависит от:** Phase 15.1 P8-P9 (aliases integration affects all new pages).
> **Связано:** `AGENTS.md#batch_ingest_trigger`, `scripts/batch-ingest.sh --scan`
> **Rollback plan:** Все изменения — additive/structural, safe to revert individual files.

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
