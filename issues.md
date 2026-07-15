# Issues — Wiki Audit Tracker

---

## 🔴 Open / In Progress

### Issue #11: Trap Handlers для Cleanup
**Проблема:** Часть скриптов не использует `trap EXIT/cleanup`.
**Status:** 🟡 Partial — 3/4 fixed. `lint.sh`, `check-new-sources.sh` have `_set_cleanup_trap`; `text-similarity.sh` has basic `trap EXIT`; **`rebuild-meta.sh` still missing the trap**.

### Issue #28: Page Templates Co-evolution
**Проблема:** AGENTS.md содержит секции Template Editing Policy и Template Co-evolution Process, но фактическая работа не завершена.
**Status:** ⬜ Open — requires discussion + user approval.

### Issue #25: `check_id` Numbering Inconsistency
**Проблема:** `lint.sh` comments пишут `Check 4/9` для check_id=3, `Check 5/9` для check_id=5. Нумерация не совпадает с AGENTS.md и process-lint.json.
**Status:** ⬜ Open — lint.sh has mixed formats: `Check 3/10`, `Check 5/10` vs `Check 11/11`, `Check 12/12`.

### Issue #46: Inconsistent `set -euo pipefail`
**Проблема:** Из 30 скриптов только 16 используют полный `set -euo pipefail`. Остальные либо без `-e`, либо `set +e`.
**Затронутые:** ❌ Без `-e`: `batch-ingest.sh`, `check-structural.sh`, `classify-source.sh`, `detect-contradications.sh`, `lint.sh`, `raw-correct.sh`, `rebuild-source-manifest.sh`.
⚠️ Явный `set +e` только в `detect-contradications.sh:23`.
**Status:** 🟡 Partial — 2 remaining: `benchmark-rebuild.sh` (no `set` at all), `text-similarity.sh` (`set -uo pipefail` missing `-e`).

### Issue #48: N+1 Python3 Calls Pattern
**Проблема:** Десятки отдельных subprocess вызовов в циклах → fork overhead × 10-40 на скрипт.
**Затронутые:** `lint.sh` (11), `text-similarity.sh` (13).
**Status:** ⬜ Open — T5 pending.

### Issue #50: Lint Execution Difficulties & Script Delegation Gaps
**Date**: 2026-07-08
**Trigger:** Full wiki audit via process-lint.json, all 15 checks executed.

#### ⚠️ Difficulties Encountered

1. **Structural violations (16 files) — regex patterns failed on first pass**
   - Problem: `check-structural.sh` finds pages where body text exists between H1 and first ## with no intro paragraph
   - Root cause: Lint JSON reports `{path, h1_line, first_h2_line}` but doesn't include the actual content that needs fixing
   - **Fix**: `check-structural.sh` should output actionable JSON with suggested intro text based on page title

2. **Orphan pages — agent review required before any link insertion**
   - Root cause: heuristic scoring doesn't understand WHY a page is orphaned (deleted source? missed ingest? intentional unlinking?)
   - **Fix**: Create `scripts/orphan-report.sh` → returns JSON {orphans[], suggestions[]}. Agent reviews each suggestion.

3. **Hot cache stale detection — auto-refresh runs silently**
   - Root cause: Script redirects to /dev/null in process-lint.json; may be failing silently
   - **Fix**: Either add JSON return values or remove from post_lint_actions until script produces meaningful output

4. **Contradictions discrepancy: Check 1 found 3, Check 9 found 0**
   - Root cause: check_id=1 is soft-only (grep), doesn't validate actual contradiction content
   - **Fix**: Update process-lint.json#check_id=1 description to clarify "soft check"

5. **Excessive empty lines — pattern detection unreliable**
   - Problem: regex `{3,}` sometimes misses edge cases
   - **Fix**: Single unified pass in `scripts/clean-markdown-whitespace.sh` with proper handling

#### ✅ What Lint.sh Already Does Well
- Check 8 (broken links): unified-pass.sh --auto successfully auto-repairs and reports agent_review_required
- Check 12+13: Tag audit + frontmatter insertion work automatically
- JSON output on stdout: Clean machine-parseable format for downstream processing

*Status: ⬜ Open — remaining gaps in auto-fix modes, hot cache feedback.*


### Issue #51: Agent Inline Python During Lint — Should Be Scripts Instead
**Date**: 2026-07-08  
**Trigger:** Full wiki audit via process-lint.json — agent wrote inline Python for tasks that should be in scripts.

#### 🤖 Problem: Agent Overstepping into Script Territory

During lint execution, the agent wrote **inline Python scripts** for tasks that should have been handled by dedicated shell/python scripts:
1. Structural violations fix → Should use `check-structural.sh --auto-fix`
2. Orphan page crosslinks → Should use existing `auto-crosslink.sh --auto-fix-high-confidence`
3. Wiki index docs section injection → Should be `scripts/add-index-links.sh`

#### ✅ Solution: Script-First Architecture During Lint

**Rule**: During lint execution, agent **MUST NOT write inline Python**. All tasks must go through scripts.

*Status: ⬜ Open — requires creating missing scripts and updating process-lint.json auto_fix_phase.*


### Issue #52: Missing Discovery Step in Development Workflow
**Date**: 2026-07-08  
**Trigger:** Analysis of context optimization gap — agent wrote new rule/script instead of extending existing infrastructure.

#### 🧠 Problem Statement

RULES.md §9 R01-R08 defines principles of compactification (do not duplicate, write once, minimal context) but **lacks explicit discovery step before implementation**. Agent transitions directly from PLAN → IMPLEMENTATION without scanning existing rules/scripts for related logic.

**What was missing:**
- No explicit "check existing infrastructure" trigger between Plan and Implementation steps
- R01 says "Do not duplicate existing rules (schema_ref)" but doesn't say "CHECK FIRST — scan rules/ scripts/"
- §11 TASK EXECUTION CYCLE workflow: Problem → Discussion → Plan → **IMPLEMENTATION** (skip discovery) → Verify → Document → Git

**Consequence observed:** Agent created `rules/memory-sync-at-task-end.md` + `scripts/memory/sync-working-memory.sh` instead of extending existing `hot-cache-auto-refresh.sh` logic or adding one-line instruction to existing workflow.

#### 🔍 Root Causes in RULES.md

| Section | What it says | What's missing |
|---------|-------------|----------------|
| §9 R01 | "Do not duplicate existing rules" | No step: "BEFORE writing → scan existing rules/scripts" |
| §9 R02 | "Each rule written ONCE" | No step: "Find already written logic first" |
| §11 TASK EXECUTION CYCLE | Problem → Plan → Implementation → Verify... | Missing discovery step between Plan and Implementation |

#### 📍 Where to Add Discovery Step

**Option A (preferred):** Add single sentence to R01 in RULES.md §9:
> **BEFORE writing anything new → scan `rules/` and `scripts/` for related logic. If found → extend it or reference via schema_ref — do NOT create new file.**

**Option B:** Add step 3.5 between Plan (step 3) and Implementation (step 4) in §11:
> **3.5 DISCOVERY → scan existing rules/ scripts/ for related logic before implementation. If pattern exists → extend, don't duplicate.**

#### ⚠️ Impact on Context Optimization

When agent skips discovery:
- Creates new files instead of extending existing ones → context bloat
- Duplicates logic that already exists in memory → wasted tokens
- Breaks progressive disclosure principle (R04) — loads more files per session

*Status: 🟡 In Progress — awaiting schema-patch proposal to add discovery step.*

---

> Last update: 2026-07-15 | Open issues: #11, #28, #25, #46, #48, #50, #51. | Closed: #22, #23, #24/#45, #47, #8, #49, #52.
