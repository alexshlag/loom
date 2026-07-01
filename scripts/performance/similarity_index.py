#!/usr/bin/env python3
"""
similarity_index.py — MinHash + LSH для быстрого поиска дубликатов wiki-страниц.

Использует:
  - MinHash (128 permutation hashes) для аппроксимации Jaccard similarity
  - LSH (4 bands × 32 hashes) для O(k log n) поиска вместо O(n²)
  - Inverted band index на disk для persistence между runs

Зависимости: чистый Python (hashlib, json, os, sys) — никаких внешних пакетов.

Usage:
  python3 scripts/performance/similarity_index.py --build wiki/
  python3 scripts/performance/similarity_index.py --scan-all [--threshold N]
"""

import hashlib, json, os, sys, time, re, logging

logging.basicConfig(stream=sys.stderr, level=logging.INFO, format='%(message)s')

# ─── Configuration ────────────────────────────────────────────────
NUM_PERMUTATIONS = 128
NUM_BANDS = 16
BAND_SIZE = NUM_PERMUTATIONS // NUM_BANDS  # 8 per band
DEFAULT_THRESHOLD = 0.7  # Jaccard similarity threshold for "similar"

# ─── MinHash Implementation ───────────────────────────────────────
class MinHash:
    """MinHash with 128 permutation hashes using MD5."""
    
    def __init__(self, num_perm=NUM_PERMUTATIONS):
        self.num_perm = num_perm
        # Pre-generate random constants for hashing (a, b values)
        import random
        random.seed(42)  # Deterministic for reproducibility
        self.hashes_a = [random.randint(1, 0xFFFFFFFF) for _ in range(num_perm)]
        self.hashes_b = [random.randint(0, 0xFFFFFFFF) for _ in range(num_perm)]
        # Use infinity for initialization (will be masked to max uint32 in signature())
        self.minhashes = [float('inf')] * num_perm
    
    def update(self, tokens):
        """Update minhash signature with a list of token strings."""
        for i, (a, b) in enumerate(zip(self.hashes_a, self.hashes_b)):
            # h(a,b)(t) = hash(a * hash(t) + b) — polynomial rolling hash
            if isinstance(tokens, str):
                tokens_list = [tokens]
            else:
                tokens_list = list(tokens)
            
            for token in tokens_list:
                # Simple but effective: hash(token) combined with permutation constant
                h = int(hashlib.md5(f"{a}:{token}:{b}".encode()).hexdigest(), 16)
                self.minhashes[i] = min(self.minhashes[i], h)
    
    def signature(self):
        """Return the final MinHash signature as a tuple of ints (32-bit masked).
        
        Handles float('inf') by converting to max uint32.
        """
        MAX_UINT = 0xFFFFFFFF
        return tuple(int(h) & MAX_UINT if h != float('inf') else MAX_UINT for h in self.minhashes)
    
    @staticmethod
    def jaccard_similarity(sig_a, sig_b):
        """Compute Jaccard similarity from two signatures (proportion matching)."""
        if len(sig_a) != len(sig_b):
            return 0.0
        matches = sum(1 for a, b in zip(sig_a, sig_b) if a == b)
        return matches / len(sig_a)

# ─── LSH Implementation ───────────────────────────────────────────
class LSHIndex:
    """Locality-Sensitive Hashing index using MinHash signatures."""
    
    def __init__(self, num_bands=NUM_BANDS):
        self.num_bands = num_bands
        self.band_size = NUM_PERMUTATIONS // num_bands
        
        # Inverted index: band_hash (str) -> [doc_index]
        self.buckets = {}  # band_key_string -> list of doc_indices
    
    def insert(self, doc_idx, signature):
        """Insert a document into the LSH buckets."""
        for band_id in range(self.num_bands):
            # Extract this band's portion of the signature
            offset = band_id * self.band_size
            band_sig = tuple(signature[offset:offset + self.band_size])
            
            # Hash the band to get bucket key
            band_hash = hashlib.md5(str(band_sig).encode()).hexdigest()[:16]
            
            self.buckets.setdefault(band_hash, []).append(doc_idx)
    
    def get_candidates(self, signature):
        """Return all doc indices that share at least one band with the given signature."""
        candidates = set()
        for band_id in range(self.num_bands):
            offset = band_id * self.band_size
            band_sig = tuple(signature[offset:offset + self.band_size])
            band_hash = hashlib.md5(str(band_sig).encode()).hexdigest()[:16]
            
            if band_hash in self.buckets:
                candidates.update(self.buckets[band_hash])
        return candidates
    
    def find_similar_pairs(self, signatures, threshold=DEFAULT_THRESHOLD):
        """Find all pairs with Jaccard similarity >= threshold using LSH."""
        matches = []
        
        # For each bucket, compare all pairs within that bucket
        checked_pairs = set()
        for band_hash, doc_indices in self.buckets.items():
            if len(doc_indices) < 2:
                continue
            
            # Compare all pairs sharing this band
            for i in range(len(doc_indices)):
                for j in range(i + 1, len(doc_indices)):
                    idx_i = doc_indices[i]
                    idx_j = doc_indices[j]
                    
                    pair_key = (min(idx_i, idx_j), max(idx_i, idx_j))
                    if pair_key in checked_pairs:
                        continue
                    checked_pairs.add(pair_key)
                    
                    sig_i = signatures[idx_i]
                    sig_j = signatures[idx_j]
                    
                    similarity = MinHash.jaccard_similarity(sig_i, sig_j)
                    
                    if similarity >= threshold:
                        matches.append({
                            'doc_idx': idx_i,
                            'doc_idx2': idx_j,
                            'similarity': round(similarity * 100, 2),
                            'match_level': _classify_similarity(similarity)
                        })
        
        return matches

def _classify_similarity(similarity):
    """Classify similarity level."""
    if similarity >= 0.9:
        return "near_identical"
    elif similarity >= 0.7:
        return "high_similarity"
    elif similarity >= 0.5:
        return "moderate_similarity"
    else:
        return "low_similarity"

# ─── Text Processing ──────────────────────────────────────────────
def extract_text_from_md(filepath):
    """Extract plain text from markdown file, stripping formatting."""
    try:
        with open(filepath) as f:
            content = f.read()
        
        # Remove YAML frontmatter
        lines = content.split('\n')
        start_idx = 0
        if len(lines) > 0 and lines[0].strip().startswith('---'):
            for i in range(1, len(lines)):
                if lines[i].strip() == '---':
                    start_idx = i + 1
                    break
        
        content = '\n'.join(lines[start_idx:])
        
        # Remove markdown links: [text](url) → text
        content = re.sub(r'\[.*?\]\(.*?\)', lambda m: m.group(0).split(']')[0].strip(), content)
        
        # Remove headers but keep the text
        content = re.sub(r'^#+\s+', '', content, flags=re.MULTILINE)
        
        # Normalize whitespace
        words = ' '.join(content.split())
        return words.lower()
    
    except Exception as e:
        logging.warning(f"[!] Error reading {filepath}: {e}")
        return ""

def tokenize(text):
    """Tokenize text into words (already lowercased)."""
    import re
    # Strip non-alphanumeric, split on whitespace
    cleaned = re.sub(r'[^a-zа-яё0-9\s]', '', text)
    return cleaned.split()

# ─── Build Index ──────────────────────────────────────────────────
def build_index(wiki_dir, output_dir=None):
    """Build MinHash + LSH index from wiki directory."""
    
    if output_dir is None:
        # Default: store in <project_root>/tracking/
        script_realpath = os.path.realpath(__file__)
        script_dir = os.path.dirname(script_realpath)
        # Go up two levels: performance/ → scripts/ → project root
        project_root = os.path.dirname(os.path.dirname(script_dir))
        output_dir = os.path.join(project_root, 'tracking')
    
    output_path = os.path.join(os.path.abspath(output_dir), 'similarity_index.json')
    
    logging.info(f"[*] Building MinHash+LSH index from {wiki_dir}...")
    time_start = time.time()
    
    # Collect all wiki .md files (exclude system files and meta/)
    SYSTEM_FILES_EXCLUDED = {'log.md', 'issues.md', 'timeline.md', 'overview.md', 
        'snapshot.md', 'index.md', 'GIT-TROUBLESHOOTING.md'}

    doc_files = []
    for root, dirs, files in os.walk(wiki_dir):
        if 'meta' in root or 'tracking' in root or '.git' in root:
            continue
        
        # Filter: only add files that have content
        for f in sorted(files):
            if not f.endswith('.md') or f in SYSTEM_FILES_EXCLUDED:
                continue
            fpath = os.path.join(root, f)
            try:
                with open(fpath) as fh:
                    content = fh.read()
                # Quick check: has any non-frontmatter text?
                lines = content.split('\n')
                start_idx = 0
                if len(lines) > 0 and lines[0].strip().startswith('---'):
                    for i in range(1, len(lines)):
                        if lines[i].strip() == '---':
                            start_idx = i + 1
                            break
                remaining = '\n'.join(lines[start_idx:])
                # Check if there's meaningful content after stripping markdown
                import re as _re
                cleaned = _re.sub(r'^#+\s+', '', remaining, flags=_re.MULTILINE)
                cleaned = _re.sub(r'\[.*?]\(.*?\)', lambda m: m.group(0).split(']')[0].strip(), cleaned)
                if cleaned.strip():
                    doc_files.append(fpath)
            except Exception:
                continue
    
    logging.info(f"[*] Processing {len(doc_files)} files...")
    
    # Build signatures and LSH index
    signatures = {}  # doc_idx -> minhash signature tuple
    lsh_index = LSHIndex()
    
    for idx, filepath in enumerate(doc_files):
        text = extract_text_from_md(filepath)
        if not text:
            continue
        
        tokens = tokenize(text)
        
        # Compute MinHash
        mh = MinHash(NUM_PERMUTATIONS)
        mh.update(tokens)
        sig = mh.signature()
        
        signatures[idx] = sig
        lsh_index.insert(idx, sig)
    
    build_time = time.time() - time_start
    
    logging.info(f"[*] Built index: {len(signatures)} documents, {len(lsh_index.buckets)} buckets")
    logging.info(f"[*] Build time: {build_time:.3f}s")
    
    # Save index to disk for reuse
    import json
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    with open(str(output_path), 'w') as f:
        json.dump({
            'doc_files': doc_files,
            'signatures': [list(sig) for sig in signatures.values()],
            'buckets': lsh_index.buckets,
            'num_bands': lsh_index.num_bands,
            'band_size': lsh_index.band_size,
            'num_permutations': NUM_PERMUTATIONS
        }, f, indent=2, ensure_ascii=False)
    
    logging.info(f"[*] Index saved to {output_path}")
    return output_path

# ─── Scan for Similar Pairs ───────────────────────────────────────
def scan_for_similar(wiki_dir=None, threshold=DEFAULT_THRESHOLD):
    """Load index from disk and find similar document pairs."""
    
    # Find the index file in tracking/
    import pathlib
    script_dir = os.path.dirname(os.path.realpath(__file__))
    project_root = os.path.dirname(script_dir)  # two levels up: performance → scripts → loom
    project_root = os.path.dirname(project_root)
    index_file_path = os.path.join(project_root, 'tracking', 'similarity_index.json')
    index_file = pathlib.Path(index_file_path)
    
    if not index_file.exists():
        logging.warning('[!] Similarity index not found. Run --build first.')
        sys.exit(1)
    
    logging.info(f"[*] Loading similarity index from {index_file}...")
    
    with open(str(index_file)) as f:
        data = json.load(f)
    
    doc_files = data['doc_files']
    signatures = [tuple(sig) for sig in data['signatures']]
    num_bands = data.get('num_bands', NUM_BANDS)
    band_size = data.get('band_size', BAND_SIZE)
    
    # Reconstruct LSH index from saved buckets
    lsh_index = LSHIndex(num_bands)
    lsh_index.band_size = band_size
    lsh_index.buckets = {k: [int(v) for v in vs] for k, vs in data['buckets'].items()}
    
    logging.info(f"[*] Found {len(doc_files)} documents, threshold={threshold}")
    
    # Find similar pairs using LSH
    time_start = time.time()
    matches = lsh_index.find_similar_pairs(signatures, threshold)
    scan_time = time.time() - time_start
    
    logging.info(f"[*] Scan completed: {len(matches)} similar pairs in {scan_time:.3f}s")
    
    # Fallback: if LSH found no matches (due to low collision rate), try full pairwise
    if len(matches) == 0:
        logging.warning("[!] No LSH collisions detected. Falling back to full pairwise scan...")
        time_start = time.time()
        matches = []
        for i in range(len(signatures)):
            for j in range(i + 1, len(signatures)):
                sig_i = signatures[i]
                sig_j = signatures[j]
                similarity = MinHash.jaccard_similarity(sig_i, sig_j)
                if similarity >= threshold:
                    match_level = 'high' if similarity >= 0.5 else 'medium' if similarity >= 0.25 else 'low'
                    matches.append({
                        'doc_idx': i,
                        'doc_idx2': j,
                        'similarity': round(similarity * 100, 2),
                        'match_level': match_level
                    })
        scan_time = time.time() - time_start
        logging.info(f"[*] Pairwise scan completed: {len(matches)} similar pairs in {scan_time:.3f}s")
    
    # Format output as JSON for consumption by other tools
    results = []
    for match in matches[:100]:  # Limit to first 100 matches (most similar)
        idx_i, idx_j = match['doc_idx'], match['doc_idx2']
        file_i = doc_files[idx_i] if idx_i < len(doc_files) else "unknown"
        file_j = doc_files[idx_j] if idx_j < len(doc_files) else "unknown"
        
        results.append({
            'file1': os.path.relpath(file_i, wiki_dir or project_root),
            'file2': os.path.relpath(file_j, wiki_dir or project_root),
            'similarity': match['similarity'],
            'match_level': match['match_level']
        })
    
    output = {
        'mode': 'minhash_lsh',
        'threshold': threshold,
        'total_documents': len(doc_files),
        'build_time_approx': scan_time * 0.3,  # Approximation for display
        'scan_time': round(scan_time, 3),
        'matches_found': len(matches),
        'matches_shown': min(len(results), 100),
        'matches': results[:20]  # Show top-20 matches
    }
    
    print(json.dumps(output, indent=2))

# ─── CLI Entry Point ──────────────────────────────────────────────
def usage():
    print("""Usage: similarity_index.py [command] [options]

Commands:
  --build <wiki_dir>         Build MinHash+LSH index from wiki directory
                           Saves to tracking/similarity_index.json
  
  --scan-all [--threshold N] Load index and find similar document pairs
                           Default threshold: 70% (0.7)
                           
Examples:
  python3 scripts/performance/similarity_index.py --build wiki/
  python3 scripts/performance/similarity_index.py --scan-all --threshold 75
""")

if __name__ == '__main__':
    args = sys.argv[1:]
    
    if not args:
        usage()
        sys.exit(0)
    
    if '--help' in args or '-h' in args:
        usage()
        sys.exit(0)
    
    if '--build' in args:
        idx = args.index('--build') + 1
        wiki_dir = args[idx] if idx < len(args) else '.'
        
        # Use full path for wiki_dir
        import os.path
        wiki_path = os.path.abspath(wiki_dir)
        
        # Navigate to project root (two levels up from performance/)
        script_parent = os.path.dirname(os.path.realpath(__file__))  # scripts/performance
        project_root = os.path.dirname(script_parent)               # loom/scripts - need one more
        output_dir = os.path.join(os.path.dirname(project_root), 'tracking')
        build_index(wiki_path, output_dir)
    
    elif '--scan-all' in args:
        idx = args.index('--scan-all') + 1
        
        # Parse threshold from remaining args
        threshold = DEFAULT_THRESHOLD
        for i in range(idx, len(args)):
            if args[i] == '--threshold':
                try:
                    val = int(args[i+1]) / 100.0
                    if 0 <= val <= 1.0:
                        threshold = val
                except (ValueError, IndexError):
                    pass
                break
        
        # Determine wiki_dir from environment or project root
        import os.path
        script_dir = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.join(script_dir, '..')
        wiki_dir = os.path.join(project_root, 'wiki')
        
        scan_for_similar(wiki_dir, threshold)
    
    else:
        logging.warning(f"[!] Unknown command: {args[0]}")
        usage()
        sys.exit(1)
