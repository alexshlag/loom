import json, sys, os, re, logging
from collections import defaultdict
from datetime import datetime

logging.basicConfig(stream=sys.stderr, level=logging.INFO, format='%(message)s')

wiki_dir = os.environ.get("WIKI_DIR", "wiki")
quiet_mode = os.environ.get("QUIET") == "true" or "--quiet" in sys.argv

# Exclude system files from contradiction scanning (AGENTS.md: system_files_excluded_from_search)
EXCLUDED_FILES = {"log.md", "issues.md", "timeline.md", "overview.md", "snapshot.md",
                  "index.md", "GIT-STATUS-LOG.md", "working_memory.json"}

pages_with_dates = {}
fact_groups = defaultdict(list)

for root, dirs, files in os.walk(wiki_dir):
    for fname in files:
        if not fname.endswith(".md"):
            continue
        # Exclude system files (AGENTS.md: system_files_excluded_from_search)
        if fname in EXCLUDED_FILES:
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

# Detect contradictions: only version conflicts are errors — date-only groups are informational
contradictions = []
informational_notes = []
for group_key, entries in fact_groups.items():
    if len(entries) < 2:
        continue
    
    is_version_group = "version:" in group_key.lower()
    
    if is_version_group:
        first_entry = entries[0]
        second_entries = entries[1:3]
        hints_list = [e["path"] for e in second_entries]
        
        contradictions.append({
            "type": "version_conflict",
            "group_key": group_key,
            "entries": [{"path": e["path"], "context": e["context"][:150]} for e in entries],
            "resolution_hint": {
                "action": "add_updated_section",
                "target_page": first_entry["path"],
                "references": hints_list,
                "template": "## Updated [DATE] — conflicting info\\n- **[CONFLICTING_SOURCE]**: [brief].\\n- **Source:** `[PATH]`.\\n- **Conflicts with:** `TARGET_PAGE`, [OLD_DATE] (old statement)."
            }
        })
    else:
        # Date-only groups are NOT contradictions — informational only
        informational_notes.append({
            "type": "date_group",
            "group_key": group_key,
            "pages": [e["path"] for e in entries],
            "note": "Multiple pages share this date — not a contradiction, just temporal grouping"
        })

# Output JSON on stdout
output = {
    "timestamp": datetime.now().strftime("%Y-%m-%dT%H:%M:%S"),
    "total_pages_scanned": len(pages_with_dates),
    "fact_groups_analyzed": len(fact_groups),
    "potential_contradictions": len(contradictions),
    "informational_notes": informational_notes,
    "issues_found": contradictions if contradictions else None,
    "status": "ISSUES_FOUND" if contradictions else "CLEAN"
}

print(json.dumps(output, indent=2))

# Human-readable summary via logging (stderr) unless --quiet
if not quiet_mode and contradictions:
    logging.info(f"[!] Found {len(contradictions)} potential contradiction(s):")
    for c in contradictions[:5]:
        entries_str = " | ".join(f"{e['path']} -> {e['context'][:80]}" for e in c["entries"])
        logging.info(f"  • {c['group_key']}: {entries_str}")
if not quiet_mode and informational_notes:
    logging.info(f"[i] Informational date groups ({len(informational_notes)}):")

# Exit code: 1 if issues found, 0 if clean
if contradictions:
    sys.exit(1)
else:
    sys.exit(0)
