# PLAN: Wiki Improvement Roadmap

---

## ✅ Completed — 2026-07-01 Session

### Phase 13.2: Batch Ingest Workflow ✅ COMPLETED
**Цель**: Cross-reference между новыми источниками + bulk-update index/hot/log.

**Этапы реализации:**
| Step | Task | Effort | Status |
|------|------|--------|--------|
| **1** | Разделить интеллект (агент) vs автоматизация (скрипт) — дизайн решения | Low | ✅ Done |
| **2** | Создать `scripts/batch-ingest.sh` + `_batch_ingest.py` для кластеризации | Medium | ✅ Done |
| **3** | Добавить batch workflow в AGENTS.md → process-ingest.json step 1.5_batch | High | ✅ Done |

**Зависимости**: Нет.
**Связано**: `issues.md#30`

---

## 🔄 Pending Feature Phases (from original roadmap)

### Phase 29: Raw Corrected Zone + Delta Tracking 🥇
**Цель**: Добавить zone `raw/corrected/` для agent-writable processed copies, обеспечить delta tracking и correct source referencing.

**Проблема:**
- raw/** — read-only для агента (immutable originals)
- wiki pages ссылаются на frontmatter sources: [] — но нет механизма re-read оригиналов при contradiction
- Agent не может хранить обработанные версии рядом с оригиналами → дублирование в wiki/

**Решение:** `raw/corrected/SRC-*/` — agent-writable zone для processed copies.

**Этапы реализации:**
| Step | Task | Owner | Effort | Status |
|------|------|-------|--------|--------|
| **1** | Обновить `validate-path.sh`: добавить `raw/corrected/` в ALLOWED_WRITE_ZONES | Agent | Low | ⬜ Next |
| **2** | Создать `scripts/raw-correct.sh` — agent вызов для создания corrected copy (валидирует путь, формат) | Agent | Medium | ⬜ After step 1 |
| **3** | Обновить process-ingest.json: add post-processing step после capture → agent сохраняет corrected copy в raw/corrected/SRC-*/ | Agent | High | ⬜ After step 2 |
| **4** | Обновить AGENTS.md: правила original vs corrected, wiki referencing pattern, delta tracking integration | Agent | Medium | ⬜ After step 3 |

**Зависимости**: Sequential (1→2→3→4). Каждый шаг требует testing before next.
**Связано**: `issues.md#29` (delta tracking placement), `issues.md#32` (wiki sources structure)

---

### Phase 13: Wiki Page Templates Schema (#H4) 🥈
**Цель**: Единый, полный, не-разрозненный набор per-type format descriptions для всех типов wiki pages.
**Связан с**: `issues.md#H4`
**Приоритет**: Medium — требуется before any new ingest or synthesis creation

### Phase 12.2: Auto-Extract Assumptions 🥉
**Цель**: Агент автоматически экстрагирует assumptions из источников (источники с weak evidence помечать)
**Приоритет**: Future

---

## 🔄 Pending Phases

| Phase | Description | Priority |
|-------|-------------|----------|
| **S5** | Search analytics → popularity boost in `score_page()`. Read meta/search_analytics.json → add +frequency_boost to pages that appeared in popular queries. Soft signal only — never filters results. | High |
| **Local Indexes** | `index.md` в каждой категории для линейного поиска вместо O(n²) + root index → краткий формат (categories + links only). **Depends**: F1 research on unique file naming before implementation. | High |
| Graph-Based Crosslinks | `auto-crosslink.sh` rewrite с shared-source analysis и scoring | Medium |
| Wiki Scalability (1000+ pages) | Optimizations: ripgrep, incremental rebuild, skip full rebuild >100 pages | Medium |

---

## 📝 Phase 29 Deep-Dive Analysis — Raw Corrected Zone Architecture

### 🔍 Problem Statement

#### Current setup (before raw/corrected):
```bash
# Originals (immutable)
raw/SRC-001/pi-dev-docs-latest.md          # ← original, agent read-only

# Wiki pages reference via frontmatter (broken chain)
wiki/entities/pi-coding-agent.md:
  sources: ["https://pi.dev/docs/latest"]   # ← external URL only!
```

**Проблемы:**
1. **No audit trail**: Agent can't re-read original source for contradiction resolution
2. **No delta tracking**: Agent doesn't know if raw/SRC-001 was already processed → waste of tokens on re-ingest
3. **Broken link chain**: Wiki references external URL, but agent needs intermediate processing step (fix paths, OCR errors, extract entities)

#### Proposed architecture:
```bash
# Layer 1: Originals (immutable, agent read-only)
raw/SRC-001/pi-dev-docs-latest.md          # ← original, never modified by agent

# Layer 2: Corrected copies (agent rw, full access)
raw/corrected/SRC-001/pi-dev-docs-latest.md   # ← agent writes corrected version here
                                                  #     - fixed broken links to external URLs
                                                  #     - OCR errors from capture process
                                                  #     - extracted entities/tags as markdown

# Layer 3: Wiki pages reference Layer 2
wiki/entities/pi-coding-agent.md:
  sources: ["raw/corrected/SRC-001/pi-dev-docs-latest.md"]   # ← corrected copy!
```

### 🛡 Guardrails for raw/corrected/:

#### validate-path.sh changes:
```bash
# Current:
ALLOWED_WRITE_ZONES=("raw/sources/" "wiki/")

# After Phase 29:
ALLOWED_WRITE_ZONES=("raw/corrected/**/*" "wiki/")   # ← agent rw zone added
PROTECTED_PATTERNS=("meta/")                        # ← unchanged
```

#### Agent write rules for raw/corrected/:
1. ✅ Agent can create/write `.md`, `.json`, `.txt` files in `raw/corrected/SRC-*/*`
2. ❌ Agent cannot modify originals in `raw/SRC-*/original.*` (read-only)
3. ❌ Agent cannot delete/move original files
4. ✅ Agent-generated files must use naming convention: `{filename}` or `_extracted-{filename}`

### 🔄 Integration with existing processes:

#### process-ingest.json integration points:

**Step 0 (capture)** — unchanged: agent reads source, saves to raw/SRC-*/
**Step 1 (source analysis)** — NEW: after reading original → agent creates corrected copy in raw/corrected/
**Step 2 (discussion with user)** — NEW: agent presents summary from corrected copy
**Step 3a (integration_new_page)** — updated: wiki pages reference `raw/corrected/SRC-*/` instead of originals
**Step 1.5_batch (batch ingest)** — enhanced: batch scanner reads raw/corrected/ files, not originals

#### Delta Tracking integration:

```bash
# raw/corrected/SRC-001/.manifest.json ← agent-generated delta tracking file
{
  "original_path": "raw/SRC-001/pi-dev-docs-latest.md",
  "corrected_path": "raw/corrected/SRC-001/pi-dev-docs-latest.md",
  "hash_original": "abc123...",
  "hash_corrected": "def456...",
  "date_ingested": "2026-07-01",
  "status": "processed"
}
```

**Delta check flow:**
1. Agent receives new source → hash of original
2. Check meta/source-manifest.json for existing entry with same hash
3. If found → skip re-ingest (already processed)
4. If not found → create corrected copy in raw/corrected/, write manifest, proceed

#### Contradiction Resolution integration:

**Current:** wiki pages have sources: [] but no way to trace back to original source for comparison.

**After Phase 29:**
```yaml
# wiki/entities/pi-coding-agent.md:
---
sources: ["raw/corrected/SRC-001/pi-dev-docs-latest.md"]
---
## Definition
[Current facts from corrected copy]
## Обновлено [date] — новое уточнение
[Facts from new source that contradicts existing]
```

**Resolution flow:**
1. Agent detects contradiction → reads wiki page → gets sources: ["raw/corrected/SRC-001/..."]
2. Agent reads meta/source-manifest.json → finds original_path + hash_original
3. Agent re-reads raw/SRC-001/original (immutable) for comparison
4. Compare facts from current wiki vs original source → resolve based on cascade priority

### 📊 Impact assessment:

| Aspect | Before Phase 29 | After Phase 29 | Change |
|--------|-----------------|---------------|--------|
| **Audit trail** | None — agent can't trace back to source | raw/corrected/ + manifest.json → full chain | ✅ Major improvement |
| **Contradiction resolution** | Blind cascade priority (code > docs) | Source re-read via original_path in manifest | ✅ Major improvement |
| **Delta tracking** | meta/source-manifest.json only | raw/corrected/.manifest.json + hash check | ✅ Enhanced |
| **Wiki references** | External URLs or frontmatter-only | Direct links to corrected copies (rw zone) | ✅ Cleaner chain |

### 📋 Implementation order:

1. **Step 1**: Update `validate-path.sh` → add raw/corrected/ to ALLOWED_WRITE_ZONES
   - Test: agent can write to raw/corrected/SRC-001/test.md ✓
   
2. **Step 2**: Create `scripts/raw-correct.sh` — safe write wrapper for agent
   - API: `--add "raw/corrected/SRC-001/file.md" content...`
   - Validates path prefix, JSON format (for .json files), prevents original modification
   
3. **Step 3**: Update process-ingest.json → add post-processing step after capture
   - Step 1: After reading raw/SRC-*/original → agent creates corrected copy in raw/corrected/
   - Wiki pages reference corrected copies via sources: [] field
   
4. **Step 4**: Update AGENTS.md + delta tracking integration (Phase 29, step 3)
   - Document rules about original vs corrected files
   - Add manifest.json generation to ingest flow

### ⚠️ Risks & Mitigations:

| Risk | Severity | Mitigation |
|------|----------|------------|
| Agent accidentally modifies originals in raw/SRC-*/ | HIGH | validate-path.sh blocks writes to raw/** except raw/corrected/ |
| Agent creates malformed JSON in .manifest files | MEDIUM | scripts/raw-correct.sh validates format before writing |
| Corrected copies get out of sync with originals | LOW | manifest.json stores hash_original → agent can verify if corrected is stale |

---

## ✅ Schema Migration — Dialog.md → AGENTS.md + process-файлы (Phase 12.4)

**Status**: ✅ **COMPLETED** (06-29) — all rules embedded in AGENTS.md / process files.
> Note: `dialog.md` has been removed after migration. All references are now inline/embedded in target files.

### Completed actions:
| Step | Action | Result |
|------|---------|--------|
| D1-D2 | Link Conventions + EXT-RES1 embedded, DR-EX1 removed | AGENTS.md updated |
| D3 | fetch_content_truncation.secondary_action cleaned (raw hierarchy example removed) | AGENTS.md cleaned |
| D4 | ZONE-DEF1 + META-DEF1 added to Protected Zones | AGENTS.md updated |
| D5 | EXT-RES1 embedded in process-ingest.json (EXT-1..EXT-4 merged into single rule) | process-ingest.json updated |
| D6 | BROKEN-REF1-v3 embedded, schema_ref fixed | process-query.json updated |
| D7 | check_id=7 reference fixed, fuzzy_matching removed from inline logic | process-lint.json updated |
| D8 | DUAL-MODE-LINT-1 modes added to lint_checks | process-lint.json updated |

### Cross-category exception:
- `../` allowed for cross-category wiki links (e.g. concepts/ ↔ syntheses/) as long as target exists under wiki/
- Updated in AGENTS.md Link Conventions section.


---

*Last update: 2026-07-01 | Phase 29 Deep-Dive Analysis — Raw Corrected Zone Architecture added. Phase 13.2 Batch Ingest Workflow completed (Phase 14 deferred pending raw/corrected implementation).*
