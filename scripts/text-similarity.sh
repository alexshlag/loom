#!/usr/bin/env bash
# text-similarity.sh — Detect copy-paste chains via n-gram comparison
# Graceful by design: never fails, always returns JSON result

set -uo pipefail  # no errexit — we handle errors ourselves

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
CACHE_FILE="$PROJECT_ROOT/tracking/ngram_index.json"
SIMILARITY_CACHE="$PROJECT_ROOT/tracking/similarity_cache.json"
WIKI_DIR="$PROJECT_ROOT/wiki"
LOG_DIR="$PROJECT_ROOT/logs"
SIMILARITY_LOG="$LOG_DIR/text-similarity.log"

mkdir -p "$LOG_DIR" 2>/dev/null || true
mkdir -p "$(dirname "$CACHE_FILE")" 2>/dev/null || true

# Trap cleanup for .tmp files on crash/abort
trap 'rm -f "$CACHE_FILE.tmp" "$SIMILARITY_CACHE.tmp" 2>/dev/null' EXIT

# ─── Usage ──────────────────────────────────────────────────────────
usage() {
    echo "Usage: $0 <file1> <file2> [--threshold N] [--gram-size N] [--verbose]"
    echo "   OR:  $0 --scan-all [--threshold N] [--gram-size N] [--verbose]"
    echo ""
    echo "Arguments:"
    echo "  file1, file2     Two files to compare"
    echo "  --scan-all       Scan all wiki pages pairwise (O(n²) — use cautiously)"
    echo "  --threshold N    Minimum similarity % to report (default: 50)"
    echo "  --gram-size N    N-gram size for comparison (default: 3, range: 2-6)"
    echo "  --verbose        Print comparison steps to stderr"
    exit 0
}

# ─── Parse args ─────────────────────────────────────────────────────
FILE1=""
FILE2=""
SCAN_ALL=false
THRESHOLD=50
GRAM_SIZE=3
VERBOSE=false
POSITIONAL_FILES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h|usage) usage ;;
        --scan-all) SCAN_ALL=true; shift ;;
        --threshold) THRESHOLD="$2"; shift 2 ;;
        --gram-size) GRAM_SIZE="$2"; shift 2 ;;
        --verbose) VERBOSE=true; shift ;;
        *) POSITIONAL_FILES+=("$1"); shift ;;
    esac
done

# Validate gram size range (2-6)
if [[ "$GRAM_SIZE" -lt 2 ]] || [[ "$GRAM_SIZE" -gt 6 ]]; then
    GRAM_SIZE=3
fi

# Extract positional files (first two non-flag args)
if [[ ${#POSITIONAL_FILES[@]} -gt 0 ]]; then
    FILE1="${POSITIONAL_FILES[0]}"
fi
if [[ ${#POSITIONAL_FILES[@]} -ge 2 ]]; then
    FILE2="${POSITIONAL_FILES[1]}"
fi

# ─── Validation: input must be present for pairwise mode ──────────────
if [[ "$SCAN_ALL" == "false" ]] && [[ -z "${FILE1:-}" ]]; then
    echo '{"mode":"error","reason":"no_files_provided","matches":[]}'
    exit 0
fi

log_msg() {
    local msg="$1"
    echo "$(date -u '+%Y-%m-%dT%H:%M:%SZ') | $msg" >> "$SIMILARITY_LOG" 2>/dev/null || true
}

verbose_log() {
    if [[ "$VERBOSE" == "true" ]]; then
        echo "[similarity] $1" >&2
    fi
}

# ─── Extract plain text from markdown (strip headers, links, formatting) ──
extract_text() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        verbose_log "File not found: $file"
        return 2
    fi
    
    # Use Python for robust markdown text extraction
    python3 << PYEOF
import re, sys

try:
    with open("$file") as f:
        content = f.read()
    
    # Remove YAML frontmatter
    lines = content.split('\n')
    start_idx = 0
    if lines[0].strip().startswith('---'):
        for i in range(1, len(lines)):
            if lines[i].strip() == '---':
                start_idx = i + 1
                break
    
    # Remove markdown links: [text](url) → text
    content = '\n'.join(lines[start_idx:])
    content = re.sub(r'\[.*?\]\(.*?\)', lambda m: m.group(0).split(']')[0].strip(), content)
    
    # Remove headers (#, ##, ###) but keep the text
    content = re.sub(r'^#+\s+', '', content, flags=re.MULTILINE)
    
    # Remove horizontal rules and excessive blank lines
    content = re.sub(r'\n(-{3,}|\*{3,})\n', '\n\n', content)
    content = re.sub(r'\n{4,}', '\n\n\n', content)
    
    print(content.strip())
    
except Exception as e:
    sys.exit(2)
PYEOF

    return $?
}

# ─── Generate n-grams from text ──────────────────────────────────────
generate_ngrams() {
    local file="$1"
    local n="${2:-3}"
    
    python3 << PYEOF
import re, sys, os

try:
    with open("$file") as f:
        content = f.read()
    
    # Normalize: lowercase, strip punctuation, split into words
    text = re.sub(r'[^a-zа-яё0-9\s]', '', content.lower())
    words = text.split()
    
    # n defaults to 3 in get_ngrams
    ngrams = set()
    for i in range(len(words) - n + 1):
        gram = ' '.join(words[i:i+n])
        if len(gram.strip()) > 0:
            ngrams.add(gram)
    
    # Print to stdout, one per line
    for ng in sorted(ngrams):
        print(ng)

except Exception as e:
    sys.exit(2)
PYEOF

    return $?
}

# ─── Compute similarity between two files (Jaccard on n-grams) ────────
compute_similarity() {
    local file1="$1"
    local file2="$2"
    local n="${3:-3}"
    
    python3 << PYEOF
import json, re, sys

file1 = "$file1"
file2 = "$file2"
n = $n

def strip_markdown(text):
    lines = text.split('\n')
    start_idx = 0
    if lines and lines[0].strip().startswith('---'):
        for i in range(1, len(lines)):
            if lines[i].strip() == '---':
                start_idx = i + 1
                break
    content = '\n'.join(lines[start_idx:])
    content = re.sub(r'\[.*?\]\(.*?\)', lambda m: m.group(0).split(']')[0].lstrip('['), content)
    content = re.sub(r'^#+\s+', '', content, flags=re.MULTILINE)
    content = re.sub(r'\n(-{3,}|\*{3,})\n', '\n\n', content)
    return content

def normalize(text):
    text = re.sub(r'[^a-zа-яё0-9\s]', '', text.lower())
    return text.split()

def get_ngrams(words, n=3):
    ngrams = set()
    for i in range(len(words) - n + 1):
        gram = ' '.join(words[i:i+n])
        if len(gram.strip()) > 0:
            ngrams.add(gram)
    return ngrams

try:
    with open(file1) as f:
        words1 = normalize(strip_markdown(f.read()))
    with open(file2) as f:
        words2 = normalize(strip_markdown(f.read()))
    
    if len(words1) < n or len(words2) < n:
        result = {"similarity": 0.0, "common_ngrams": 0, "total_unique": 0, "match_level": "no_match"}
    else:
        ngrams1 = get_ngrams(words1, n)
        ngrams2 = get_ngrams(words2, n)
        
        common = ngrams1.intersection(ngrams2)
        union = ngrams1.union(ngrams2)
        
        if len(union) == 0:
            result = {"similarity": 0.0, "common_ngrams": 0, "total_unique": 0, "match_level": "no_match"}
        else:
            similarity = len(common) / len(union)
            
            if similarity >= 0.9:
                match_level = "near_identical"
            elif similarity >= 0.7:
                match_level = "high_similarity"
            elif similarity >= 0.5:
                match_level = "moderate_similarity"
            else:
                match_level = "low_similarity"
            
            result = {
                "similarity": round(similarity * 100, 2),
                "common_ngrams": len(common),
                "total_unique": len(union),
                "match_level": match_level
            }
    
    print(json.dumps(result))

except Exception as e:
    print(json.dumps({"similarity": 0.0, "error": str(e)}))
    sys.exit(2)
PYEOF

    return $?
}

# ─── Cache management ────────────────────────────────────────────────
load_cache() {
    if [[ -f "$CACHE_FILE" ]]; then
        python3 -c "import json; print(json.dumps(json.load(open('$CACHE_FILE')), indent=2))" 2>/dev/null || echo '{}'
    else
        echo '{}'
    fi
}

save_cache() {
    local cache_data="$1"
    echo "$cache_data" | python3 -c "
import json, sys

data = json.load(sys.stdin)
with open('$CACHE_FILE', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
" 2>/dev/null || log_msg "Cache save failed"
}

# ─── Main logic ──────────────────────────────────────────────────────
verbose_log "Starting similarity analysis"
log_msg "started | mode=${SCAN_ALL:+scan_all|pairwise} files=$FILE1,$FILE2"

if [[ "$SCAN_ALL" == "true" ]]; then
    # Scan all wiki pages using inverted n-gram index (O(n) build + fast search)
    verbose_log "Scanning with inverted n-gram index..."
    
    python3 << PYEOF
import json, os, sys, re, time

wiki_dir = "$WIKI_DIR"
threshold = $THRESHOLD
GRAM_SIZE_VAR=$GRAM_SIZE
cache_file = "$CACHE_FILE"
sim_cache_file = "$SIMILARITY_CACHE"

SYSTEM_FILES_EXCLUDED = {'log.md', 'issues.md', 'timeline.md', 'overview.md', 
    'snapshot.md', 'index.md', 'GIT-TROUBLESHOOTING.md'}

def strip_md(text):
    lines = text.split('\n')
    start_idx = 0
    if lines and lines[0].strip().startswith('---'):
        for i in range(1, len(lines)):
            if lines[i].strip() == '---':
                start_idx = i + 1
                break
    content = '\n'.join(lines[start_idx:])
    content = re.sub(r'\[.*?\]\(.*?\)', lambda m: m.group(0).split(']')[0].lstrip('['), content)
    content = re.sub(r'^#+\s+', '', content, flags=re.MULTILINE)
    return content

def normalize(text):
    text = re.sub(r'[^a-zа-яё0-9\s]', '', text.lower())
    return text.split()

def get_ngrams(words, n=3):
    return set(' '.join(words[i:i+n]) for i in range(len(words) - n + 1))

# Collect all wiki files (exclude meta/ and system files)
files = []
for root, dirs, _ in os.walk(wiki_dir):
    if 'meta' in dirs:
        dirs.remove('meta')
    for f in sorted(os.listdir(root)):
        if f.endswith('.md') and f not in SYSTEM_FILES_EXCLUDED:
            files.append(os.path.join(root, f))

print(f"[*] Processing {len(files)} wiki pages...", file=sys.stderr)
time_start = time.time()

# Build inverted index: ngram -> [file_idx]
ngram_index = {}
file_ngrams = {}  # file_path -> set of ngrams
for idx, fpath in enumerate(files):
    try:
        with open(fpath) as f:
            text = normalize(strip_md(f.read()))
        ngrams = get_ngrams(text, GRAM_SIZE_VAR)
        file_ngrams[fpath] = ngrams
        
        for ng in ngrams:
            if ng not in ngram_index:
                ngram_index[ng] = []
            ngram_index[ng].append(idx)
    except Exception as e:
        print(f"[!] Error reading {fpath}: {e}", file=sys.stderr)

print(f"[*] Built inverted index: {len(ngram_index)} unique n-grams, {len(files)} files", file=sys.stderr)
build_time = time.time() - time_start

# Find similar pairs using shared n-grams (Jaccard similarity)
time_search = time.time()
similarity_cache = {}
try:
    with open(sim_cache_file) as f:
        similarity_cache = json.load(f)
except Exception:
    pass

matches = []
checked_pairs = set()

for ng, file_indices in ngram_index.items():
    if len(file_indices) < 2:
        continue
    
    # Check all pairs sharing this n-gram
    for i in range(len(file_indices)):
        for j in range(i + 1, len(file_indices)):
            idx_i = file_indices[i]
            idx_j = file_indices[j]
            pair_key = (idx_i, idx_j)
            
            if pair_key in checked_pairs:
                continue
            checked_pairs.add(pair_key)
            
            # Check similarity cache
            cached_key = f"{files[idx_i].replace('/', '_')}|{files[idx_j].replace('/', '_')}"
            if cached_key in similarity_cache:
                result = similarity_cache[cached_key]
            else:
                ng_i = file_ngrams[files[idx_i]]
                ng_j = file_ngrams[files[idx_j]]
                
                common = len(ng_i.intersection(ng_j))
                union_len = len(ng_i.union(ng_j))
                similarity = common / union_len if union_len > 0 else 0
                
                if similarity >= 0.9:
                    match_level = "near_identical"
                elif similarity >= 0.7:
                    match_level = "high_similarity"
                elif similarity >= 0.5:
                    match_level = "moderate_similarity"
                else:
                    match_level = "low_similarity"
                
                result = {
                    "similarity": round(similarity * 100, 2),
                    "common_ngrams": common,
                    "total_unique": union_len,
                    "match_level": match_level
                }
            
            if result["similarity"] >= threshold:
                matches.append({
                    "file1": os.path.relpath(files[idx_i], wiki_dir),
                    "file2": os.path.relpath(files[idx_j], wiki_dir),
                    **result
                })
        
search_time = time.time() - time_search
print(f"[*] Search completed: {len(matches)} matches in {search_time:.3f}s", file=sys.stderr)

# Save similarity cache (atomic: write to .tmp then mv)
tmp_cache = sim_cache_file + '.tmp'
try:
    with open(tmp_cache, 'w') as f:
        json.dump(similarity_cache, f, indent=2)
    import os
    os.rename(tmp_cache, sim_cache_file)
except Exception:
    try:
        os.unlink(tmp_cache)
    except OSError:
        pass

print(json.dumps({"mode": "scan_all", "threshold": threshold, "matches": matches, 
                   "count": len(matches), "build_time": build_time}, indent=2))
PYEOF

else
    # Pairwise mode — compare two files
    verbose_log "Comparing: $FILE1 vs $FILE2"
    
    if [[ ! -f "$FILE1" ]] || [[ ! -f "$FILE2" ]]; then
        verbose_log "One or both files not found"
        echo '{"mode":"pairwise","file1":"'"$FILE1"'","file2":"'"$FILE2"'","similarity":0,"match_level":"no_match","common_ngrams":0}'
        log_msg "files_missing | $FILE1, $FILE2"
        exit 0
    fi
    
    # Check cache first (include gram_size in key)
    CACHE_KEY="${FILE1##*/}|${FILE2##*/}|g${GRAM_SIZE}"
    
    cached_result="$(python3 -c "
import json

try:
    with open('$CACHE_FILE') as f:
        data = json.load(f)
    key = '$CACHE_KEY'
    if key in data:
        print(json.dumps(data[key]))
    else:
        exit(1)
except Exception:
    exit(1)
" 2>/dev/null)" || true
    
    if [[ -n "$cached_result" ]]; then
        verbose_log "Cache hit for $CACHE_KEY"
        echo "$cached_result" | python3 -c "
import json, sys

match = json.load(sys.stdin)
print(json.dumps({\"mode\": \"pairwise\", \"file1\": \"$FILE1\", \"file2\": \"$FILE2\", **match}, indent=2))
" 2>/dev/null || echo '{"mode":"pairwise","similarity":0}'
        exit 0
    fi
    
    # Compute similarity via the function
    result=$(compute_similarity "$FILE1" "$FILE2" "$GRAM_SIZE")
    
    # Cache result (skip errors)
    echo "$result" | python3 -c "
import json, sys
d = json.load(sys.stdin)
if 'similarity' in d and 'error' not in d:
    cache = {}
    try:
        with open('$CACHE_FILE') as f:
            cache = json.load(f)
    except Exception:
        pass
    cache['$CACHE_KEY'] = d
    tmp_f = '$CACHE_FILE' + '.tmp'
    try:
        with open(tmp_f, 'w') as f:
            json.dump(cache, f, indent=2)
        import os
        os.rename(tmp_f, '$CACHE_FILE')
    except Exception:
        pass
" 2>/dev/null || true
    
    # Emit result with mode/file metadata
    echo "$result" | python3 -c "
import json, sys
result = json.load(sys.stdin)
print(json.dumps({'mode': 'pairwise', 'file1': '$FILE1', 'file2': '$FILE2', **result}, indent=2))
"

fi

# ─── Done gracefully ────────────────────────────────────────────────
exit 0
