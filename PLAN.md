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
| **T3** | Standardize `set -euo pipefail` (#46) | ✅ Done — added to: check-new-sources.sh, detect-contradications.sh (commented), structural-fix.sh, tag-audit.sh, check-wiki-changes.sh, load-hot-cache.sh, restore-hot-cache.sh, validate-path.sh. Fixed lib.sh function name mismatch (`cleanup_set_trap` → `_set_cleanup_trap`) and updated check-new-sources.sh comment. | 🟡 P1 HIGH | 30m |
| **T4** | Unified walk in `rebuild-meta.sh` (#47) | ✅ Done — merged registry + backlinks into single Python call (one JSON read, one fork). Eliminated triple os.walk() via wiki-walk.py. Expected savings: -66% disk I/O, ~0.5-1s/run. | 🟡 P2 MEDIUM | 45m |
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

## 🆕 Phase 19: Wiki Naming Collision Audit 🔴 P0
**Цель:** Предотвратить коллизии имён файлов при наполнении wiki из разных проектов. Добавить auto-detection + audit в lint workflow.

### Текущее состояние (аудит)
- **21 страница** нарушает rule `rules/naming_conventions.json#NAMES-CORE-V1`
- Symfony-specific concepts без префикса: messenger-component, twig-templating, assetmapper, routing-system, event-dispatcher, security-system, service-container, testing-strategy, workflow-state-machine
- **Exception list** не определён — агент не знает, что cache-system.md и hexagonal-architecture.md действительно абстрактные

### 📋 Tasks

| # | Component | Description | Dependencies | Status |
|---|-----------|-------------|--------------|--------|
| **N1** | Add exception list to `rules/naming_conventions.json` | Explicitly mark truly abstract concepts: cache-system.md, hexagonal-architecture.md, doctrine-orm.md. Add detection logic for framework-specific vs abstract. | None | ⬜ Pending |
| **N2** | Create `scripts/filename-audit.sh` | Scan wiki/ for naming violations: (a) concepts without project prefix when tags/sources indicate framework-specific; (b) entities/docs with bare concept names; (c) detect duplicates by base_name. Output JSON array of violations. | None | ⬜ Pending |
| **N3** | Add `filename_collision_audit` to process-lint.json check_id=6 | Integration into mechanical_linting: add check to existing array, reference schema_ref, define output format (severity: LOW/MEDIUM/HIGH). | N2 | ⬜ Pending |
| **N4** | Update `scripts/lint.sh` integration | Call filename-audit.sh from check 6, parse JSON output, update TOTAL_ISSUES counter. Add auto-fix detection for simple renames. | N3 | ✅ Done |
| **N5** | Fix process-query.json execute_save_path | Remove unnecessary schema_ref on naming_conventions — query doesn't write files directly, delegates to ingest. Clean up references. | None | ✅ Done |

---

### 📊 Results (Post-Implementation)
- **Found:** 10 pages in wiki/concepts/ violating naming conventions
- **Exceptions defined:** cache-system.md, hexagonal-architecture.md, doctrine-orm.md (truly abstract)
- **Violations flagged:** assetmapper, event-dispatcher, messenger-component, routing-system, security-system, service-container, sonata-admin-bundle, testing-strategy, twig-templating, workflow-state-machine
- **Auto-fix pending:** All 10 violations require user approval before rename (HIGH severity)
- **Lint integration:** Check 6 now includes filename_collision_audit → returns JSON with file path, severity, suggested new path

### Execution Order
```
✅ N1 (exception list) → ✅ N2 (audit script)
    ↓
✅ N3 (lint integration) ← depends on N2
    ↓
✅ N4 (lint.sh wiring) ← depends on N3
    ↓
✅ N5 (cleanup process-query.json)
```

### Expected Outputs
- `scripts/filename-audit.sh` — standalone audit script with --help, exit codes 0/1
- `process-lint.json` updated: check_id=6 includes filename_collision_audit
- `rules/naming_conventions.json` updated: exceptions section added
- Existing wiki pages flagged for rename (not auto-fixed — user approval required)

---

## ✅ Completed Sessions (Archived)

- **Phase 16** (2026-07-05): Wiki Documentation Language Standardization → AGENTS.md + RULES.md fully translated, process files cleaned
- **Phase 14.5** (2026-07-05): Logic Restoration — Cascade Priority & Contradiction Resolution Flow → `rules/contradiction_resolution.json` created
- **Phase 13.4**: Section Template System → JSON templates in `wiki/templates/`
- **Phase 29** (2026-07-01): Delta Tracking → hash-based deduplication via `scripts/rebuild-source-manifest.sh`
- **Batch Ingest Workflow** (2026-07-01): `scripts/batch-ingest.sh` orchestrator
- **Schema Migration** (2026-06-29): dialog.md → AGENTS.md + process files

---

## 🆕 Phase 20: Wiki Skills System Integration 🔴 P1
**Цель:** Активировать `wiki/skills/` как рабочую коллекцию навыков — определить формат, добавить в bootstrap, настроить auto-generation из повторяющихся задач.

### Problem Statement

`wiki/skills/` существует с одним файлом (`memory-hooks-integration-with-process_TRJ-2026.md`), но:
- Нет стандарта формата скилла
- Агент не сканирует эту директорию при старте
- Нет триггера для auto-generation из повторяющихся задач в ingest/query/lint
- Нет связи с `.pi/skills/` (runtime-навыки)

Инфраструктура вики (`schema_ref`, lazy loading, process files) идеально подходит — нужно добавить 4 слоя интеграции.

### 📐 Архитектура скилла в wiki

Файл скилла = `.md` с frontmatter и структурой:

```yaml
---
tags: [skill, <category>]
date: YYYY-MM-DD
type: documentation
category: note  # или skill (уникальная категория)
aliases: []
sources: [<raw paths>, web_search]
related: [<other wiki pages or skills>]
---
```

**Секции скилла:**

```markdown
# Skill: <Name>

## Procedure
- read: OK | edit: REQUIRED | write: NEVER

## Context
- Trigger: <when to use>
- Outcome: success | partial | blocked
- Complexity: low | medium | high

## Algorithm (REQUIRED)
1. Step one — with conditional logic if applicable
2. Step two
3. ...

## Dependencies
- rules/<name>.json (schema_ref path)

## Notes
- Distilled from trajectory "<TRJ-ID>".
```

### 📋 Tasks

| # | Component | Description | Dependencies | Status |
|---|-----------|-------------|--------------|--------|
| **S1** | Define skill format spec → `rules/skill_format.json` ... | None | ✅ Done |
| **S2** | Add skill scan to bootstrap → update `session_bootstrap.json` ... | S1 | ✅ Done |
| **S3** | Add auto-generation trigger to process-ingest.json ... | S1 | ✅ Done |
| **S4** | Add skill-awareness to process-query.json ... | S2 | ✅ Done |
| **S5** | Bridge: `.pi/skills/` ↔ `wiki/skills/` export script ... | None | ✅ Done |
### Execution Order

```
✅ S1 (format spec) → foundational reference for all other steps
    ↓
✅ S2 (bootstrap integration) ← depends on S1
    ↓
✅ S3 (auto-generation in ingest) ← depends on S1
✅ S4 (query awareness) ← parallel with S3, depends on S2
    ↓
✅ S5 (export script) ← optional, done last
```

### Status: All S1-S5 Complete ✅

---

## 🆕 Phase 20.2: Distillation Pipeline Fix & Auto-Trigger 🔴 P1
**Цель:** Исправить distill.sh (нарушает naming_convention) и добавить фактический auto-distillation trigger в memory_hooks.

### Problem Statement

`scripts/memory/distill.sh` создаёт скиллы без `-skill.md` суффикса → нарушение `rules/skill_format.json#naming_convention`. Memory hooks в process files вызывают только `--check-undistilled`, который сканирует, но не дистиллирует. Получается: траектории копились в `raw/trajectories/`, хуки проверяли их, но **нигде нет шага для автодистилляции**.

### 📋 Tasks

| # | Component | Description | Dependencies | Status |
|---|------|-------------|--------------|--------|
| **D1** | Fix `scripts/memory/distill.sh` naming — `{slug}-skill.md`. ✅ Done |
| **D2** | Add auto-distillation trigger after capture в memory_hooks — `distill.sh --trajectory <path>` after `traj-capture.sh`. Trigger: on_capture_complete. | D1, S5 | ✅ Done |

| **D3** | Update duplicate detection logic — slug regex for `-skill.md`. ✅ Done |

### Execution Order

```
✅ D1 (fix naming) ← foundational — без него не работает D3
    ↓
✅ D3 (duplicate detection) ← depends on D1 for correct slug matching
    ↓
✅ D2 (auto-trigger hooks) ← depends on D3, can be tested after
```

### Design Principles

1. **Naming convention is contract** — `distill.sh` должен следовать `rules/skill_format.json#naming_convention`, не игнрировать его (R07: naming rules ARE conditional logic)
2. **Hooks must distill, not just check** — `--check-undistilled` полезен как audit, но auto-trigger должен реально создавать скиллы из захваченных траекторий
3. **Idempotency preserved** — `check_duplicate_skill()` обновлён для нового формата, повторный дистилл одного trajectory → detect duplicate → skip
4. **No manual intervention required** — capture → distill цикл автоматический через hooks

### Expected Outputs
- Updated `scripts/memory/distill.sh` (naming + duplicate detection)
- Updated `process-ingest.json` memory_hooks → auto-distillation action after capture
- Updated `process-query.json` memory_hooks → same auto-distillation logic

## Phase 20.1: External Skill Search & Cross-Linking 🔴 P1
**Цель:** Когда query не находит релевантного скилла — проактивно предложить поискать в интернете, безопасно импортировать и связать с wiki docs.

### 📋 Tasks

| # | Component | Description | Dependencies | Status |
|---|-----------|-------------|--------------|--------|
| **S6** | `rules/skill_search_sources.json` — sources list for external skills | Curated URLs/repos where agent looks for quality skill definitions (e.g., skills.sh, GitHub org repos). No ad-hoc random search. | None | ✅ Done |
| **S7** | `rules/skill_safety_check.json` — safety check before importing | Validate: no malicious code execution, no credential harvesting patterns, reasonable scope. Reference existing rules/evidence_grade.json. | S6 | ✅ Done |
| **S8** | Query fallback chain → update `process-query.json` skill_awareness_check | If local skills don't match → propose external search to user → fetch from sources list → safety check → ask approval → ingest via process-ingest.json flow. | S7, S4 | ✅ Done |
| **S9** | Cross-linking in format spec → update `rules/skill_format.json` | Add `related_docs` field: skills link to relevant framework/language docs (e.g., skill "React Hooks" → links to wiki/docs/react-core.md). Auto-suggested via semantic matching. | S1 | ✅ Done |

### Execution Order

```
✅ S6 (sources list) → foundational for external search
    ↓
✅ S7 (safety check) ← depends on S6
    ↓
✅ S8 (query fallback chain) ← depends on S7 + S4
    ↓
✅ S9 (cross-linking spec) ← parallel with S8, updates S1
```

### Expected Outputs
- `rules/skill_search_sources.json` — curated source list for external skills
- `rules/skill_safety_check.json` — validation rules before importing
- Updated `process-query.json` → skill search fallback chain (if local fails → external)
- Updated `rules/skill_format.json` → added `related_docs` field with auto-suggestion logic

### Design Principles
1. **Curated sources only** — no random web crawling, strict source list (S6)
2. **Safety first** — validate before importing (R07: safety checks ARE conditional logic) (S7)
3. **User approval mandatory** — external skill import requires explicit user go-ahead
4. **Cross-links are auto-suggested** — agent proposes but doesn't enforce related docs (S9)

### Expected Outputs
- `rules/skill_format.json` — canonical format definition, referenced via schema_ref
- Updated `session_bootstrap.json` with skill scan step
- Updated `process-ingest.json` with auto-generation conditional logic
- Updated `process-query.json` with skill-awareness check
- `scripts/export-skill.sh` — optional bridge script
- Existing `wiki/skills/memory-hooks-integration-with-process_TRJ-2026.md` refactored to new format (via S1)

### Design Principles

1. **Non-blocking scan** — if wiki/skills/ is empty or corrupted, session continues
2. **Schema_ref for format** — all process files reference `rules/skill_format.json`, no duplication
3. **Auto-cleanup** — before writing to working_memory: filter completed/outdated skills (per session_context_rules.json)
4. **No auto-import** — .pi/skills/ remains SDK-managed; wiki/skills/ → .pi export requires explicit command