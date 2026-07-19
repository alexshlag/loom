## ⬜ Open / In Progress

### Issue #53: ??? (next issue number)
**Date**: ???

#### Description

(To be filled when new issue is discovered)

#### Status: ⬜ Open

---

## ✅ Closed

### Issue #52: Missing script references in rules/*.json and process-*.json
**Date**: 2026-07-19
**Trigger**: Manual audit of script paths in rules and process files

#### 🔍 Problem
Several script references pointed to non-existent scripts:
1. `scripts/create-commit-msg.sh` → `rules/create_commit_message.json` (existed in note, removed)
2. `scripts/hot-cache-update.sh` → `rules/session_context_rules.json:96` (file at `scripts/memory/`)
3. `scripts/glossary-cleanup.sh` → `process-lint.json:191` (never created)
4. `scripts/paths` → `rules/session_context_rules.json:32` (description text, not script)

#### ✅ Solution
1. Created `scripts/check-script-refs.sh` — scans rules/*.json and process-*.json for all `scripts/...` references, validates existence
2. Added as `check_id=17` in `process-lint.json` — runs automatically during lint
3. Fixed `scripts/hot-cache-update.sh` → `scripts/memory/hot-cache-update.sh` in session_context_rules.json
4. Created `scripts/glossary-cleanup.sh` (minimal stub — agent-driven per check_id=16)
5. Cleaned up `create_commit_message.json` note (removed stale ref)
6. Fixed `scripts/paths` → `scripts/*.sh` in description text

#### Status: ✅ Closed

---

> Last update: 2026-07-19 | Open issues: #53. | Closed: #11, #28, #46, #50, #22, #23, #24/#45, #47, #8, #49, #51, #52, #25, #48, T5, T6.

