---
tags: [cache, system]
date: 2026-07-08
category: note
sources: []
related: []
---
# Wiki Hot Cache — Last Updated: 2026-07-08

## Active Project (WORK_MODE: project)
- **Project**: Loomana wiki architecture optimization + knowledge management
- **Status**: 🟢 ACTIVE SESSION — Wiki maintenance and expansion

## Active Session Context
- **Focus node**: Phase 24 completed: unified memory sync contract

### Pending Tasks
- **review session_context_rules.json for unified context budget rules**

## Recent Changes
  No recent log entries

## System State
### Active Threads
- Wiki maintenance and expansion (auto-fixes running on lint errors)
- Knowledge base growth via query responses and source ingestion

- **Recent activity**: fix_json_comments | Removed invalid // inline comments from context-scopes.json — replaced with schema_ref field; validated all 12 rules/*.json files pass json.tool
- **Recent activity**: agENTS_reduction | AGENTS.md reduced from 676 to 447 lines (-230 lines, ~14KB saved): extracted Auto-rebuild/Lint rules → auto_rebuild_metadata.json + non_blocking_lint.json (enriched), Wiki Snapshot JSON-block → snapshot_format.json (new), Language Policy → language_policy.json (new), removed Evidence Grade inline table → already in evidence_grade.json, removed Schema Inheritance Canonical References dead-weight table; total rules/*: 28 files (~1030 lines); commit: 5f40f6e
- **Recent activity**: schema | added STI-V1 rule (source_transient_ingest.json) — sources are transient, read→extract→wiki→forget; prevents context bloat during multi-source ingest
- **Recent activity**: docs | Phase 23: ingested 7 source documents → wiki/docs/ following STI-V1 transient rule
