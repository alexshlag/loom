#!/usr/bin/env bash
# auto-crosslink.sh — Multi-level crosslink discovery for wiki pages
# Levels: H1 title → shared sources → frontmatter related → semantic keywords
# Output: JSON [{"path": "...", "score": N, "match_types": [...}], sorted by score desc
# Architecture: Script Suggests, Agent Decides (unless --auto-fix flag)
#
# Usage:
#   ./scripts/auto-crosslink.sh [page_path] [--include-root] [--max-results N] [--min-score N] [--file-list FILE] [--auto-fix-high-confidence]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
WIKI_DIR="${PROJECT_ROOT}/wiki"
META_DIR="${PROJECT_ROOT}/meta"
RAW_SOURCES_DIR="${PROJECT_ROOT}/raw/sources"

# Parse arguments
NEW_PAGE=""
INCLUDE_ROOT=false
SCORE_THRESHOLD=3     # minimum score to report
MAX_RESULTS=5         # maximum candidates returned
FILE_LIST=""
AUTO_FIX_HCC=false  # --auto-fix-high-confidence mode
IN_AUTO_MODE=false  # flag to prevent recursive calls

while [[ $# -gt 0 ]]; do
    case "$1" in
        --include-root) INCLUDE_ROOT=true; shift;;
        --max-results) MAX_RESULTS="$2"; shift 2;;
        --min-score) SCORE_THRESHOLD="$2"; shift 2;;
        --file-list) FILE_LIST="$2"; shift 2;;
        --auto-fix-high-confidence) AUTO_FIX_HCC=true; IN_AUTO_MODE=true; shift;;
        *) NEW_PAGE="$1"; shift;;
    esac
done

# ─── Auto-fix high-confidence mode (scan all orphans, fix them) ──
if [[ "$AUTO_FIX_HCC" == "true" ]]; then
    # Scan all wiki pages for orphans and auto-fix them
    ORPHAN_LIST=$(mktemp)
    ./scripts/orphan-pages.sh "${WIKI_DIR}" "${META_DIR}/backlinks.json" > "$ORPHAN_LIST" 2>/dev/null || true
    
    # Extract orphan paths from output (lines ending with "(no backlinks)")
    ALL_ORPHANS=()
    while IFS= read -r line; do
        if [[ "$line" == *"(no backlinks)" ]]; then
            page=$(echo "$line" | sed 's/(.*//' | tr -d ' ')
            ALL_ORPHANS+=("$page")
        fi
    done < <(grep "(no backlinks)" "$ORPHAN_LIST" || true)
    rm -f "$ORPHAN_LIST"
    
    # If no orphans, exit clean
    if [[ ${#ALL_ORPHANS[@]} -eq 0 ]]; then
        echo "[✓] auto-crosslink: no orphan pages found" >&2
        exit 0
    fi
    
    FIXED_COUNT=0
    
    for ORPHAN in "${ALL_ORPHANS[@]}"; do
        # Skip system files and skills directories
        if [[ "$ORPHAN" == *"skills/"* || "$ORPHAN" == "overview.md" || "$ORPHAN" == "log.md" ]]; then
            echo "[*] Skipping system/structural file: $ORPHAN" >&2
            continue
        fi
        
        # Find crosslink candidates for this orphan page (high threshold only)
        CANDIDATES=$(./scripts/auto-crosslink.sh --file-list "$(mktemp)" "$ORPHAN" --max-results 3 --min-score 5 --include-root 2>/dev/null || true)
        
        if [[ -n "$CANDIDATES" && "$CANDIDATES" != "[]" ]]; then
            # Process candidates and auto-fix high-confidence matches (score >=5)
            python3 << EOF
import json, sys, os, re

candidates = json.loads("""$CANDIDATES""")
page_path = "${ORPHAN}"
fixed_count = 0
wiki_dir = "$WIKI_DIR"

for c in candidates:
    score = c.get('score', 0)
    path = c['path']
    
    # Auto-fix if high confidence (score >=5)
    if score >= 5:
        # Ensure .md extension
        if not path.endswith('.md'):
            full_path = os.path.join(wiki_dir, f"{path}.md")
        else:
            full_path = os.path.join(wiki_dir, path)
        page_full_path = os.path.join(wiki_dir, f"{page_path}")
        if not page_full_path.endswith('.md'):
            page_full_path += '.md'

        # 1) Add outgoing crosslink from orphan TO candidate
        with open(page_full_path, 'r') as f:
            content = f.read()
        
        lines = content.split('\n')
        insert_idx = len(lines)
        for i, line in enumerate(lines):
            if line.strip() == '---' and i > 0:
                insert_idx = i + 1
                break
            elif line.startswith('## '):
                insert_idx = i
                break
        
        crosslink_lines = [f"- [[wiki/{path}]] (score: {score})"]
        lines = lines[:insert_idx] + crosslink_lines + lines[insert_idx:]
        content = '\n'.join(lines)
        with open(page_full_path, 'w') as f:
            f.write(content)
        
        print(f"Auto-linked {page_path} -> wiki/{path}")
        fixed_count += 1
    
        # 2) Add incoming backlink TO candidate (so candidate links to orphan)
        with open(full_path, 'r') as f:
            cand_content = f.read()
        
        cand_lines = cand_content.split('\n')
        cand_insert_idx = len(cand_lines)
        for i, line in enumerate(cand_lines):
            if line.strip() == '---' and i > 0:
                cand_insert_idx = i + 1
                break
            elif line.startswith('## '):
                cand_insert_idx = i
                break
        
        # Check if already linked
        already_linked = f"[[wiki/{page_path}]]" in cand_content or f"wiki/{page_path}" in cand_content
        if not already_linked:
            backlink_lines = [f"- [[wiki/{page_path}]] (score: {score}, incoming)"]
            cand_lines = cand_lines[:cand_insert_idx] + backlink_lines + cand_lines[cand_insert_idx:]
            with open(full_path, 'w') as f:
                f.write('\n'.join(cand_lines))
            print(f"Added backlink to wiki/{path} <- {page_path}")

print(json.dumps({"fixed": fixed_count}))
EOF
            FIXED_COUNT=$((FIXED_COUNT + 1))
        fi
    done
    
    echo "[✓] auto-crosslink: $FIXED_COUNT orphan pages processed" >&2
    # Regenerate backlinks index to reflect new crosslinks
    ./scripts/regenerate-backlinks.sh "$WIKI_DIR" "$META_DIR/backlinks.json" 2>/dev/null || true
    exit 0
fi

if [[ -z "${NEW_PAGE:-}" ]]; then
    # No page specified, normal mode can't proceed
    echo "[]"
    exit 1
fi

# Normalize path
NEW_REL="${NEW_PAGE#./}"
[[ "$NEW_REL" == wiki/* ]] && NEW_REL="${NEW_REL#wiki/}"
NEW_REL="${NEW_REL%.md}"
NEW_FILE="${WIKI_DIR}/${NEW_REL}.md"

if [[ ! -f "$NEW_FILE" ]]; then
    echo "[]"
    exit 1
fi

# Extract H1 title and keywords
TITLE=$(grep "^# " "$NEW_FILE" | head -1 | sed 's/^# //') || true
[[ -z "${TITLE:-}" ]] && TITLE="unknown"

# Extract shared sources: list of raw/ paths used in this page
get_sources() {
    local f="$1"
    # Look for sources in frontmatter or body
    sed -n '/^---$/,/^---$/p' "$f" 2>/dev/null | grep 'sources:' | head -5 || true
}

# Level 1: H1 title & keyword matching (score +3, +2)
echo "[*] Running auto-crosslink with multi-level analysis..." >&2

# Collect results in temp file
RESULTS_FILE=$(mktemp)
trap "rm -f $RESULTS_FILE" EXIT

find_and_score() {
    local filepath="$1"
    [[ "$filepath" == "$NEW_FILE" ]] && return
    
    local score=0
    local types=""
    
    # Level 1: Title match (+3)
    if grep -qiF "$TITLE" "$filepath" 2>/dev/null; then
        score=$((score + 3))
        types="title_match"
    fi
    
    # Level 4: Tag overlap match (+4 base for shared tags, +1 per additional)
    local NEW_TAGS=$(sed -n '/^---$/,/^---$/p' "$NEW_FILE" 2>/dev/null | grep 'tags:' | head -1 | sed 's/tags:[[:space:]]*//' || true)
    local FILE_TAGS=$(sed -n '/^---$/,/^---$/p' "$filepath" 2>/dev/null | grep 'tags:' | head -1 | sed 's/tags:[[:space:]]*//' || true)
    
    if [[ -n "${NEW_TAGS:-}" && -n "${FILE_TAGS:-}" ]]; then
        # Count overlapping tags by extracting words from both tag arrays
        local OVERLAP=0
        while IFS= read -r tag; do
            tag=$(echo "$tag" | tr -d '[]' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
            [[ "$tag" == "tags" || -z "$tag" ]] && continue  # skip the false positive and empty
            if echo "$FILE_TAGS" | grep -qi "${tag}"; then
                OVERLAP=$((OVERLAP + 1))
            fi
        done < <(echo "$NEW_TAGS" | tr ',' '\n')
        
        if [[ $OVERLAP -ge 2 ]]; then
            score=$((score + 4))
            types="$types,tag_overlap"
        elif [[ $OVERLAP -eq 1 ]]; then
            score=$((score + 2))
            types="$types,partial_tag_match"
        fi
    fi
    
    # Level 2: Shared source matching (+2 base, diminishing returns)
    local NEW_WIKI_SOURCES=$(get_sources "$NEW_FILE" | grep -v "^\s*sources:" || true)
    local FILE_WIKI_SOURCES=$(get_sources "$filepath" | grep -v "^\s*sources:" || true)
    
    # Count shared sources with diminishing factor: first=+2, rest=+1 each
    local SHARED_COUNT=0
    while IFS= read -r src; do
        [[ -z "$src" ]] && continue
        
        # Only count if this source exists in the other file too
        if grep -q "raw/" "$filepath" 2>/dev/null || grep -q "$src" "$filepath" 2>/dev/null; then
            SHARED_COUNT=$((SHARED_COUNT + 1))
            if [[ $SHARED_COUNT -eq 1 ]]; then
                score=$((score + 2))
            else
                score=$((score + 1))
            fi
        fi
    done <<< "$NEW_WIKI_SOURCES"
    
    # Level 3: Frontmatter related field match (+1)
    if grep -q "related:" "$filepath" 2>/dev/null; then
        if grep -q "${NEW_REL}.md\|${TITLE}" "$filepath" 2>/dev/null || true; then
            score=$((score + 1))
            types="$types,related_field_match"
        fi
    fi
    
    # Output candidate if above threshold
    [[ $score -ge $SCORE_THRESHOLD ]] || return 0
    
    # Normalize path for output
    REL_PATH="${filepath#$WIKI_DIR/}"
    echo "{\"path\":\"$REL_PATH\",\"score\":$score,\"match_types\":\"$types\"}" >> "$RESULTS_FILE"
}

# Scan all wiki pages to find candidates
while IFS= read -r filepath; do
    [[ -z "$filepath" ]] && continue
    find_and_score "$filepath"
done < <(find "$WIKI_DIR" -name "*.md" -type f ! -path "*/meta/*" ! -path "*/raw/*" 2>/dev/null | head -100)

# Also include root system files if requested
if [[ "$INCLUDE_ROOT" == "true" ]]; then
    for rf in AGENTS.md context.md PLAN.md; do
        if [[ -f "$PROJECT_ROOT/$rf" ]]; then
            find_and_score "$PROJECT_ROOT/$rf"
        fi
    done
fi

# Sort and return top results
if [[ -s "$RESULTS_FILE" ]]; then
    # Sort by score descending, take top MAX_RESULTS
    sort -t'"' -k4 -rn "$RESULTS_FILE" | head -n "$MAX_RESULTS" | python3 -c "
import json, sys
lines = [json.loads(l) for l in sys.stdin]
print(json.dumps(lines))
" || echo "[]"
else
    echo "[]"
fi

exit 0
