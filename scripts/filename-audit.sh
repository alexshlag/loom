#!/usr/bin/env bash
set -euo pipefail

# filename-audit.sh — Scan wiki/concepts/ for naming convention violations
# Detects: project-specific tags (e.g., symfony-messaging) without matching prefix in filename
# Output: JSON array of violations [{file, severity, suggested_name, reason}]
# Usage: ./scripts/filename-audit.sh [--help] [wiki_dir]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${1:-$SCRIPT_DIR/..}"
WIKI_CONCEPTS="$PROJECT_ROOT/wiki/concepts"

show_help() {
    cat <<'EOF'
filename-audit.sh — Naming convention violation audit for wiki/concepts/

Usage: ./scripts/filename-audit.sh [--help] [wiki_dir]

Checks all .md files in wiki/concepts/ for naming violations:
  - Detects project-specific tags (e.g., symfony-messaging) without matching prefix in filename
  - Skips files in exception list (abstract concepts, framework exceptions)
  - Outputs JSON array with violations [{file, severity, suggested_name, reason}]

Exit codes:
  0 — No violations found
  1 — Violations detected (JSON output to stdout)

Examples:
  ./scripts/filename-audit.sh          # scan default wiki/concepts/
  ./scripts/filename-audit.sh /path    # scan custom directory
EOF
    exit 0
}

if [[ "${1:-}" == "--help" ]]; then
    show_help
fi

# Run audit via Python for safe JSON handling
RESULT=$(python3 - <<PYEOF
import os, sys, re, json

wiki_concepts = os.environ.get("WIKI_CONCEPTS") or "$WIKI_CONCEPTS"
exceptions = ["cache-system.md", "hexagonal-architecture.md", "doctrine-orm.md"]

# Known project prefixes — only these are valid project slugs
KNOWN_PROJECTS = [
    "symfony",
    "react", 
    "sonata",
    "doctrine",
    "pi",
    "ai-factory",  # hyphenated prefix counts as single slug
]

violations = []

for md_file in sorted(os.listdir(wiki_concepts)):
    if not md_file.endswith('.md'):
        continue
    
    filepath = os.path.join(wiki_concepts, md_file)
    
    if md_file in exceptions:
        continue
    
    with open(filepath, 'r') as f:
        content = f.read()
    
    # Extract tags from frontmatter
    tag_line = None
    for line in content.split('\n'):
        if 'tags:' in line.lower():
            tag_line = line
            break
    
    if not tag_line:
        continue
    
    match = re.search(r'\[(.*?)\]', tag_line)
    if not match:
        continue
    
    tags_str = match.group(1)
    tags = [t.strip().strip('"').strip("'") for t in re.split(r',\s*', tags_str)]
    
    # Find project-specific tags matching known projects
    matched_project = None
    matched_tag = None
    for tag in tags:
        parts = tag.split('-')
        first_part = parts[0]
        
        # Case 1: hyphenated prefix (e.g., symfony-messaging → project=symfony)
        if len(parts) >= 2 and len(''.join(parts[1:])) > 1:
            for proj in KNOWN_PROJECTS:
                if first_part == proj or first_part.startswith(proj + '-'):
                    matched_project = proj
                    matched_tag = tag
                    break
        
        # Case 2: plain project name (e.g., symfony, react)
        elif not matched_project and tag in KNOWN_PROJECTS:
            matched_project = tag
            matched_tag = tag
    
    # If no known project found → skip (not a naming violation)
    if not matched_project or not matched_tag:
        continue
    
    base_name = md_file[:-3]
    
    # Check if filename starts with the matched project prefix
    has_prefix = False
    for proj in KNOWN_PROJECTS:
        if base_name.startswith(proj + '-'):
            has_prefix = True
            break
        # Handle hyphenated prefixes like ai-factory-
        if '-' in proj and base_name.startswith(proj + '-'):
            has_prefix = True
            break
    
    if not has_prefix:
        suggested_name = f"{matched_project}-{base_name}.md"
        violations.append({
            'file': md_file,
            'severity': 'HIGH',
            'suggested_name': suggested_name,
            'reason': f'tags contain project-specific patterns (e.g., {matched_tag}) without filename prefix'
        })

print(json.dumps(violations))
PYEOF
) || true

if [[ -n "$RESULT" ]]; then
    echo "$RESULT"
    if [[ "$RESULT" != "[]" ]]; then
        exit 1
    fi
fi

echo "[]"
exit 0
