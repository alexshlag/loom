#!/usr/bin/env bash
# apply-contradiction-fix.sh — Semi-auto generation of diff for contradiction sections
# Usage: ./scripts/apply-contradiction-fix.sh [--dry-run] [--target <page_path>]
# Output: Diff-ready markdown with "## Обновлено" section, ready for agent review

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
WIKI_DIR="${PROJECT_ROOT}/wiki"
DRY_RUN=true
TARGET_PAGE=""
CONFLICT_DATA=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift;;
        --apply) DRY_RUN=false; shift;;
        --target) TARGET_PAGE="$2"; shift 2;;
        *) shift;;
    esac
done

cd "$PROJECT_ROOT"

python3 << 'PYSCRIPT' --quiet 2>/dev/null || true
import json, sys, os, re
from datetime import datetime

wiki_dir = "wiki" if len(sys.argv) < 1 else sys.argv[1]
dry_run = "--dry-run" in sys.argv or "-d" in sys.argv
target_page = "" if len(sys.argv) < 2 else sys.argv[2]

# Read detect-contradications output from stdin or generate fresh scan
conflict_data = None
if not os.isatty(0):
    input_str = sys.stdin.read()
    try:
        conflict_data = json.loads(input_str)
    except json.JSONDecodeError: pass

# If no valid data, run a quick scan
if not conflict_data or not conflict_data.get("issues_found"):
    from collections import defaultdict
    
    pages_with_dates = {}
    fact_groups = defaultdict(list)
    
    for root, dirs, files in os.walk(wiki_dir):
        for fname in files:
            if not fname.endswith(".md"): continue
            filepath = os.path.join(root, fname)
            rel_path = os.path.relpath(filepath, wiki_dir)
            
            try:
                with open(filepath, "r") as f:
                    content = f.read(4096)
                
                match = re.search(r'date:\s*(\d{4}-\d{2}-\d{2})', content)
                if not match: continue
                page_date = match.group(1)
                
                key_facts = []
                for line in content.split("\n")[:50]:
                    stripped = line.strip()
                    # Version patterns (v2.0, v3.1.2)
                    for m in re.finditer(r'(v\d+\.\d+(?:\.\d+)?)', stripped):
                        key_facts.append({"type": "version", "value": m.group(1), "context": stripped})
                    # Date patterns (2026-06-24) - exclude YAML dates
                    for m in re.finditer(r'(\d{4}-\d{2}-\d{2})', stripped):
                        val = m.group(1)
                        if not val.startswith("---") and val != page_date:
                            key_facts.append({"type": "date", "value": val, "context": stripped})
                
                if key_facts:
                    pages_with_dates[rel_path] = {"date": page_date, "facts": key_facts}
                    for fact in key_facts:
                        group_key = f"{fact['type']}:{fact['value']}"
                        if len(group_key) < 30:
                            fact_groups[group_key].append({"path": rel_path, "context": fact["context"]})
            except Exception: continue
    
    contradictions = []
    for group_key, entries in fact_groups.items():
        if len(entries) >= 2:
            contradictions.append({
                "type": "version_conflict",
                "group_key": group_key,
                "entries": [{"path": e["path"], "context": e["context"][:150]} for e in entries]
            })
    
    conflict_data = {"potential_contradictions": len(contradictions), "issues_found": contradictions}

if not conflict_data or not conflict_data.get("issues_found"):
    print("[✓] No contradictions to fix", file=sys.stderr)
    sys.exit(0)

for c in conflict_data["issues_found"]:
    target = target_page if target_page else (c["entries"][0]["path"] if c["entries"] else None)
    refs = [e["path"] for e in c["entries"][1:3]]
    
    # Generate diff-ready markdown section
    full_path = os.path.join(wiki_dir, target) if target else ""
    exists = os.path.isfile(full_path) if target else False
    
    print(f"---")
    print(f"path: {target}")
    print(f"exists: {'yes' if exists else 'no'}")
    print(f"group_key: {c['group_key']}")
    print(f"references: {','.join(refs)}")
    
    # Generate the section content for agent to review/apply
    today = datetime.now().strftime("%Y-%m-%d")
    section_template = f"""## Обновлено {today} — conflicting info
- **Conflicting fact**: `{c['group_key']}` found in multiple pages with different contexts.
- **Sources involved**: {[e['path'].replace('.md','') for e in c['entries']]}.
- **Action needed**: Agent must review which source is authoritative (see issue #4: Authoritative Sources Criteria)."""

    if exists and target:
        print(f"---")
        print(f"SECTION_CONTENT_START")
        print(section_template)
        print(f"SECTION_CONTENT_END")
    
print("---")
PYSCRIPT "$WIKI_DIR" --dry-run 2>/dev/null || true
fi