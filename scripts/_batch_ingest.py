#!/usr/bin/env python3
"""
_batch_ingest.py — Batch ingest clustering engine

Usage: python3 _batch_ingest.py <source_list_file>
Input: Text file with one source path per line
Output: JSON to stdout with clusters and metadata

Phase 1: Extract H1, tags, first-sentence from each source
Phase 2: Cluster by shared keywords/entities (>= 2 sources share keyword)
"""

import json
import re
from collections import defaultdict
import sys
import os


def extract_keywords(text):
    """Extract meaningful keywords from text."""
    words = set()
    
    # Extract from tags line in frontmatter
    tag_match = re.search(r'tags:\s*\[(.*?)\]', text)
    if tag_match:
        for tag in tag_match.group(1).split(','):
            word = tag.strip().lower()
            if len(word) > 2:  # Skip very short tags
                words.add(word)
    
    # Extract from H1 and body (first 500 chars for speed)
    text_snippet = text[:500].lower()
    stop_words = {'and', 'the', 'for', 'with', 'this', 'that', 'have', 'are', 'was', 'been', 'not'}
    
    for word in re.findall(r'\b[a-zA-Zа-яё]{3,}\b', text_snippet):
        if word not in stop_words:
            words.add(word)
    
    return words


def extract_metadata(content):
    """Extract H1, first sentence, and tags from markdown content."""
    lines = content.split('\n')
    
    # Extract H1
    h1_match = re.search(r'^# (.+)$', content, re.MULTILINE)
    h1 = h1_match.group(1).strip() if h1_match else "Unknown"
    
    # First sentence (after frontmatter)
    first_sentence = ""
    in_frontmatter = False
    for line in lines:
        if line.strip() == '---':
            if not in_frontmatter:
                in_frontmatter = True
            else:
                in_frontmatter = False
                continue
        elif in_frontmatter and line.startswith('tags:'):
            continue
        
        if not in_frontmatter and line.strip():
            first_sentence = line.strip()
            break
    
    # Extract keywords from content
    keywords = extract_keywords(content)
    
    return {
        'h1': h1,
        'first_sentence': first_sentence[:200],
        'keywords': sorted(list(keywords))
    }


def cluster_sources(file_metadata_list):
    """Cluster sources by shared keywords (>= 2 sources share keyword)."""
    # Build keyword index: keyword -> list of source files
    keyword_index = defaultdict(list)
    
    for src_path, metadata in file_metadata_list.items():
        for kw in metadata['keywords']:
            keyword_index[kw].append(src_path)
    
    # Greedy cluster building (sorted by frequency desc)
    clusters = []
    used_sources = set()
    
    for kw, sources in sorted(keyword_index.items(), key=lambda x: -len(x[1])):
        if len(sources) < 2:
            continue
        
        # Check if any source already in existing cluster (merge)
        merged_cluster = None
        for cluster in clusters:
            has_overlap = any(s in cluster['sources'] for s in sources)
            if has_overlap:
                cluster['sources'].extend([s for s in sources if s not in cluster['sources']])
                cluster['keywords'].append(kw)
                merged_cluster = True
                break
        
        # Create new cluster if no merge and >= 2 sources
        if not merged_cluster and len(sources) >= 2:
            clusters.append({
                'keyword': kw,
                'sources': list(dict.fromkeys(sources)),  # Deduplicate
                'shared_keyword_count': len(sources),
                'keywords': []  # Will be populated when merging or finalizing
            })
    
    return clusters


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 _batch_ingest.py <source_list_file>", file=sys.stderr)
        sys.exit(1)
    
    source_list_path = sys.argv[1]
    
    if not os.path.exists(source_list_path):
        print(f"Error: Source list file '{source_list_path}' not found", file=sys.stderr)
        sys.exit(1)
    
    # Read source files
    with open(source_list_path, 'r') as f:
        source_files = [line.strip() for line in f if line.strip()]
    
    if not source_files:
        print("Error: No source files listed", file=sys.stderr)
        sys.exit(1)
    
    # Phase 1: Extract metadata from each source
    file_metadata_list = {}
    valid_sources = []
    
    for src_path in source_files:
        try:
            with open(src_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            metadata = extract_metadata(content)
            file_metadata_list[src_path] = metadata
            valid_sources.append(src_path)
        
        except Exception as e:
            print(f"Warning: Error reading {src_path}: {e}", file=sys.stderr)
    
    if not valid_sources:
        sys.exit(1)
    
    # Phase 2: Cluster sources
    clusters = cluster_sources(file_metadata_list)
    
    # Build final output
    used_sources = set()
    individual_sources = []
    
    for src in valid_sources:
        if any(src in c['sources'] for c in clusters):
            used_sources.add(src)
        else:
            individual_sources.append(src)
    
    output = {
        'total_sources': len(valid_sources),
        'valid_sources_count': len(valid_sources),
        'clusters': [],
        'individual_sources': []
    }
    
    for i, cluster in enumerate(clusters):
        unique_sources = list(dict.fromkeys(cluster['sources']))
        
        # Generate cluster name from first two sources' H1s
        sample_h1s = [file_metadata_list.get(s, {}).get('h1', 'Unknown')[:50] 
                      for s in unique_sources[:2]]
        cluster_name = f"Shared entities: {', '.join(sample_h1s)}"
        
        output['clusters'].append({
            'cluster_id': f"cluster-{i+1}",
            'name': cluster_name,
            'sources': unique_sources,
            'shared_keywords_count': len(unique_sources)
        })
    
    # Add individual sources (not clustered)
    for src in valid_sources:
        if src not in used_sources:
            output['individual_sources'].append(src)
    
    print(json.dumps(output, indent=2))


if __name__ == '__main__':
    main()
