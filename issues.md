## 🔴 Open / In Progress

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

> Last update: 2026-07-19 | Open issues: #51. | Closed: #11, #28, #46, #50, #22, #23, #24/#45, #47, #8, #49, #52, #25, #48, T5.

