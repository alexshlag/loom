# PLAN: Wiki Improvement Roadmap

---

## ✅ Completed (reference only)

| Phase | Feature | Commit |
|-------|----------|--------|
| 1-5 | Auto-rebuild meta, smarter search, non-blocking lint, index update, dynamic scoring | `1990a20` |
| 8 | Contradiction Deep Scan (Python-based) | `c368411` |
| 10 | Evidence-Based Priority System + frontmatter schema | `581b115` |
| 11.1 | Syndication Detection — `text-similarity.sh` | `258fa2c` |
| 12.1 | Decision Rules Framework — DR-1/DR-2/DR-3 | `c368411` |
| IF-1..IF-4 | Integration hooks: lint check_id=9, process refs, step_3c ingest scan | `b824a7` |

**Resolved from 06-28 audit**: P1 (shebangs), P2 (atomic writes), P3 (tests), P4 (error handling),
P5 (temp files), P6 (link validator limit), P7 (path guardrails), P9 (debug prints),
P12 (logging standard), P13 (trap handlers), P15 (minor fixes).

**Resolved from 06-28 session**: P8/#21 (heredoc injection → env var passing), #H3 (system file exclusion in detect-contradications), Phase 12.3 D6 (rebuild-meta auto-trigger after link-fix).

---

## ⬜ Unresolved — From 06-28 Audit

### Script fixes needed

| ID | Issue | Plan | Priority |
|----|-------|------|----------|
| **Phase 11.2** | Causal Chain Analysis | After schema migration → future priority | 🟡 Low |

### Deferred (strategic)

| ID | Issue | Status |
|----|-------|--------|
| **P10** | Redundant wiki walks — 3 full walks per ingest, can be unified | Large refactor → deferred | ⬜ Deferred |
| **P11** | Manual JSON construction in bash scripts (`echo/printf` vs `jq`) | Scripts already use `json.dump()` for complex output; only echo-level needs migration | ⬜ Deferred |
| **P14** | Scripts documentation — no unified docs for 15+ scripts | Nice-to-have → deferred to onboarding work | ⬜ Deferred |

---

## 🔄 Pending Feature Phases (from original roadmap)

### Phase 11.2: Causal Chain Analysis
**Цель**: Agent prompt для "X wrote first, Y copied from X" — causal chain analysis на основе overlap данных из text-similarity.sh
**Приоритет**: Low (after schema migration + issue fixes)

### Phase 12.2: Auto-Extract Assumptions
**Цель**: Агент автоматически экстрагирует assumptions из источников (источники с weak evidence помечать)
**Приоритет**: Future

---

## 🔄 Pending Phases

| Phase | Description | Priority |
|-------|-------------|----------|
| **Local Indexes** | `index.md` в каждой категории для линейного поиска вместо O(n²) + root index → краткий формат (categories + links only). **Depends**: F1 research on unique file naming before implementation. | High |
| Graph-Based Crosslinks | `auto-crosslink.sh` rewrite с shared-source analysis и scoring | Medium |
| Wiki Scalability (1000+ pages) | Optimizations: ripgrep, incremental rebuild, skip full rebuild >100 pages | Medium |

---

## 📝 Future Improvements (linked to issues.md)

| ID | Issue ID | Description | Status |
|----|----------|-------------|--------|
| F1 | #F1 (issues.md) | Root index format: `wiki/index.md` → краткий (categories + links). Research Wikipedia naming conventions + unique file naming rules. | 📝 Planning — discussion required |
| F2 | #F2 (issues.md) | Local indexes in every category folder with keywords/tags/first sentences. Requires rebuild-meta.sh update. | 📝 Planned — depends on F1 research |

> **Note**: Файл `h1-index.py` + `rebuild-meta.sh` генерируют index.md автоматически, не вручную агентом.

---

## ✅ Schema Migration — Dialog.md → AGENTS.md + process-файлы (Phase 12.4)

**Status**: ✅ **COMPLETED** (06-29) — all D1-D10 steps executed.

### Completed actions:
| Step | Action | Result |
|------|---------|--------|
| D1 | Link Conventions embedded from dialog.md#link_rules + EXT-LINK-V1 | AGENTS.md updated |
| D2 | DR-EX1 removed, auto-fix threshold from EXT-LINK-V1 kept | AGENTS.md cleaned |
| D3 | fetch_content_truncation.secondary_action removed (raw hierarchy example) | AGENTS.md cleaned |
| D4 | ZONE-DEF1 + META-DEF1 added to Protected Zones | AGENTS.md updated |
| D5 | EXT-RES1 embedded in process-ingest.json (EXT-1..EXT-4 merged) | process-ingest.json updated |
| D6 | BROKEN-REF1-v3 embedded, schema_ref fixed | process-query.json updated |
| D7 | check_id=7 reference fixed, fuzzy_matching removed from inline logic | process-lint.json updated |
| D8 | DUAL-MODE-LINT-1 modes added to lint_checks | process-lint.json updated |
| D9 | symfony.md raw/ link removed | wiki/entities/symfony.md cleaned |
| D10 | Full link-validator.sh --full passes — no regressions | All links valid |

### Cross-category exception:
- `../` allowed for cross-category wiki links (e.g. concepts/ ↔ syntheses/) as long as target exists under wiki/
- Updated in AGENTS.md Link Conventions section.

### Audit findings (06-29) — Что где находится сейчас

| # | Location | Issue | Action needed |
|---|----------|-------|---------------|
| **M1** | AGENTS.md `## 🔗 Link Conventions & Auto-Fix` + DR-EX1 inline JSON | Dублирует и конфликтует с dialog.md#EXT-LINK-V1 и dialog.md#link_rules | Заменить секцию на встраивание из dialog.md (link_rules + EXT-LINK-V1), убрать DR-EX1 |
| **M2** | AGENTS.md `## 🛡 Rules & Guardrails` → fetch_content_truncation.secondary_action | Ссылается на raw hierarchy — конфликт с CANONICAL-URL1 логику из dialog.md | Очистить: удалить пример raw hierarchy, оставить только web_search fallback |
| **M3** | AGENTS.md `### Protected Zones` | Не содержит ZONE-DEF1 и META-DEF1 из dialog.md | Встроить ZONE-DEF1 (raw→user, wiki→agent) + META-DEF1 (NEVER edit meta directly) |
| **M4** | process-ingest.json `step_1.5.external_source_policy` → EXT-1..EXT-4 | 4 правила дублируют dialog.md#EXT-RES1. Rule IDs не совпадают с canonical EXT-RES1. EXT-2 redundant (link-repair.sh уже делает это) | Заменить на встраивание EXT-RES1 из dialog.md, сохранить ingest-specific hooks (manifest creation, registry update) |
| **M5** | process-query.json `step_0.75.broken_link_awareness` → inline rules | external_wiki_pattern, create_page_or_remove, no_match_found дублируют/перекрываются с dialog.md#BROKEN-REF1-v3. Также schema_ref: AGENTS.md#decision_rules — неправильно | Заменить inline rules на встраивание BROKEN-REF1-v3 из dialog.md, исправить schema_ref → process-query.json#broken_link_awareness (или убрать если не нужен) |
| **M6** | process-lint.json `check_id=7.broken_link_auto_resole` → reference: AGENTS.md#link-conventions--auto-fix | Section path не существует в AGENTS.md. Также содержит inline fuzzy_matching, дублирующий dialog.md правила | Исправить reference → AGENTS.md#link-conventions (если секция будет), убрать inline fuzzy_matching логику, оставить только lint orchestration |
| **M7** | wiki/entities/symfony.md | Содержит `[text](raw/sources/...)` — prohibited pattern: links must not point to raw/, только metadata в frontmatter разрешено | Заменить на canonical URL или удалить ссылку |

### Migration plan (embedding, NOT schema_ref)

| Step | Action | Source → Target | Files affected | Status |
|------|---------|-----------------|---------------|--------|
| **D1** | Replace `## 🔗 Link Conventions & Auto-Fix` with dialog.md#link_rules + EXT-LINK-V1 (embedded inline) | dialog.md#link_rules + EXT-LINK-V1 → AGENTS.md### Link Conventions | AGENTS.md | ⬜ Pending |
| **D2** | Remove DR-EX1 inline JSON, keep only auto-fix threshold logic from EXT-LINK-V1 | EXT-LINK-V1.unavailability_check_policy → AGENTS.md### Link Conventions | AGENTS.md | ⬜ Pending |
| **D3** | Clean fetch_content_truncation.secondary_action — remove raw hierarchy example | Dialog canonical patterns → AGENTS.md#fetch_content_truncation | AGENTS.md | ⬜ Pending |
| **D4** | Add ZONE-DEF1 and META-DEF1 to `### Protected Zones` section | dialog.md#ZONE-DEF1 + #META-DEF1 → AGENTS.md### Protected Zones | AGENTS.md | ⬜ Pending |
| **D5** | Replace EXT-1..EXT-4 with embedded EXT-RES1 from dialog.md, keep only ingest hooks (manifest creation, registry update) | dialog.md#EXT-RES1 → process-ingest.json#step_1.5.external_source_policy | process-ingest.json | ⬜ Pending |
| **D6** | Replace inline rules in broken_link_awareness with embedded BROKEN-REF1-v3 from dialog.md, fix schema_ref | dialog.md#BROKEN-REF1-v3 → process-query.json#broken_link_awareness | process-query.json | ⬜ Pending |
| **D7** | Fix check_id=7 reference in process-lint.json to point to AGENTS.md#link-conventions (after D1), remove inline fuzzy_matching logic | — → process-lint.json### broken_link_auto_resole | process-lint.json | ⬜ Pending |
| **D8** | Add DUAL-MODE-LINT-1 modes reference to process-lint.json lint_checks section | dialog.md#DUAL-MODE-LINT-1 → process-lint.json (near check_id=7) | process-lint.json | ⬜ Pending |
| **D9** | Fix wiki/entities/symfony.md — replace `[text](raw/...)` with canonical URL or remove entirely | — → wiki/entities/symfony.md | wiki/entities/symfony.md | ⬜ Pending |
| **D10** | Run full `link-validator.sh --full` after all fixes to verify no regressions | — → All affected files | All | ⬜ Pending |

### Rule ID mapping (old → canonical)

| Old Location/ID | New Canonical ID | Target File | Action |
|-----------------|------------------|-------------|--------|
| EXT-1..EXT-4 (process-ingest.json) | dialog.md#EXT-RES1 | process-ingest.json#step_1.5.external_source_policy | Merge into single rule, keep ingest-specific hooks |
| DR-EX1 (AGENTS.md inline JSON) | dialog.md#EXT-LINK-V1 | AGENTS.md### Link Conventions → Auto-Fix section | Replace old policy with EXT-LINK-V1 embedding |
| BROKEN-REF1-v3 (dialog.md) | dialog.md#BROKEN-REF1-v3 | process-query.json#step_0.75.broken_link_awareness | Embed inline rules replacing external_wiki_pattern/create_page_or_remove/no_match_found |
| link_rules (dialog.md) | — | AGENTS.md### Link Conventions → Auto-Fix section | Embed internal_format, prohibited patterns, auto_fix_policy, crosslink_discovery |
| ZONE-DEF1 (dialog.md) | dialog.md#ZONE-DEF1 | AGENTS.md### Protected Zones section | Add raw/**=user, wiki/**=agent owner rules |
| META-DEF1 (dialog.md) | dialog.md#META-DEF1 | AGENTS.md### Protected Zones/meta/** section | Add "NEVER edit meta files directly" rule |
| DUAL-MODE-LINT-1 (dialog.md) | dialog.md#DUAL-MODE-LINT-1 | process-lint.json near check_id=7 | Add fast/deep mode reference to lint checks |

---

*Last update: 2026-06-29 | Schema migration plan corrected — Phase 12.4. All rules embedded, NOT referenced via schema_ref. Future improvements tracked (F1-F2 linked to issues.md).*
