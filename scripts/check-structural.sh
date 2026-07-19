#!/usr/bin/env bash
# check-structural.sh — Verify H1 headers and auto-insert intro paragraph when missing
# Usage: ./check-structural.sh [wiki_dir] [--auto-fix]
# Output: JSON array of violations (missing H1) or auto-fix summary to stdout

set -euo pipefail


WIKI_DIR="${2:-${1:-}}"
if [ -z "${WIKI_DIR:-}" ]; then
    WIKI_DIR="./wiki"
fi

AUTO_FIX=false
if [[ "${3:-}" == "--auto-fix" ]]; then
    AUTO_FIX=true
fi

if command -v python3 &>/dev/null; then
    export WIKI_DIR
    export AUTO_FIX
    python3 << 'PYEOF'
import os, sys, re, json

wiki_dir = os.environ.get('WIKI_DIR', './wiki')
AUTO_FIX = os.environ.get('AUTO_FIX', 'false').lower() == 'true'
violations = []

for root, dirs, files in os.walk(wiki_dir):
    # Skip system directories and root level (system files)
    if 'meta' in root or 'raw' in root or '.vault-meta' in root:
        continue
    if root == wiki_dir:  # Skip system files at root level (hot.md, index.md, log.md, overview.md, snapshot.md)
        continue
    for fname in sorted(files):
        if not fname.endswith('.md'):
            continue
        path = os.path.join(root, fname)

        try:
            with open(path) as f:
                content = f.read()
        except Exception:
            continue

        lines = content.split('\n')

        # Find fm_end (end of YAML frontmatter ---)
        fm_end = 0
        dashes_found = 0
        for i, line in enumerate(lines):
            if line.strip() == '---':
                dashes_found += 1
                if dashes_found == 2:
                    fm_end = i + 1
                    break

        # Scan between fm_end and first ## — only require H1, no body_text/description mandatory
        h1_idx = None
        title_line = ''

        for i in range(fm_end, len(lines)):
            stripped = lines[i].strip()
            if not stripped:
                continue

            # Detect H1 (but not ##)
            if re.match(r'^# ', stripped) and not stripped.startswith('## '):
                h1_idx = i
                title_line = stripped.strip('#').strip()
                break

        # Violation: no H1 header found before first ##
        if not h1_idx:
            rel = os.path.relpath(path, wiki_dir)
            violations.append({'path': rel, 'issue': 'no_H1_header'})

# --- Auto-fix mode: generate intro paragraph and prepend to files ---
if AUTO_FIX and violations:
    # Build intro: "# <title from H1 or filename>\n\n<first paragraph from H2>"
    fixed = []
    for v in violations:
        path = os.path.join(wiki_dir, v['path'])
        # Extract title (H1 if present, else filename)
        with open(path) as f:
            lines = f.readlines()
        title = None
        for line in lines:
            m = re.match(r'^# (.+)$', line)
            if m:
                title = m.group(1).strip()
                break
        if not title:
            title = v['path'].replace('/', ' - ')
            title = re.sub(r'[-_.]+', ' ', title).strip()
        
        # Find first H2 as intro text
        intro_text = ''
        in_body = False
        for line in lines:
            stripped = line.strip()
            if not in_body:
                if re.match(r'^## ', stripped):
                    in_body = True
                    intro_text = stripped[3:].strip()
                    break
                elif re.match(r'^# ', stripped):
                    # H1 already processed, skip
                    pass
        
        # Build new intro paragraph (single line, no blank lines)
        intro = f"# {title}\n\n{intro_text}".strip()
        
        # Prepend intro to file
        with open(path, 'r') as f:
            existing = ''.join(f.readlines())
        with open(path, 'a') as f:
            f.write(intro + '\n\n' + existing)
        fixed.append(v['path'])
    
    # Report success
    print(json.dumps({
        'mode': 'auto_fix',
        'fixed': fixed,
        'count': len(fixed)
    }, indent=2))
    sys.exit(0)

# Output violations JSON
print(json.dumps(violations, indent=2))

# Print violations on stderr
for v in violations:
    print(f"VIOLATION: {v['path']} — missing H1 header", file=sys.stderr)

sys.exit(0 if not violations else 1)
PYEOF
else
    echo '[]'
fi
