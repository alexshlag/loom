#!/usr/bin/env bash
# check-structural.sh — Verify H1 headers exist in wiki pages
# Usage: ./check-structural.sh [wiki_dir]
# Output: JSON array of violations (missing H1) to stdout

set -euo pipefail


WIKI_DIR="${2:-${1:-}}"
if [ -z "${WIKI_DIR:-}" ]; then
    WIKI_DIR="./wiki"
fi

if command -v python3 &>/dev/null; then
    export WIKI_DIR
    python3 << 'PYEOF'
import os, sys, re, json

wiki_dir = os.environ.get('WIKI_DIR', './wiki')
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

# Output JSON to stdout
print(json.dumps(violations, indent=2))

# Print violations on stderr
for v in violations:
    print(f"VIOLATION: {v['path']} — missing H1 header", file=sys.stderr)

sys.exit(0 if not violations else 1)
PYEOF
else
    echo '[]'
fi
