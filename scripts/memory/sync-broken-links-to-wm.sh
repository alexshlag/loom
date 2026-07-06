#!/usr/bin/env bash
# sync-broken-links-to-wm.sh — Capture agent_review_required from unified-pass.sh output → WM.broken_links_resolved[]
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WM_FILE="$PROJECT_ROOT/working_memory.json"

# Read stdin: JSON array of agent_review_required entries (from unified-pass.sh stdout)
INPUT=$(cat)

if [[ -z "$INPUT" || "$INPUT" == "[]" ]]; then
    exit 0
fi

python3 -c '
import json, sys

wm_path = sys.argv[1]
input_data = sys.argv[2] if len(sys.argv) > 2 else ""

# Read current WM
with open(wm_path) as f:
    wm = json.load(f)

# Get existing broken_links_resolved
existing = set()
for item in wm.get("broken_links_resolved", []):
    existing.add(json.dumps(item, sort_keys=True))

# Parse new entries (could be array or object with agent_review_required key)
new_entries = []
if input_data and input_data != "[]":
    try:
        parsed = json.loads(input_data)
        if isinstance(parsed, dict) and "agent_review_required" in parsed:
            raw = parsed["agent_review_required"]
        else:
            raw = parsed
        
        if isinstance(raw, list):
            for item in raw:
                key = json.dumps(item, sort_keys=True)
                if key not in existing:
                    new_entries.append(item)
    except (json.JSONDecodeError, TypeError):
        pass

# Update WM
if "broken_links_resolved" not in wm:
    wm["broken_links_resolved"] = []
wm["broken_links_resolved"].extend(new_entries)

with open(wm_path, "w") as f:
    json.dump(wm, f, indent=4)

print(f"✅ Added {len(new_entries)} broken links to WM (total: {len(wm[\"broken_links_resolved\"])})", file=sys.stderr)
' "$WM_FILE" "$(cat)" || true

exit 0
