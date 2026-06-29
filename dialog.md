# dialog.md — DEPRECATED (schema migrated 2026-06-29)

**Status**: All rules from this file have been embedded into AGENTS.md and process-files.
This file is preserved as historical reference only. Do not reference via `schema_ref`.

## Migrated Rules (see PLAN.md Phase 12.4 for details)

| Rule ID | Target File | Status |
|---------|-------------|--------|
| link_rules | AGENTS.md#link-conventions | ✅ Embedded |
| EXT-LINK-V1 | AGENTS.md#link-conventions → Auto-Fix section | ✅ Embedded |
| ZONE-DEF1 | AGENTS.md### Protected Zones | ✅ Embedded |
| META-DEF1 | AGENTS.md### Protected Zones/meta/** | ✅ Embedded |
| EXT-RES1 | process-ingest.json#step_1.5.external_source_policy | ✅ Embedded (merged EXT-1..EXT-4) |
| BROKEN-REF1-v3 | process-query.json#broken_link_awareness | ✅ Embedded |
| DUAL-MODE-LINT-1 | process-lint.json near check_id=7 | ✅ Embedded |

**Note**: All rules are now in target files directly. Never use `schema_ref → dialog.md`.
