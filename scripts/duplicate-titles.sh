#!/usr/bin/env bash
# duplicate-titles.sh — проверяет дубли заголовков в пределах категорий wiki
# Оптимизация: Python + hash-set O(n) вместо многократных subprocess head calls
# Usage: ./scripts/duplicate-titles.sh [wiki_dir]
# Exit code: 0 = no duplicates, 1 = duplicates found

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
WIKI_DIR="${1:-$PROJECT_ROOT/wiki}"

echo "[*] Checking for duplicate titles..." >&2

# Read categories from canonical source
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../"
WIKI_DIR="${1:-$PROJECT_ROOT/wiki}"

echo "[*] Checking for duplicate titles..." >&2

python3 << PYEOF
import os, re, sys, json

wiki_dir = "${WIKI_DIR}"
cat_file = os.path.join("$(cd "$(dirname "$0")" && pwd)", "..", "rules", "categories.json")
CATEGORIES = []
try:
    with open(cat_file) as f: cat_data = json.load(f)
    CATEGORIES = [c["key"] for c in cat_data.get("categories", [])]
except Exception:
    # Fallback if JSON unavailable
    CATEGORIES = ['entities', 'concepts', 'comparisons', 'syntheses',
                  'notes', 'meetings', 'projects', 'bibliography', 'resources']

SYSTEM_FILES = {'index.md', 'log.md', 'timeline.md', 'snapshot.md'}


# Hash-set: title -> [file_paths]
title_map = {}  # {category: {title: [paths]}}
for cat in CATEGORIES:
    title_map[cat] = {}

duplicates = []

def extract_h1(filepath):
    """Extract first H1 header from markdown file."""
    try:
        with open(filepath) as f:
            for line in f:
                if re.match(r'^# ', line.strip()):
                    return line.strip()[2:].strip()
    except Exception:
        pass
    return None

# Check each category directory
for cat in CATEGORIES:
    cat_dir = os.path.join(wiki_dir, cat)
    
    title_map[cat] = {}  # Reset for this category
    
    if not os.path.isdir(cat_dir):
        continue
        
    for fname in sorted(os.listdir(cat_dir)):
        if not fname.endswith('.md'):
            continue
            
        fpath = os.path.join(cat_dir, fname)
        h1_title = extract_h1(fpath)
        
        if not h1_title:
            continue
        
        # Hash-set lookup: O(1) per title
        rel_path = os.path.relpath(fpath, wiki_dir)
        
        if h1_title in title_map[cat]:
            duplicates.append({
                'title': h1_title,
                'category': cat,
                'files': [os.path.relpath(os.path.join(cat_dir, existing_file), wiki_dir) 
                         for existing_file in title_map[cat][h1_title]] + [rel_path]
            })
        else:
            title_map[cat].setdefault(h1_title, []).append(rel_path)

# Check root-level wiki files (not duplicated across categories)
root_h1_titles = {}
for fname in sorted(os.listdir(wiki_dir)):
    if not fname.endswith('.md'):
        continue
    fpath = os.path.join(wiki_dir, fname)
    
    h1_title = extract_h1(fpath)
    if not h1_title:
        continue
    
    # Skip system files from root duplicate check (they're handled separately)
    rel_path = fname.replace('.md', '').title() + '.Md'
    
    if h1_title in root_h1_titles:
        duplicates.append({
            'title': h1_title,
            'category': 'root',
            'files': [root_h1_titles[h1_title], fname]
        })
    else:
        root_h1_titles[h1_title] = fname

if len(duplicates) > 0:
    print(f"[!] Duplicate titles found ({len(duplicates)}):")
    for dup in duplicates:
        files_str = ', '.join(dup['files'])
        cat_label = f"category '{dup['category']}'" if dup['category'] != 'root' else 'root wiki/'
        print(f"    {dup['title']} ({cat_label}): {files_str}")
    
    sys.exit(1)

print("[✓] No duplicate titles found")
sys.exit(0)
PYEOF
