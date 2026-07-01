---
tags: [cache, system]
date: 2026-07-01
category: cache
sources: []
related: []
---
# Wiki Hot Cache — Last Updated: 2026-07-01

## Active Threads
- Phase 23 Step 3: unified-pass.sh integration into lint/ingest workflows (COMPLETED)
- Issue #10: Python scripts refactored to use logging module (COMPLETED)
- Issue #11: check-new-sources.sh trap handler fixed (COMPLETED)
- Lint.sh skip-check numbering bug fixed + hot_cache_stale_check wired (COMPLETED)

## Recent Changes
- **2026-07-01**: `scripts/unified-pass.sh` — added `--auto` flag + output normalization for auto-fix mode
- **2026-07-01**: `scripts/lint.sh` — check 8 replaced `link-validator.sh --auto` with `unified-pass.sh --quiet --skip-meta --skip-crosslinks --auto`
- **2026-07-01**: `process-lint.json` — check_id=7 command updated to unified-pass; duplicate check_id "8" fixed (hot_cache_stale_check → check_id "11")
- **2026-07-01**: `process-ingest.json` — step_3a/3b/6 link-validator calls replaced with unified-pass
- **2026-07-01**: `process-query.json` — step 3 finalization now runs check-wiki-changes.sh for hot.md staleness
- **2026-07-01**: `scripts/lint.sh` — check 11 (hot_cache_stale) added; fixed skip-check numbering (was matching wrong IDs)
- **2026-07-01**: `scripts/check-wiki-changes.sh` — fixed heredoc bug ($CHANGED not expanded)
- **2026-07-01**: `scripts/raw-link-repair.py`, `_detect_contradictions.py`, `h1-index.py`, `similarity_index.py` — refactored to use logging module for human messages (stderr), print() only for machine-readable JSON (stdout)

## Key Recent Facts
- Phase 23 (Unified Pass Architecture) is now fully COMPLETED — unified-pass.sh replaces 3 separate script walks
- lint.sh runs 11 checks total (was 10, added hot_cache_stale)
- All 4 Python scripts now use `logging.basicConfig(stream=sys.stderr)` for human-readable output
- `check-wiki-changes.sh` now correctly lists modified files in its output prompt
- After every session, `process-query.json` step 3 finalization checks wiki changes → agent updates hot.md
