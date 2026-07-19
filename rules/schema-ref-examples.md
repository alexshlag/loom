# Schema Ref Examples — Broken Link Fixing Practice

## Practical examples (extracted from RULES.md for compactness)

### 1. raw_corrected_zone (fixed)
- Was: `schema_ref: AGENTS.md#raw_corrected_zone` → broken link
- Found: `rules/protected_zones.json` contains access rules for zones
- Action: Update to `rules/protected_zones.json`

### 2. batch_ingest_trigger (fixed)
- Was: `schema_ref: AGENTS.md#batch_ingest_trigger` → broken link
- Found: rules moved to `rules/batch_ingest_trigger.json`
- Action: Update to `rules/batch_ingest_trigger.json`

### 3. link-conventions (fixed)
- Was: `schema_ref: rules/link-conventions` → incorrect filename
- Actual name: `rules/link_conventions.json` (with underscore in name)
- Action: Fix path

### 4. Delta Tracking (removed)
- Implemented in `scripts/rebuild-source-manifest.sh`
- Was: `schema_ref: AGENTS.md#delta_tracking` → **Removed**
- Reason: script is self-documenting
