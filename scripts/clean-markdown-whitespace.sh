#!/usr/bin/env bash
# clean-markdown-whitespace.sh — Normalize excessive empty lines in markdown files
# Usage: ./clean-markdown-whitespace.sh [--quiet] [wiki_dir]
# Output: JSON report to stdout, violations on stderr

set -euo pipefail

QUIET=false
[[ "${1:-}" == "--quiet" ]] && QUIET=true

WIKI_DIR="${2:-./wiki}"
if [ ! -d "$WIKI_DIR" ]; then
    echo "[]" >&2
    exit 0
fi

export WIKI_DIR QUIET
python3 << 'PYEOF'
import os, sys, re, json

wiki_dir = os.environ.get('WIKI_DIR', './wiki')
quiet = os.environ.get('QUIET', 'false').lower() == 'true'
fixed_paths = []
violations_found = 0

for root, dirs, files in os.walk(wiki_dir):
    # Skip system directories
    if 'meta' in root or 'raw' in root or '.vault-meta' in root:
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
        
        # Normalize whitespace-only lines (tabs/spaces → empty)
        cleaned = re.sub(r'[ \t]+\n', '\n', content)
        
        # Squash 3+ consecutive newlines to exactly 2
        original_length = len(cleaned)
        fixed_content = re.sub(r'\n{3,}', '\n\n', cleaned)
        
        if len(fixed_content) < original_length:
            with open(path, 'w') as f:
                f.write(fixed_content)
            rel = os.path.relpath(path, wiki_dir)
            fixed_paths.append(rel)
            violations_found += 1
            
            if not quiet:
                print(f"FIXED: {rel} — squashed excessive empty lines", file=sys.stderr)

# Output JSON to stdout (machine-parseable for lint.sh)
print(json.dumps({
    'fixed_files': fixed_paths,
    'total_fixed': len(fixed_paths),
    'status': 'CLEAN' if not fixed_paths else 'FIXED',
    'timestamp': os.popen('date -u +%Y-%m-%dT%H:%M:%S%z').read().strip()
}, indent=2))

sys.exit(0)  # Never fail — cleanup is always safe

PYEOF
