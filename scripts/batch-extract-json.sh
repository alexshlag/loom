#!/usr/bin/env bash
# batch-extract-json.sh — Extract multiple fields from JSON in a single Python call
# Usage: scripts/batch-extract-json.sh <json_data> field1 field2 ...
#        echo "$json" | scripts/batch-extract-json.sh --stdin field1 field2 ...
# Output: tab-separated values (field1\tfield2\t...)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."

INPUT_MODE="arg"  # arg or stdin
JSON_DATA=""
FIELDS="${*:-}"

if [[ "$1" == "--stdin" ]]; then
    INPUT_MODE="stdin"
    shift
    FIELDS="${*:-}"
else
    JSON_DATA="$*"
fi

if [[ -z "$FIELDS" ]]; then
    echo "Usage: batch-extract-json.sh <json_data> field1 [field2 ...]" >&2
    echo "       scripts/batch-extract-json.sh --stdin field1 [field2 ...] <<< \$json" >&2
    exit 1
fi

# Read JSON data from either stdin or argument
if [[ "$INPUT_MODE" == "stdin" ]]; then
    read -r -d '' JSON_DATA || true
fi

python3 -c "
import json, sys

fields = sys.argv[1:]
raw = sys.stdin.read() if len(sys.argv) > 0 else ''
data = json.loads(raw)

results = []
for field in fields:
    parts = field.split('.')
    val = data
    found = True
    for part in parts:
        if isinstance(val, dict) and part in val:
            val = val[part]
        else:
            found = False
            break
    
    if not found:
        results.append('null')
    elif isinstance(val, (dict, list)):
        results.append(json.dumps(val))
    elif val is None or isinstance(val, bool):
        results.append(str(val).lower())
    else:
        results.append(str(val))

print('\t'.join(results))
" <<< "$JSON_DATA" $FIELDS 2>/dev/null || echo "null"$(printf '\t%s' $(seq 1 ${#fields[@]}))
