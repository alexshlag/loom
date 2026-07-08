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
- **Current focus**: Memory optimization for ingest — STI-V1 rule (sources transient, never hold multiple sources simultaneously)
- **Active work**: Implementing source memory lifecycle contract to prevent context window bloat

## Recent Changes
  No recent log entries

## System State
### Active Threads
- Wiki maintenance and expansion (auto-fixes running on lint errors)
- Knowledge base growth via query responses and source ingestion

- **Recent activity**: ### Files changed:
- **Recent activity**: compact_json_rules | JSON instruction compactification — rules/*.json and AGENTS.md §9 integration
- **Recent activity**: fix_json_comments | Removed invalid // inline comments from context-scopes.json — replaced with schema_ref field; validated all 12 rules/*.json files pass json.tool
- **Recent activity**: agENTS_reduction | AGENTS.md reduced from 676 to 447 lines (-230 lines, ~14KB saved): extracted Auto-rebuild/Lint rules → auto_rebuild_metadata.json + non_blocking_lint.json (enriched), Wiki Snapshot JSON-block → snapshot_format.json (new), Language Policy → language_policy.json (new), removed Evidence Grade inline table → already in evidence_grade.json, removed Schema Inheritance Canonical References dead-weight table; total rules/*: 28 files (~1030 lines); commit: 5f40f6e
