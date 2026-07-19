#!/usr/bin/env bash
# filename-audit.sh — Naming convention + collision audit for wiki
# Detects: project-specific tags without prefix, bare vs prefixed collisions, duplicate base names
# Usage: ./scripts/filename-audit.sh [--help] [--check <proposed_path>] [--resolve] [wiki_dir]
#
# Modes:
#   default     — scan wiki/concepts/ for naming violations
#   --check P   — test if proposed path collides with existing files
#   --resolve   — detect ALL collisions across wiki/, output with tie-breaking info
#
# Exit codes:
#   0 — No violations/collisions found
#   1 — Violations or collisions detected (JSON output to stdout)

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
WIKI_DIR="${PROJECT_ROOT}/wiki"
RULES_REF="${PROJECT_ROOT}/rules/filename_collision_strategy.json"

show_help() {
    cat <<'EOF'
filename-audit.sh — Naming convention + collision audit for wiki

Usage:
  ./scripts/filename-audit.sh [--help] [wiki_dir]           # scan for violations
  ./scripts/filename-audit.sh --check <proposed_path>       # test collision for ingest
  ./scripts/filename-audit.sh --resolve                     # detect all collisions with tie-breaking

Options:
  --check <path>    Test proposed wiki file path for collisions against existing files
  --resolve         Detect bare vs prefixed collisions; output with tie-breaking info
  --wiki-dir <dir>  Override wiki directory (default: wiki/)

Output:
  JSON array of {file, severity, type, suggested_name, reason, tie_breaking_level}

Exit codes:
  0 — Clean
  1 — Issues found
  2 — Error (invalid args, missing rules file)

Examples:
  ./scripts/filename-audit.sh                     # scan wiki/concepts/ violations
  ./scripts/filename-audit.sh --check wiki/concepts/cache.md
  ./scripts/filename-audit.sh --resolve
EOF
    exit 0
}

MODE="default"
CHECK_PATH=""
WIKI_SCAN_DIR="$WIKI_DIR"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help)    show_help ;;
        --check)   MODE="check"; CHECK_PATH="$2"; shift 2 ;;
        --resolve) MODE="resolve"; shift ;;
        --wiki-dir) WIKI_SCAN_DIR="$2"; shift 2 ;;
        *)         WIKI_SCAN_DIR="$1"; shift ;;
    esac
done

# Ensure WIKI_SCAN_DIR is a valid path (not flag)
if [[ "$WIKI_SCAN_DIR" == --* ]]; then
    WIKI_SCAN_DIR="$WIKI_DIR"
fi

python3 - "$MODE" "$CHECK_PATH" "$WIKI_SCAN_DIR" "$RULES_REF" <<'PYEOF'
import os, sys, re, json, glob

mode = sys.argv[1]
check_path = sys.argv[2] if len(sys.argv) > 2 else ""
wiki_scan_dir = sys.argv[3] if len(sys.argv) > 3 else "wiki"
rules_ref = sys.argv[4] if len(sys.argv) > 4 else "rules/filename_collision_strategy.json"

# Known project prefixes
KNOWN_PROJECTS = ["symfony", "react", "sonata", "doctrine", "pi", "ai-factory", "ibexa", "sylius"]

def is_project_prefix(name):
    """Check if filename starts with a known project prefix."""
    for proj in KNOWN_PROJECTS:
        if name == proj or name.startswith(proj + '-'):
            return proj
    return None

def get_base_name(filename):
    """Strip project prefix and .md extension."""
    base = filename.replace('.md', '')
    for proj in KNOWN_PROJECTS:
        if base.startswith(proj + '-'):
            return base[len(proj)+1:], proj
    return base, None

def extract_tags(filepath):
    """Extract tags from frontmatter."""
    try:
        with open(filepath, 'r') as f:
            content = f.read()
        tag_match = re.search(r'tags:\s*\[(.*?)\]', content, re.DOTALL)
        if tag_match:
            return [t.strip().strip('"').strip("'") for t in tag_match.group(1).split(',')]
    except:
        pass
    return []

def extract_date(filepath):
    """Extract date from frontmatter."""
    try:
        with open(filepath, 'r') as f:
            content = f.read()
        date_match = re.search(r'date:\s*(\d{4}-\d{2}-\d{2})', content)
        if date_match:
            return date_match.group(1)
    except:
        pass
    return None

def extract_aliases(filepath):
    """Extract aliases from frontmatter."""
    try:
        with open(filepath, 'r') as f:
            content = f.read()
        alias_match = re.search(r'aliases:\s*\[(.*?)\]', content, re.DOTALL)
        if alias_match:
            return [a.strip().strip('"').strip("'") for a in alias_match.group(1).split(',')]
    except:
        pass
    return []

def has_project_tag(tags):
    """Check if any tag indicates a project-specific concept."""
    for tag in tags:
        for proj in KNOWN_PROJECTS:
            if tag.startswith(proj + '-') or tag == proj:
                return proj
    return None

# Collect all wiki md files by directory
wiki_files = {}  # dir -> {filename: filepath}
for root, dirs, files in os.walk(wiki_scan_dir):
    rel_dir = os.path.relpath(root, wiki_scan_dir)
    if rel_dir not in wiki_files:
        wiki_files[rel_dir] = {}
    for f in files:
        if f.endswith('.md') and not f.endswith('.json'):
            wiki_files[rel_dir][f] = os.path.join(root, f)

violations = []

if mode == "default":
    # Original: scan wiki/concepts/ for naming violations
    concepts_dir = os.path.join(wiki_scan_dir, "concepts")
    if not os.path.isdir(concepts_dir):
        print("[]")
        sys.exit(0)
    exceptions = ["cache-system.md", "hexagonal-architecture.md", "doctrine-orm.md"]

    for md_file in sorted(wiki_files.get("concepts", {}).keys()):
        if md_file in exceptions:
            continue
        filepath = wiki_files["concepts"][md_file]
        tags = extract_tags(filepath)
        matched_project = has_project_tag(tags)

        if not matched_project:
            continue

        base = md_file[:-3]
        prefix_match = is_project_prefix(base)

        if prefix_match:
            continue  # has valid prefix

        violations.append({
            'file': md_file,
            'severity': 'HIGH',
            'type': 'missing_prefix',
            'suggested_name': f"{matched_project}-{md_file}",
            'reason': f'tags contain project-specific pattern (e.g., {matched_project}-) without filename prefix',
            'tie_breaking_level': 'level_1_primary_entity'
        })

elif mode == "check":
    # Test proposed path for collision
    if not check_path:
        print(json.dumps([{'error': '--check requires a path argument'}]))
        sys.exit(2)

    proposed_file = os.path.basename(check_path)
    wiki_scan_norm = os.path.normpath(wiki_scan_dir)
    proposed_dir = os.path.relpath(os.path.dirname(check_path), wiki_scan_norm)

    # Look for base name collisions in the same directory
    dir_files = wiki_files.get(proposed_dir, {})
    base, proj = get_base_name(proposed_file.replace('.md', ''))

    for existing_file in dir_files.keys():
        if existing_file == proposed_file:
            continue

        existing_full = existing_file.replace('.md', '')
        existing_base, existing_proj = get_base_name(existing_full)

        # Compute conceptual base (strip project prefix from both)
        proposed_conceptual = base  # already stripped if has prefix
        existing_conceptual = existing_base

        # If proposed is bare, also check if it matches existing's conceptual base
        if not proj:
            proposed_conceptual = base
        if not existing_proj:
            existing_conceptual = existing_base

        if proposed_conceptual == existing_conceptual and proposed_conceptual:
            # Same base name — potential collision
            # Determine if it's a bare vs prefixed collision
            proposed_has_prefix = proj is not None
            existing_has_prefix = existing_proj is not None

            if proposed_has_prefix and not existing_has_prefix:
                violations.append({
                    'file': existing_file,
                    'proposed': proposed_file,
                    'severity': 'HIGH',
                    'type': 'bare_vs_prefixed',
                    'suggested_name': existing_file,  # rename existing to match
                    'reason': f"bare '{existing_file}' collides with proposed '{proposed_file}' (project: {proj})",
                    'tie_breaking_level': 'level_1_primary_entity',
                    'action': 'rename_bare_to_prefixed'
                })
            elif existing_has_prefix and not proposed_has_prefix:
                violations.append({
                    'file': proposed_file,
                    'existing_file': existing_file,
                    'severity': 'MEDIUM',
                    'type': 'prefixed_vs_bare',
                    'suggested_name': f"{existing_proj}-{proposed_file}",
                    'reason': f"proposed bare '{proposed_file}' would collide with existing '{existing_file}'",
                    'tie_breaking_level': 'level_2_specificity',
                    'action': 'add_prefix_to_proposed'
                })
            elif proposed_has_prefix and existing_has_prefix and proj == existing_proj:
                violations.append({
                    'file': existing_file,
                    'proposed': proposed_file,
                    'severity': 'LOW',
                    'type': 'same_prefix_collision',
                    'reason': f"both prefixed with '{proj}' but different base names",
                    'action': 'allow_both_with_crosslink'
                })

elif mode == "resolve":
    # Detect ALL bare vs prefixed collisions across wiki
    collision_map = {}  # (dir, base_name) -> [{filepath, has_prefix, project, tags, date}]

    for dir_name, files in wiki_files.items():
        for md_file, filepath in files.items():
            base = md_file[:-3]
            prefix_match = is_project_prefix(base)
            tags = extract_tags(filepath)
            date = extract_date(filepath)
            aliases = extract_aliases(filepath)

            base_for_grouping = base
            if prefix_match:
                base_for_grouping = base[len(prefix_match)+1:]

            key = (dir_name, base_for_grouping)
            if key not in collision_map:
                collision_map[key] = []

            collision_map[key].append({
                'filepath': filepath,
                'filename': md_file,
                'dir': dir_name,
                'base': base_for_grouping,
                'has_prefix': prefix_match is not None,
                'project': prefix_match,
                'tags': tags,
                'date': date,
                'aliases': aliases
            })

    for key, entries in collision_map.items():
        if len(entries) < 2:
            continue

        dir_name, base_key = key
        prefixed = [e for e in entries if e['has_prefix']]
        bare = [e for e in entries if not e['has_prefix']]

        # Skip prefix-only files (entire filename IS the prefix, e.g. symfony.md in entities/)
        # These are entity pages, not concept pages — no collision between different entities
        if not base_key and prefixed:
            # Group by project prefix to avoid cross-entity false positives
            by_project = {}
            for e in prefixed:
                proj = e['project']
                if proj not in by_project:
                    by_project[proj] = []
                by_project[proj].append(e)
            # Only flag if same project has multiple prefix-only files
            for proj, proj_entries in by_project.items():
                if len(proj_entries) > 1:
                    for i in range(len(proj_entries)):
                        for j in range(i+1, len(proj_entries)):
                            violations.append({
                                'file_a': proj_entries[i]['filename'],
                                'file_b': proj_entries[j]['filename'],
                                'severity': 'MEDIUM',
                                'type': 'prefix_only_collision',
                                'reason': f"two prefix-only files under '{proj}' in {dir_name}/",
                                'tie_breaking_level': 'level_3_last_updated',
                                'action': 'keep_newer, merge older into aliases'
                            })
            continue

        prefixed = [e for e in entries if e['has_prefix']]
        bare = [e for e in entries if not e['has_prefix']]

        # Check if bare and prefixed refer to same entity
        bare_projects = set(e['project'] for e in prefixed if e['project'])
        bare_has_project_tag = any(has_project_tag(e['tags']) for e in bare)

        if prefixed and (bare or bare_has_project_tag):
            for b in bare:
                b_project = has_project_tag(b['tags']) or b.get('project')
                collisions = []
                for p in prefixed:
                    same_project = (b_project and b_project == p['project']) or (not b_project and p['project'])

                    if same_project:
                        collision = {
                            'file': b['filename'],
                            'existing_prefixed': p['filename'],
                            'severity': 'HIGH',
                            'type': 'bare_vs_prefixed_same_entity',
                            'proposed_name': p['filename'],
                            'reason': f"bare '{b['filename']}' collides with prefixed '{p['filename']}' (entity: {p['project']})",
                            'tie_breaking_level': 'level_1_primary_entity',
                            'action': 'rename_bare_to_prefixed'
                        }
                        collisions.append(collision)
                        violations.extend(collisions)
                    elif p['project'] not in bare_projects:
                        collisions.append({
                            'file': b['filename'],
                            'existing_prefixed': p['filename'],
                            'severity': 'MEDIUM',
                            'type': 'bare_vs_prefixed_different_entity',
                            'reason': f"bare '{b['filename']}' may be abstract; prefixed '{p['filename']}' is entity-specific",
                            'tie_breaking_level': 'level_2_specificity',
                            'action': 'check_tags_for_entity_specificity'
                        })
                        violations.extend(collisions)
            continue

        # Two prefixed names, same project — check specificity
        if len(prefixed) > 1:
            for i in range(len(prefixed)):
                for j in range(i+1, len(prefixed)):
                    a, b_entry = prefixed[i], prefixed[j]
                    # Different base names under same prefix
                    if a['base'] != b_entry['base']:
                        continue  # not a collision, different concepts
                    # Same base, same prefix — duplicate!
                    violations.append({
                        'file_a': a['filename'],
                        'file_b': b_entry['filename'],
                        'severity': 'HIGH',
                        'type': 'duplicate_prefixed',
                        'reason': f"two prefixed files with same base '{key}' under '{a['project']}'",
                        'tie_breaking_level': 'level_3_last_updated',
                        'action': 'keep_newer, merge older into aliases'
                    })

# Deduplicate by filepath
seen = set()
unique_violations = []
for v in violations:
    key = v.get('file') or v.get('filepath') or v.get('file_a', '')
    if key not in seen:
        seen.add(key)
        unique_violations.append(v)

print(json.dumps(unique_violations, indent=2))
PYEOF

RESULT=$?
if [[ $RESULT -ne 0 ]]; then
    echo "[]"
fi

exit 0
