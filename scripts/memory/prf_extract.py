#!/usr/bin/env python3
"""prf_extract.py — TF-IDF-like term extraction for Pseudo-Relevance Feedback.

Usage:
  ./prf_extract.py --wiki-dir wiki/ --candidates "path1,path2,path3" [--stopwords stopwords.txt]

Output:
  term:score lines (stdout), sorted by score desc, threshold >= 1.5

IDF cache:
  Reads/writes meta/idf_cache.json for performance.
  Auto-rebuilds when wiki files are newer than cache.
"""

import argparse, json, math, os, re, sys, datetime
from collections import Counter
from pathlib import Path

STOPWORDS = set()
WORD_RE = re.compile(r'\b[a-z]{3,}\b')
CACHE_PATH = 'meta/idf_cache.json'
TOP_CANDIDATES = 3
TERM_LIMIT = 10
SCORE_THRESHOLD = 1.5

def load_stopwords(path):
    if path and os.path.isfile(path):
        with open(path) as f:
            for line in f:
                w = line.strip().lower()
                if w:
                    STOPWORDS.add(w)

def extract_words(text):
    return [m.group() for m in WORD_RE.finditer(text.lower()) if m.group() not in STOPWORDS]

def read_first_lines(filepath, n=20):
    """Read first n lines, skipping YAML frontmatter."""
    lines = []
    in_frontmatter = False
    try:
        with open(filepath, 'r', errors='replace') as f:
            for i, line in enumerate(f):
                if i == 0 and line.strip() == '---':
                    in_frontmatter = True
                    continue
                if in_frontmatter:
                    if line.strip() == '---':
                        in_frontmatter = False
                    continue
                if i >= n + (1 if in_frontmatter else 0):
                    break
                lines.append(line)
    except (IOError, OSError):
        return []
    return lines

def compute_tf(text_lines):
    """Return raw term frequency counts (not normalized)."""
    words = []
    for line in text_lines:
        words.extend(extract_words(line))
    if not words:
        return {}
    return Counter(words)

def load_or_rebuild_idf_cache(wiki_dir):
    """Load IDF cache, rebuild if stale or missing."""
    cache_file = Path(CACHE_PATH)
    rebuild = True
    if cache_file.exists():
        try:
            with open(cache_file) as f:
                cache = json.load(f)
            cache_mtime = cache_file.stat().st_mtime
            wiki_files = list(Path(wiki_dir).rglob('*.md'))
            wiki_newest = max(f.stat().st_mtime for f in wiki_files) if wiki_files else 0
            if cache_mtime >= wiki_newest:
                rebuild = False
        except (json.JSONDecodeError, KeyError, OSError):
            rebuild = True
    if rebuild:
        cache = build_idf_cache(wiki_dir)
        cache_file.parent.mkdir(parents=True, exist_ok=True)
        with open(cache_file, 'w') as f:
            json.dump(cache, f, indent=2)
    return cache

def build_idf_cache(wiki_dir):
    """Scan all wiki .md files, compute document frequency per term."""
    df = Counter()
    n = 0
    for md_path in Path(wiki_dir).rglob('*.md'):
        n += 1
        words_in_file = set()
        lines = read_first_lines(str(md_path), 20)
        for line in lines:
            words_in_file.update(extract_words(line))
        df.update(words_in_file)
    return {
        'term_df': dict(df),
        'N': n,
        'last_updated': datetime.datetime.now().isoformat()
    }

def main():
    parser = argparse.ArgumentParser(description='PRF term extraction for recall.sh')
    parser.add_argument('--wiki-dir', required=True, help='Path to wiki/ directory')
    parser.add_argument('--candidates', required=True, help='Comma-separated candidate page paths')
    parser.add_argument('--stopwords', default='', help='Path to stopwords file')
    args = parser.parse_args()

    load_stopwords(args.stopwords)
    wiki_dir = args.wiki_dir
    candidates = [c.strip() for c in args.candidates.split(',') if c.strip()]

    if len(candidates) < 2:
        sys.exit(0)

    # Take top-3 for PRF extraction
    top3 = candidates[:TOP_CANDIDATES]

    # Compute TF for each candidate (raw counts)
    combined_tf = Counter()
    for path in top3:
        lines = read_first_lines(path, 20)
        page_tf = compute_tf(lines)
        combined_tf.update(page_tf)

    # Get IDF cache
    idf_cache = load_or_rebuild_idf_cache(wiki_dir)
    idf_data = idf_cache.get('term_df', {})
    n_total = idf_cache.get('N', 1)

    # Small wiki fallback: N < 5 → IDF unreliable, exit early
    if n_total < 5:
        sys.exit(0)

    # Compute final scores: raw_count × idf
    scored = []
    for term, raw_count in combined_tf.items():
        df = idf_data.get(term, 1)
        idf = math.log(max(n_total / max(df, 1), 1.0))
        score = raw_count * idf
        if score >= SCORE_THRESHOLD:
            scored.append((term, round(score, 2)))

    # Sort by score desc, take top N
    scored.sort(key=lambda x: -x[1])
    for term, score in scored[:TERM_LIMIT]:
        print(f'{term}:{score}')

if __name__ == '__main__':
    main()
