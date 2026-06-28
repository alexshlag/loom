#!/usr/bin/env python3
"""h1-index.py — Builds H1 header index for fast wiki search.

Usage:
  python3 scripts/h1-index.py --build       # Build/update the index
  python3 scripts/h1-index.py --search "query" --max N  # Search using H1 index + full-text fallback

Output (for --search): path/to/file.md:matched_line (sorted by relevance score)
"""

import json, os, re, sys, glob, time

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WIKI_DIR = os.path.join(PROJECT_ROOT, "wiki")
H1_INDEX_FILE = os.path.join(PROJECT_ROOT, "meta", "h1-index.json")
SYSTEM_FILES_EXCLUDED = {
    'log.md', 'issues.md', 'timeline.md', 'overview.md', 
    'snapshot.md', 'index.md'
}

def extract_h1(filepath):
    """Extract H1 header from markdown file."""
    try:
        with open(filepath) as f:
            for line in f:
                if re.match(r'^# ', line.strip()):
                    return line.strip()[2:].strip()  # Remove '# ' prefix
    except Exception:
        pass
    return None

def build_index():
    """Build H1 header index -> {h1_text: [file_paths]}."""
    h1_index = {}
    all_files = []
    
    for root, dirs, files in os.walk(WIKI_DIR):
        if 'meta' in dirs or 'raw' in dirs:
            dirs[:] = [d for d in dirs if d not in ('meta', 'raw')]
        for f in sorted(files):
            if f.endswith('.md') and f not in SYSTEM_FILES_EXCLUDED:
                full_path = os.path.join(root, f)
                rel_path = os.path.relpath(full_path, WIKI_DIR)
                
                h1_text = extract_h1(full_path)
                if h1_text:
                    # Index with normalized form for fuzzy matching
                    h1_index.setdefault(h1_text.lower(), []).append(rel_path)
                    h1_index[rel_path] = {'h1': h1_text, 'path': rel_path}
                
                all_files.append(rel_path)
    
    os.makedirs(os.path.dirname(H1_INDEX_FILE), exist_ok=True)
    with open(H1_INDEX_FILE, 'w') as f:
        json.dump(h1_index, f, indent=2, ensure_ascii=False)
    
    print(f"[*] Built H1 index: {len(h1_index)} entries from {len(all_files)} files")
    return h1_index

def score_query(filepath, query):
    """Score a file against a query based on H1 match + frequency."""
    # Find the H1 for this file
    data = {}
    try:
        with open(H1_INDEX_FILE) as f:
            data = json.load(f)
    except Exception:
        return 0
    
    if not isinstance(data, dict):
        return 0
    
    # Get H1 text from index
    h1_text = None
    for k, v in data.items():
        if isinstance(v, dict) and 'h1' in v and v['path'] == filepath:
            h1_text = v['h1']
            break
        elif k.lower() == filepath.replace('/', '-').replace('.md', '').lower():
            # Fallback: try to find by normalized path
            continue
    
    if not h1_text:
        return 0
    
    score = 0
    query_lower = query.lower().split()
    
    # H1 match scoring (high priority)
    for qword in query_lower:
        words = h1_text.lower().split()
        
        # Exact word match → +3 per occurrence
        exact_match = sum(1 for w in words if w == qword)
        score += exact_match * 3
        
        # Prefix/substring match → +1 (e.g., 'symfony' matches 'Symfony')
        prefix_match = sum(1 for w in words if w.startswith(qword))
        score += prefix_match
    
    return max(score, 50)  # Base minimum score

def search_files(query):
    """Search using H1 index + fallback to full-text grep."""
    h1_index_data = {}
    try:
        with open(H1_INDEX_FILE) as f:
            h1_index_data = json.load(f)
    except Exception:
        pass
    
    # Phase 1: Fast lookup from H1 index (O(log n))
    query_lower = query.lower()
    matched_files = []
    
    # Try direct match against indexed H1s
    for key, value in h1_index_data.items():
        if isinstance(value, list):
            # This is a category -> paths mapping
            continue
        
        # Check if this key matches the query (normalized)
        normalized_key = key.lower().replace('/', '-').replace('.md', '')
        
        # Direct keyword match in H1
        for qword in query_lower.split():
            if qword in normalized_key or normalized_key.replace('-', ' ') in qword:
                matched_files.append(key)
                break
    
    print(f"[*] H1 index search found {len(matched_files)} candidates")
    
    # Phase 2: Full-text grep for remaining results (if needed)
    if len(matched_files) < 5:
        print("[*] Falling back to full-text grep...")
        
        for root, dirs, files in os.walk(WIKI_DIR):
            if 'meta' in dirs or 'raw' in dirs:
                dirs[:] = [d for d in dirs if d not in ('meta', 'raw')]
            
            query_pattern = re.compile(query.lower(), re.IGNORECASE)
            
            for f in files:
                if f.endswith('.md') and f not in SYSTEM_FILES_EXCLUDED:
                    full_path = os.path.join(root, f)
                    rel_path = os.path.relpath(full_path, WIKI_DIR)
                    
                    try:
                        with open(full_path) as fp:
                            content = fp.read().lower()
                        
                        matches_count = len(query_pattern.findall(content))
                        if matches_count > 0 and not any(fp == full_path for fp in matched_files):
                            matched_files.append(rel_path)
                    except Exception:
                        pass
    
    return matched_files

def main():
    import argparse
    parser = argparse.ArgumentParser(description='H1 Header Index Builder/Search')
    parser.add_argument('--build', action='store_true', help='Build H1 index')
    parser.add_argument('--search', type=str, help='Search query')
    parser.add_argument('--max', type=int, default=15, help='Max results (default: 15)')
    
    args = parser.parse_args()
    
    if args.build:
        build_index()
        return
    
    # Search mode (called from wiki-search.sh)
    query = args.search
    max_results = args.max
    
    matched_files = search_files(query)
    
    # Score and sort results
    scored_results = []
    for filepath in matched_files:
        score = score_query(filepath, query)
        scored_results.append((score, filepath))
    
    # Sort by score (descending), take top N
    scored_results.sort(key=lambda x: x[0], reverse=True)
    top_results = scored_results[:max_results]
    
    for score, filepath in top_results:
        print(f"{filepath}:{score}")

if __name__ == '__main__':
    main()
