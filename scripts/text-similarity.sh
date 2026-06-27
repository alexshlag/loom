#!/usr/bin/env bash
# text-similarity.sh — Detect copy-paste chains via n-gram comparison
# Graceful by design: never fails, always returns JSON result

set -uo pipefail  # no errexit — we handle errors ourselves

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
CACHE_FILE="$PROJECT_ROOT/tracking/similarity_cache.json"
WIKI_DIR="$PROJECT_ROOT/wiki"
LOG_DIR="$PROJECT_ROOT/logs"
SIMILARITY_LOG="$LOG_DIR/text-similarity.log"

mkdir -p "$LOG_DIR" 2>/dev/null || true
mkdir -p "$(dirname "$CACHE_FILE")" 2>/dev/null || true

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
    
    python3 << PYEOF
import json, os, sys

file1 = "$file1"
file2 = "$file2"
threshold = $THRESHOLD
n = 3

try:
    # Read files
    with open(file1) as f:
        text1 = f.read()
    with open(file2) as f:
        text2 = f.read()
    
    # Normalize texts
    def normalize(text):
        import re
        text = re.sub(r'[^a-zа-яё0-9\s]', '', text.lower())
        return text.split()
    
    words1 = normalize(text1)
    words2 = normalize(text2)
    
    # Generate n-grams
    def get_ngrams(words, n=3):
        ngrams = set()
        for i in range(len(words) - n + 1):
            gram = ' '.join(words[i:i+n])
            if len(gram.strip()) > 0:
                ngrams.add(gram)
        return ngrams
    
    ngrams1 = get_ngrams(words1, n)
    ngrams2 = get_ngrams(words2, n)
    
    # Jaccard similarity on n-grams
    common = ngrams1.intersection(ngrams2)
    union = ngrams1.union(ngrams2)
    
    if len(union) == 0:
        print(json.dumps({"similarity": 0.0, "common_ngrams": 0, "total_unique": 0, "match_level": "no_match"}))
        sys.exit(0)
    
    similarity = len(common) / len(union)
    match_level = "no_match"
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
    # Scan all wiki pages pairwise — collect results
    verbose_log "Scanning all wiki pages (O(n²))..."
    
    # Find all .md files in wiki/
    local_files=$(find "$WIKI_DIR" -name "*.md" -type f 2>/dev/null || true)
    
    if [[ -z "$(echo "$local_files")" ]]; then
        verbose_log "No markdown files found in $WIKI_DIR"
        echo '{"mode":"scan_all","threshold":'"$THRESHOLD"',"matches":[],"count":0}'
        exit 0
    fi
    
    # Use Python for efficient pairwise comparison and caching
    python3 << PYEOF
import json, os, sys

wiki_dir = "$WIKI_DIR"
threshold = $THRESHOLD
GRAM_SIZE_VAR=$GRAM_SIZE
cache_file = "$CACHE_FILE"

# Load cache
try:
    with open(cache_file) as f:
        cache = json.load(f)
except Exception:
    cache = {}

def normalize(text):
    import re
    text = re.sub(r'[^a-zа-яё0-9\s]', '', text.lower())
    return text.split()

def get_ngrams(words, n=3):
    ngrams = set()
    for i in range(len(words) - n + 1):
        gram = ' '.join(words[i:i+n])
        if len(gram.strip()) > 0:
            ngrams.add(gram)
    return ngrams

def compute_similarity(file1, file2, gram_size):
    try:
        with open(file1) as f:
            text1 = normalize(f.read())
        with open(file2) as f:
            text2 = normalize(f.read())
        
        ngrams1 = get_ngrams(text1, n=gram_size)
        ngrams2 = get_ngrams(text2, n=gram_size)
        
        if len(ngrams1) == 0 or len(ngrams2) == 0:
            return {"similarity": 0.0, "common_ngrams": 0, "match_level": "no_match"}
        
        common = ngrams1.intersection(ngrams2)
        union = ngrams1.union(ngrams2)
        similarity = len(common) / len(union) if len(union) > 0 else 0
        
        return {
            "similarity": round(similarity * 100, 2),
            "common_ngrams": len(common),
            "match_level": "high" if similarity >= 0.7 else "moderate" if similarity >= 0.5 else "low"
        }
    except Exception as e:
        return {"similarity": 0.0, "error": str(e)}

# Collect all files
files = sorted([os.path.join(wiki_dir, f) for f in os.listdir(wiki_dir) if f.endswith('.md')])

matches = []
for i in range(len(files)):
    for j in range(i+1, len(files)):
        key = f"{os.path.basename(files[i])}|{os.path.basename(files[j])}|g{GRAM_SIZE_VAR}"
        
        # Check cache first
        if key in cache:
            result = cache[key]
        else:
            result = compute_similarity(files[i], files[j], int(GRAM_SIZE_VAR))
            cache[key] = result
        
        if result.get("similarity", 0) >= threshold:
            matches.append({
                "file1": os.path.basename(files[i]),
                "file2": os.path.basename(files[j]),
                **result
            })

# Save updated cache
try:
    with open(cache_file, 'w') as f:
        json.dump(cache, f, indent=2)
except Exception:
    pass

print(json.dumps({"mode": "scan_all", "threshold": threshold, "matches": matches, "count": len(matches)}, indent=2))
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
    
    # Compute similarity (pass n and threshold to Python)
    python3 << PYEOF
import json, os, sys

file1 = "$FILE1"
file2 = "$FILE2"
n = $GRAM_SIZE
threshold = $THRESHOLD
cache_file = "$CACHE_FILE"
gram_size = $GRAM_SIZE
cache_key = f"{os.path.basename(file1)}|{os.path.basename(file2)}|g{gram_size}"

try:
    with open(file1) as f:
        text1 = f.read()
    with open(file2) as f:
        text2 = f.read()

    def normalize(text):
        import re
        text = re.sub(r'[^a-zа-яё0-9\s]', '', text.lower())
        return text.split()

    def get_ngrams(words, n=3):
        ngrams = set()
        for i in range(len(words) - n + 1):
            gram = ' '.join(words[i:i+n])
            if len(gram.strip()) > 0:
                ngrams.add(gram)
        return ngrams

    words1 = normalize(text1)
    words2 = normalize(text2)
    
    ngrams1 = get_ngrams(words1, n=int(n))
    ngrams2 = get_ngrams(words2, n=int(n))
    
    if len(ngrams1) == 0 or len(ngrams2) == 0:
        similarity = 0.0
        common = 0
    else:
        common_set = ngrams1.intersection(ngrams2)
        union = ngrams1.union(ngrams2)
        common = len(common_set)
        similarity = common / len(union) if len(union) > 0 else 0
    
    match_level = "high" if similarity >= 0.7 else "moderate" if similarity >= 0.5 else "low"
    
    result = {
        "mode": "pairwise",
        "file1": file1,
        "file2": file2,
        "similarity": round(similarity * 100, 2),
        "common_ngrams": common,
        "match_level": match_level
    }
    
    # Update cache
    try:
        with open(cache_file) as f:
            cache = json.load(f)
    except Exception:
        cache = {}
    
    cache[cache_key] = result
    try:
        with open(cache_file, 'w') as f:
            json.dump(cache, f, indent=2)
    except Exception:
        pass
    
    print(json.dumps(result))

except Exception as e:
    print(json.dumps({"mode": "pairwise", "similarity": 0.0, "error": str(e)}))
    sys.exit(2)
PYEOF

fi

# ─── Done gracefully ────────────────────────────────────────────────
exit 0
