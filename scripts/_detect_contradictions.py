import json, sys, os, re
from collections import defaultdict
from datetime import datetime

wiki_dir = os.environ.get("WIKI_DIR", "wiki")
quiet_mode = os.environ.get("QUIET") == "true" or "--quiet" in sys.argv

pages_with_dates = {}
fact_groups = defaultdict(list)

for root, dirs, files in os.walk(wiki_dir):
    for fname in files:
        if not fname.endswith(".md"):
            continue
        filepath = os.path.join(root, fname)
        rel_path = os.path.relpath(filepath, wiki_dir)
        
        try:
            with open(filepath, "r") as f:
                content = f.read(4096)
            
            # Extract frontmatter date
            match = re.search(r'date:\s*(\d{4}-\d{2}-\d{2})', content)
            if not match:
                continue
            page_date = match.group(1)
            
            # Extract key facts from first 50 lines
            key_facts = []
            for line in content.split("\n")[:50]:
                stripped = line.strip()
                
                # Version patterns (v2.0, v3.1.2)
                for m in re.finditer(r'(v\d+\.\d+(?:\.\d+)?)', stripped):
                    key_facts.append({"type": "version", "value": m.group(1), "context": stripped[:200]})
                
                # Date patterns (2026-06-24) - exclude already parsed YAML dates
                for m in re.finditer(r'(\d{4}-\d{2}-\d{2})', stripped):
                    val = m.group(1)
                    if not val.startswith("---") and val != page_date:
                        key_facts.append({"type": "date", "value": val, "context": stripped[:200]})
            
            if key_facts:
                pages_with_dates[rel_path] = {"date": page_date, "facts": key_facts}
                
                for fact in key_facts:
                    group_key = f"{fact['type']}:{fact['value']}"
                    if len(group_key) < 30:
                        fact_groups[group_key].append({"path": rel_path, "context": fact["context"]})
        
        except Exception:
            continue

# Detect contradictions: same version/date in different contexts across pages
contradictions = []
for group_key, entries in fact_groups.items():
    if len(entries) < 2:
        continue
    
    # Check if contexts differ significantly (potential conflict)
    contexts = [e["context"] for e in entries]
    
    contradictions.append({
        "type": "version_conflict",
        "group_key": group_key,
        "entries": [{"path": e["path"], "context": e["context"][:150]} for e in entries]
    })

# Output JSON on stdout
output = {
    "timestamp": datetime.now().strftime("%Y-%m-%dT%H:%M:%S"),
    "total_pages_scanned": len(pages_with_dates),
    "fact_groups_analyzed": len(fact_groups),
    "potential_contradictions": len(contradictions),
    "issues_found": contradictions,
    "status": "ISSUES_FOUND" if contradictions else "CLEAN"
}

print(json.dumps(output, indent=2))

# Human-readable summary on stderr unless --quiet
if not quiet_mode and contradictions:
    print(f"\n[!] Found {len(contradictions)} potential contradiction(s):", file=sys.stderr)
    for c in contradictions[:5]:
        print(f"  • {c['group_key']}: ", end="", file=sys.stderr)
        for e in c["entries"]:
            print(f"{e['path']} -> {e['context'][:80]} | ", end="", file=sys.stderr)
        print(file=sys.stderr)

# Exit code: 1 if issues found, 0 if clean
if contradictions:
    sys.exit(1)
else:
    sys.exit(0)
