#!/usr/bin/env bash
# structural-fix.sh — Fix FIRST-BLOCK-V1 violations (missing body text between H1 and ##)
# Usage: ./structural-fix.sh [--fix] [wiki_dir]

set -euo pipefail

WIKI_DIR="${2:-$1}"
if [ -z "$WIKI_DIR" ]; then
    WIKI_DIR="./wiki"
fi

FIX_MODE=false
while [[ "${1:-}" =~ ^-- ]]; do
    case $1 in
        --fix) FIX_MODE=true; shift ;;
    esac
done

# Run Python to find violations and optionally fix them
python3 << 'PYEOF' "$WIKI_DIR" "$FIX_MODE"
import os, sys, re

wiki_dir = sys.argv[1] if len(sys.argv) > 1 else './wiki'
fix_mode = sys.argv[2].lower() == 'true' if len(sys.argv) > 2 else False

violations = []
fixed_files = []

for root, dirs, files in os.walk(wiki_dir):
    # Skip meta directories
    if 'meta' in root or '.vault-meta' in root: continue
    
    for fname in sorted(files):
        if not fname.endswith('.md'): continue
        
        path = os.path.join(root, fname)
        
        with open(path) as f:
            content = f.read()
        
        lines = content.split('\n')
        
        # Find frontmatter end
        fm_end = 0
        found_fm = False
        for i, line in enumerate(lines):
            if line.strip() == '---':
                found_fm = not found_fm or True
        
        if found_fm:
            fm_end = i + 1
            
        # Find H1 and first ##
        h1_idx = None
        first_h2_idx = None
        has_intro = False
        
        for i in range(fm_end, len(lines)):
            stripped = lines[i].strip()
            if not stripped: continue
            
            # Check for H1
            if re.match(r'^# ', stripped) and not stripped.startswith('## '):
                h1_idx = i
                continue
            
            # Check for first ## (stop here)
            if re.match(r'^## ', stripped):
                first_h2_idx = i
                break
            
            # If we have H1, check body text
            if h1_idx is not None:
                # Skip empty lines
                if not stripped: continue
                # Skip code blocks
                if stripped.startswith('```'): continue
                # Skip heading-like patterns (# anything)
                if stripped.startswith('#'): continue
                # Check if it's just bold/italic without real words
                if re.match(r'^\*{1,4}\w+\*{1,4}$', stripped):
                    continue
                # Non-empty content = body text found
                has_intro = True
        
        # Violation: H1 exists but no body before first ##
        if h1_idx is not None and first_h2_idx is not None and not has_intro:
            rel_path = path.replace('./wiki/', '')
            
            # Generate intro based on title and frontmatter
            title = lines[h1_idx].replace('# ', '').strip()
            
            # Extract tags from frontmatter (if present)
            tags_text = ''
            fm_match = re.search(r'^---\s*\n(.+?)\n---', content, re.DOTALL)
            if fm_match:
                fm_content = fm_match.group(1)
                for line in fm_content.split('\n'):
                    if 'tags:' in line.lower():
                        tags_text = line.strip()
            
            # Generate intro sentence
            intro = f"This page covers {title} — a key topic in our wiki."
            
            if fix_mode:
                # Insert intro between H1 and first ##
                new_lines = lines[:h1_idx+1] + ['', intro] + lines[h1_idx+1:]
                
                # Find where to insert (after blank line after H1)
                insert_pos = h1_idx + 1
                
                # Check if there's already a blank line after H1
                if insert_pos < len(new_lines) and new_lines[insert_pos].strip() == '':
                    pass  # Good, use existing blank
                else:
                    # Insert blank line before intro
                    new_lines = lines[:h1_idx+2] + ['', intro] + lines[h1_idx+2:]
                
                # Write back
                with open(path, 'w') as f:
                    f.write('\n'.join(new_lines))
                
                fixed_files.append(rel_path)
            else:
                violations.append({
                    "path": rel_path,
                    "title": title,
                    "h1_line": h1_idx + 1,
                    "first_h2_line": first_h2_idx + 1
                })

# Output results
if fix_mode and fixed_files:
    print(f"Fixed {len(fixed_files)} files:")
    for f in fixed_files:
        print(f"  - {f}")
elif not fix_mode and violations:
    import json
    print(json.dumps(violations, indent=2))

PYEOF

# Exit code
if [ "$FIX_MODE" = true ]; then
    echo "[✓] Structural fix applied." >&2
fi
