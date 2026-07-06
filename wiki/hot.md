---
tags: [cache, system]
date: 2026-07-07
category: note
sources: []
related: []
---
# Wiki Hot Cache — Last Updated: 2026-07-07

## Active Project (WORK_MODE: project)
- **Project**: Loomana wiki architecture optimization + knowledge management
- **Status**: 🟡 ACTIVE — Phase 17 Script Hardening in progress (T3 ✅, T4 ✅, T6 🔄) (naming convention fix + duplicate detection)

## Active Session Context
  WM read failed — using defaults

## Recent Changes
  - **[2026-07-07] phase17 | T3 completed — added errexit to batch-ingest, check-structural, lint, raw-correct, rebuild-source-manifest**
  - **[2026-07-07] phase17 | T4 confirmed — rebuild-meta.sh already uses wiki-walk.py single-pass (no triple walk)**
  - **[2026-07-07] phase17 | T6 🔄 — lib.sh cleanup_temp_files() added, lint.sh + rebuild-meta.sh migrated to centralized cleanup_add pattern

## System State
### Active Threads
- Wiki maintenance and expansion (auto-fixes running on lint errors)
- Knowledge base growth via query responses and source ingestion

- **Recent activity**: compact_json_rules | JSON instruction compactification — rules/*.json and AGENTS.md §9 integration
- **Recent activity**: fix_json_comments | Removed invalid // inline comments from context-scopes.json — replaced with schema_ref field; validated all 12 rules/*.json files pass json.tool
- **Recent activity**: agENTS_reduction | AGENTS.md reduced from 676 to 447 lines (-230 lines, ~14KB saved): extracted Auto-rebuild/Lint rules → auto_rebuild_metadata.json + non_blocking_lint.json (enriched), Wiki Snapshot JSON-block → snapshot_format.json (new), Language Policy → language_policy.json (new), removed Evidence Grade inline table → already in evidence_grade.json, removed Schema Inheritance Canonical References dead-weight table; total rules/*: 28 files (~1030 lines); commit: 5f40f6e
