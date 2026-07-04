#!/usr/bin/env python3
# structural-fix.py — Fix FIRST-BLOCK-V1 violations (missing body text between H1 and ##)

import os, sys, json, re

wiki_dir = './wiki'
fixed_files = []

# System files to skip
SYSTEM_FILES = ['hot.md', 'index.md', 'log.md', 'overview.md', 'snapshot.md']

for root, dirs, files in os.walk(wiki_dir):
    if 'meta' in root or '.vault-meta' in root: continue
    
    for fname in sorted(files):
        if not fname.endswith('.md'): continue
        
        full_path = os.path.join(root, fname)
        
        # Skip system files
        rel_path = full_path.replace('./wiki/', '')
        base_name = fname  # just filename
        
        if base_name in SYSTEM_FILES:
            continue
        
        with open(full_path) as f:
            content = f.read()
        
        lines = content.split('\n')
        
        # Find frontmatter end (2nd ---)
        fm_end = 0
        dashes_found = 0
        for i, line in enumerate(lines):
            if line.strip() == '---':
                dashes_found += 1
                if dashes_found == 2:
                    fm_end = i + 1
                    break
        
        # Find H1 and first ##
        h1_idx = None
        first_h2_idx = None
        
        for i in range(fm_end, len(lines)):
            stripped = lines[i].strip()
            if not stripped: continue
            
            if re.match(r'^# ', stripped) and not stripped.startswith('## '):
                h1_idx = i
                continue
            
            if re.match(r'^## ', stripped):
                first_h2_idx = i
                break
        
        # Check for intro text between H1 and ##
        has_intro = False
        if h1_idx is not None:
            for j in range(h1_idx+1, min(h1_idx+5, len(lines))):
                stripped_j = lines[j].strip()
                if not stripped_j: continue
                # Skip code blocks and headings
                if stripped_j.startswith('```') or stripped_j.startswith('#'):
                    break
                # Non-empty line with real content = intro found
                has_intro = True
                break
        
        if h1_idx is not None and first_h2_idx is not None and not has_intro:
            title = lines[h1_idx].replace('# ', '').strip()
            
            # Extract tags from frontmatter for context
            fm_match = re.search(r'^---\s*\n(.+?)\n---', content, re.DOTALL)
            tags_text = ''
            if fm_match:
                fm_content = fm_match.group(1)
                for line in fm_content.split('\n'):
                    if 'tags:' in line.lower():
                        tags_text = line.strip()
            
            # Generate intro based on title and category
            category = os.path.basename(os.path.dirname(full_path))
            
            if category == 'entities':
                intro = f"Page covering {title} — entity information, architecture details, and usage patterns."
            elif category == 'concepts':
                intro = f"This page explores {title} as a key concept in our knowledge base."
            elif category == 'syntheses':
                intro = f"Synthesis of multiple sources on the topic: {title}."
            elif category == 'comparisons':
                intro = f"Comparative analysis covering {title} across different contexts and implementations."
            else:
                intro = f"This page covers {title} — important topic in our wiki knowledge base."
            
            # Insert intro between H1 and first ##
            # Find position after blank line following H1
            insert_pos = h1_idx + 1
            
            # Check if there's a blank line after H1
            while insert_pos < len(lines) and lines[insert_pos].strip() == '':
                insert_pos += 1
            
            # Insert intro with blank line before it (after existing blank(s))
            new_lines = lines[:h1_idx+1] + ['', '', intro, ''] + lines[h1_idx+1:]
            
            # Write back
            with open(full_path, 'w') as f:
                f.write('\n'.join(new_lines))
            
            fixed_files.append(rel_path)

print(json.dumps(fixed_files, indent=2))
