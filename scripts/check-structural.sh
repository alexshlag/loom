#!/usr/bin/env bash
# check-structural.sh — Find wiki pages missing body text between H1 and first ##
# Usage: ./check-structural.sh [wiki_dir]
# Output: JSON array of violations to stdout, one line per violation on stderr

set -euo pipefail

AUTO_FIX=false
[[ "${1:-}" == "--auto-fix" ]] && AUTO_FIX=true
WIKI_DIR="${2:-$1}"
if [ -z "$WIKI_DIR" ]; then
    WIKI_DIR="./wiki"
fi

if command -v python3 &>/dev/null; then
    export WIKI_DIR
    python3 << 'PYEOF'
import os, sys, re, json

wiki_dir = os.environ.get('WIKI_DIR', './wiki')
auto_fix = os.environ.get('AUTO_FIX', 'false').lower() == 'true'
violations = []
fixed_paths = []

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

        # Scan between fm_end and first ##
        h1_idx = None
        first_h2_idx = None
        has_body_text = False
        title_line = ''

        for i in range(fm_end, len(lines)):
            stripped = lines[i].strip()
            if not stripped:
                continue

            # Detect H1 (but not ##)
            if re.match(r'^# ', stripped) and not stripped.startswith('## '):
                h1_idx = i
                title_line = stripped.strip('#').strip()
                continue

            # Detect first ## — stop here
            if re.match(r'^## ', stripped):
                first_h2_idx = i
                break

            # If we have H1 but haven't hit ##, check for body text
            if h1_idx is not None:
                # Skip markdown-only (bold/italic without real words)
                if re.match(r'^\*{1,4}\w+\*{1,4}$', stripped):
                    continue
                # Skip heading-like patterns
                if stripped.startswith('#'):
                    continue
                # Non-empty line = body text found
                has_body_text = True

        # Violation: H1 exists but no body text before first ##
        if h1_idx is not None and first_h2_idx is not None and not has_body_text:
            rel = os.path.relpath(path, wiki_dir)
            violations.append({'path': rel, 'h1_line': h1_idx + 1, 'first_h2_line': first_h2_idx + 1})
            
            # Auto-fix: extract category from frontmatter and generate intro
            if auto_fix:
                # Try to find category in frontmatter
                cat_match = re.search(r'^category:\s*(.+)', content[:h1_idx * 2])
                category = 'entity'
                if cat_match:
                    category = cat_match.group(1).strip().strip('[]').strip()
                
                # Generate intro paragraph
                intro_text = f"Page covering {title_line} — overview, usage patterns, and related resources."
                
                # Inject intro between H1 line and first ##
                new_lines = lines[:first_h2_idx] + ['\n', intro_text] + lines[first_h2_idx:]
                new_content = '\n'.join(new_lines)
                
                with open(path, 'w') as f:
                    f.write(new_content)
                fixed_paths.append(rel)

# Output JSON to stdout
print(json.dumps(violations, indent=2))

# Print violations on stderr (or fixes if auto_fix)
if auto_fix and fixed_paths:
    for fp in fixed_paths:
        print(f"FIXED: {fp} — added intro paragraph", file=sys.stderr)
else:
    for v in violations:
        print(f"VIOLATION: {v['path']} — no body text between H1 (line {v['h1_line']}) and ## (line {v['first_h2_line']})", file=sys.stderr)

sys.exit(0 if not violations else 1)
PYEOF
else
    echo '[]'
fi
