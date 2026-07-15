## 🔴 Open / In Progress

### Issue #11: Trap Handlers для Cleanup
**Проблема:** Часть скриптов не использует `trap EXIT/cleanup`.
**Status:** ⬜ Open — `rebuild-meta.sh` still missing the trap.

### Issue #28: Page Templates Co-evolution
**Проблема:** AGENTS.md содержит секции Template Editing Policy и Template Co-evolution Process, но фактическая работа не завершена.
**Status:** ⬜ Open — requires discussion + user approval.

### Issue #46: Inconsistent `set -euo pipefail`
**Проблема:** Из 30 скриптов только 16 используют полный `set -euo pipefail`. Остальные либо без `-e`, либо `set +e`.
**Затронутые:** ❌ Без `-e`: `batch-ingest.sh`, `check-structural.sh`, `classify-source.sh`, `detect-contradications.sh`, `lint.sh`, `raw-correct.sh`, `rebuild-source-manifest.sh`.
⚠️ Явный `set +e` только в `detect-contradications.sh:23`.
**Status:** 🟡 Partial — 2 remaining: `benchmark-rebuild.sh` (no `set` at all), `text-similarity.sh` (`set -uo pipefail` missing `-e`).

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

---

> Last update: 2026-07-15 | Open issues: #11, #28, #46, #50, #51. | Closed: #22, #23, #24/#45, #47, #8, #49, #52, #25, #48, T5.