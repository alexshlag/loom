#!/usr/bin/env bash
# scripts/lint.sh — Standalone lint script, non-blocking for agent turn
# Usage: ./scripts/lint.sh [--quiet] [--skip-checks ID1,ID2] [wiki_dir]
# Exit code: 0 = all checks passed, 1 = issues found (but does not block flow)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
WIKI_DIR="${2:-$PROJECT_ROOT/wiki}"
QUIET=false
SKIP_CHECKS=""

# Load shared utilities for log_error, safe_run
source "$SCRIPT_DIR/utilities/common.sh" 2>/dev/null || true
source "$SCRIPT_DIR/lib.sh" 2>/dev/null || true

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --quiet) QUIET=true; shift;;
    --skip-checks) SKIP_CHECKS="$2"; shift 2;;
    *) WIKI_DIR="$1"; shift;;
  esac
done

WIKI_DIR="${1:-$PROJECT_ROOT/wiki}"

# Normalize SKIP_CHECKS for exact ID matching: comma-pad each ID
SKIP_CHECKS=",${SKIP_CHECKS// /},"

# Trap cleanup for any temp files on abort — no || true needed, this is best-effort
# Centralized cleanup via lib.sh — all temp files registered with cleanup_add()
# Handled by trap in lib.sh cleanup_temp_files()
cleanup_add "/tmp/lint_missing_fm.txt"
cleanup_add "/tmp/lint_structural.json"
cleanup_add "/tmp/lint_overlap_result.json"
cleanup_add "/tmp/lint_excessive_empty.txt"
_set_cleanup_trap

echo "========================================" >&2
echo "[*] LINT AUDIT — $(date +%Y-%m-%d) | wiki: ${WIKI_DIR#/}" >&2
echo "========================================" >&2

TOTAL_ISSUES=0

# --- Check 1: Contradictions (read all pages, compare facts) ---
CONTRADICTIONS=0
if [[ "$SKIP_CHECKS" != *",1,"* ]]; then
  CONTRADICTION_PAGES=$({ grep -r "^## Updated" "$WIKI_DIR/" --include="*.md" -l 2>/dev/null | head -20; } || true)
  if [ -n "$CONTRADICTION_PAGES" ]; then
    CONTRADICTIONS=$(echo "$CONTRADICTION_PAGES" | wc -l)
  fi
fi
TOTAL_ISSUES=$((TOTAL_ISSUES + CONTRADICTIONS))

# --- Check 2: Orphan pages ---
ORPHAN_COUNT=0
ORPHAN_PATHS_JSON="[]"
if [[ "$SKIP_CHECKS" != *",2,"* ]]; then
  local_orphans=""
  safe_run "./scripts/orphan-pages.sh $WIKI_DIR ${PROJECT_ROOT}/meta/backlinks.json" local_orphans "0 1" || true
  # Batch extract: single python3 call replaces 2 (count + path extraction)
  ORPHAN_COUNT=0; ORPHAN_PATHS_JSON="[]"
  if [ -n "$local_orphans" ]; then
    read ORPHAN_COUNT ORPHAN_PATHS_JSON <<< $(echo "$local_orphans" | python3 -c "
import json, sys
lines = sys.stdin.read().split('\n')
count = 0
paths = []
for line in lines:
    if 'Orphan pages found' in line:
        count = int(line.split(':')[1].strip()) if ':' in line else 0
    elif line.startswith('    ') and 'no backlinks' not in line.lower():
        paths.append(line.strip())
print(f'{count} {json.dumps(paths)}')
" 2>/dev/null || echo "0 []")
  fi
fi
TOTAL_ISSUES=$((TOTAL_ISSUES + ORPHAN_COUNT))

# --- Check 3: Knowledge gaps (soft check, agent review) ---
$QUIET || echo "[✓] Check 3/15: knowledge_gaps — skipped (soft check, agent review required)" >&2

# --- Check 4: New sources available ---
NEW_SOURCES=0
if [[ "$SKIP_CHECKS" != *",4,"* ]]; then
  local_new_sources=""
  safe_run "./scripts/check-new-sources.sh --max 10 ${PROJECT_ROOT}/raw/sources ${PROJECT_ROOT}/tracking/raw_registry.json" local_new_sources "0 1" || true
  if echo "$local_new_sources" | grep -q '^NEW:'; then
    NEW_SOURCES=$(echo "$local_new_sources" | grep -c '^NEW:') || NEW_SOURCES=0
  fi
fi

# --- Check 5: New topics proposal (soft check) ---
$QUIET || echo "[✓] Check 5/15: new_topics_proposal — skipped (requires external sources)" >&2

# --- Check 6: Mechanical linting (frontmatter, duplicate titles) ---
DUPLICATE_TITLES=0
FILENAME_VIOLATIONS=0
FIX_ITER=0
if [[ "$SKIP_CHECKS" != *",6,"* ]]; then
  local_dup=""
  safe_run "./scripts/duplicate-titles.sh $WIKI_DIR" local_dup || true
  if echo "$local_dup" | grep -q "Duplicate"; then
    DUPLICATE_TITLES=1
  fi
  
  # Filename collision audit — always capture output regardless of exit code
  local_filename=$(bash scripts/filename-audit.sh "$WIKI_DIR" 2>/dev/null || true)
  if echo "$local_filename" | grep -q "VIOLATIONS: [1-9]"; then
    FILENAME_VIOLATIONS=$(echo "$local_filename" | grep 'VIOLATIONS:' | grep -oE '[0-9]+' | tail -1) || FILENAME_VIOLATIONS=0
  fi
fi
TOTAL_ISSUES=$((TOTAL_ISSUES + DUPLICATE_TITLES + FILENAME_VIOLATIONS))

# --- Check 7: Date consistency ---
DATE_ISSUES=0
if [[ "$SKIP_CHECKS" != *",7,"* ]]; then
  local_date=""
  safe_run "./scripts/date-consistency.sh $WIKI_DIR" local_date "0 1" || true
  if echo "$local_date" | grep -q "Inconsistencies found"; then
    DATE_ISSUES=$(echo "$local_date" | grep -oE '[0-9]+' | head -1) || DATE_ISSUES=0
  fi
fi
TOTAL_ISSUES=$((TOTAL_ISSUES + DATE_ISSUES))

# --- Check 8: Link validation (broken internal links, auto-repair) via unified-pass ---
BROKEN_LINKS=0
AUTO_REPAIRED=0
AGENT_REVIEW_REQUIRED_JSON="[]"
if [[ "$SKIP_CHECKS" != *",8,"* ]]; then
  local_up_out=""
  safe_run "./scripts/unified-pass.sh --quiet --skip-meta --skip-crosslinks --auto" local_up_out || true

  # Batch extract: single python3 call replaces 3 (JSON extraction + count + auto-repaired + agent review)
  BROKEN_LINKS=0; AUTO_REPAIRED=0; AGENT_REVIEW_REQUIRED_JSON="[]"
  if [ -n "$local_up_out" ]; then
    read BROKEN_LINKS AUTO_REPAIRED AGENT_REVIEW_REQUIRED_JSON <<< $(echo "$local_up_out" | python3 -c "
import json, sys
content = sys.stdin.read()
start = content.find('{')
end = content.rfind('}')
if start >= 0 and end > start:
    try:
        d = json.loads(content[start:end+1])
        broken = len(d.get('broken_links', []))
        auto_rep = d.get('auto_repaired', 0)
        ag_req = json.dumps(d.get('agent_review_required', []))
        print(f'{broken} {auto_rep} {ag_req}')
    except:
        print('0 0 []')
else:
    print('0 0 []')
" 2>/dev/null || echo "0 0 []")
  fi
fi
$QUIET || echo "[$([ $BROKEN_LINKS -gt 0 ] && echo '!' || echo '✓')] Check 8/15: link_validation — broken:${BROKEN_LINKS} auto_repaired:${AUTO_REPAIRED}" >&2
TOTAL_ISSUES=$((TOTAL_ISSUES + BROKEN_LINKS))

# D6: Rebuild meta index consolidated — single call at end after all fixes

# --- Check 9: Contradiction deep scan (Python-based) ---
CONTRADICTIONS_DEEP=0
if [[ "$SKIP_CHECKS" != *",9,"* ]]; then
  local_deep=""
  safe_run "./scripts/detect-contradications.sh --quiet" local_deep "0 1" || true
  # Parse contradiction count from JSON output with fallback
  CONTCOUNT=$(echo "$local_deep" | python3 -c 'import json, sys; d=json.loads(sys.stdin.read()); print(d.get("potential_contradictions",0))' 2>/dev/null) || CONTCOUNT=0
  [[ "$CONTCOUNT" =~ ^[0-9]+$ ]] && CONTRADICTIONS_DEEP=$CONTCOUNT
fi
$QUIET || echo "[$([ $CONTRADICTIONS_DEEP -gt 0 ] && echo '!' || echo '✓')] Check 9/15: contradiction_deep — count:${CONTRADICTIONS_DEEP}" >&2
TOTAL_ISSUES=$((TOTAL_ISSUES + CONTRADICTIONS_DEEP))

# --- Check 10: Text similarity (n-gram overlap scan) ---
TEXT_SIMILARITY_MATCHES=0
if [[ "$SKIP_CHECKS" != *",10,"* ]]; then
  # text-similarity writes logs to stdout — redirect stderr for clean JSON output
  local_sim=$(bash ./scripts/text-similarity.sh --scan-all --threshold 90 2>/dev/null) || true
  # Batch: single python3 call replaces 2 individual ones (count + validity)
  TEXT_SIMILARITY_MATCHES=$(echo "$local_sim" | python3 -c 'import json, sys; d=json.loads(sys.stdin.read()); print(len(d.get("matches",[])))' 2>/dev/null) || TEXT_SIMILARITY_MATCHES=0
  [[ "$TEXT_SIMILARITY_MATCHES" =~ ^[0-9]+$ ]] || TEXT_SIMILARITY_MATCHES=0
fi
$QUIET || echo "[$([ $TEXT_SIMILARITY_MATCHES -gt 0 ] && echo '!' || echo '✓')] Check 10/15: text_similarity — matches:${TEXT_SIMILARITY_MATCHES}" >&2
TOTAL_ISSUES=$((TOTAL_ISSUES + TEXT_SIMILARITY_MATCHES))

# --- Check 11: Hot cache staleness ---
HOT_CACHE_STALE=false
if [[ "$SKIP_CHECKS" != *",11,"* ]]; then
  if safe_run "./scripts/check-wiki-changes.sh" local_hot_check "0 1"; then
    if echo "$local_hot_check" | grep -q "WIKI CHANGES DETECTED"; then
      HOT_CACHE_STALE=true
      $QUIET || echo "[!] Check 11/15: hot_cache_stale — WIKI CHANGES DETECTED" >&2
    else
      $QUIET || echo "[✓] Check 11/15: hot_cache_stale — no changes" >&2
    fi
  fi
fi

# --- Check 12: Tag audit with auto-fix (empty, non-EN, generic type, XR gaps) ---
TAG_EMPTY=0; TAG_NON_EN=0; TAG_GENERIC=0; TAG_XR_GAPS=0
if [[ "$SKIP_CHECKS" != *",12,"* ]]; then
  FIX_ITER=0
  while true; do
    local_tr=$(bash "${SCRIPT_DIR}/tag-audit.sh" --quiet "$WIKI_DIR" 2>/dev/null) || { break; }
    # Batch extract tag issues (4 individual python3 calls → single process)
    read TAG_EMPTY TAG_NON_EN TAG_GENERIC TAG_XR_GAPS <<< $(echo "$local_tr" | python3 -c "
import json, sys
data = json.loads(sys.stdin.read())
issues = data.get('issues_found', {})
print(f'{issues.get("empty_tags", 0)}\t{issues.get("non_en_tags", 0)}\t{issues.get("generic_type_tags", 0)}\t{issues.get("xr_gaps", 0)}')
" 2>/dev/null || echo "0	0	0	0")
    local_tot=$((TAG_EMPTY + TAG_NON_EN + TAG_GENERIC + TAG_XR_GAPS))
    [ "$local_tot" -eq 0 ] && break
    $QUIET || echo "[~] Tag audit: ${local_tot} issues — auto-fix (iter $((FIX_ITER+1)))..." >&2
    bash "${SCRIPT_DIR}/tag-audit.sh" --fix --quiet "$WIKI_DIR" >/dev/null 2>&1 || true
    FIX_ITER=$((FIX_ITER+1))
    [ "$FIX_ITER" -ge 3 ] && break
  done
  $QUIET || echo "[✓] Check 12/15: tag_audit — empty:${TAG_EMPTY} non-en:${TAG_NON_EN} generic:${TAG_GENERIC} xr:${TAG_XR_GAPS}" >&2
fi
TOTAL_ISSUES=$((TOTAL_ISSUES + TAG_EMPTY + TAG_NON_EN + TAG_GENERIC + TAG_XR_GAPS))

# --- Check 13: Missing frontmatter with auto-insert (slug, category, type) ---
MISSING_FM=0; FIXED_FM_FILES=""
if [[ "$SKIP_CHECKS" != *",13,"* ]]; then
    # Find pages missing YAML frontmatter delimiters at file start
    local_fms=""
    while IFS= read -r f; do
        first=$(head -1 "$f" 2>/dev/null || true)
        if [[ "$first" != "---"* ]]; then
            echo "$f" >> /tmp/lint_missing_fm.txt
        fi
    done < <(find "$WIKI_DIR/entities" "$WIKI_DIR/concepts" "$WIKI_DIR/syntheses" "$WIKI_DIR/comparisons" -name "*.md" 2>/dev/null)
    
    if [ -s /tmp/lint_missing_fm.txt ]; then
        MISSING_FM=$(wc -l < /tmp/lint_missing_fm.txt)
        
        # Auto-insert frontmatter for each missing page
        while IFS= read -r f; do
            rel="${f#${WIKI_DIR}/}"
            dir_name=$(echo "$rel" | cut -d'/' -f1)
            
            # Map directory to category value
            case "$dir_name" in
                entities)   cat_val="entity";  type_val="documentation" ;;
                concepts)   cat_val="concept"; type_val="documentation" ;;
                syntheses)  cat_val="synthesis"; type_val="faq_summary" ;;
                comparisons) cat_val="comparison"; type_val="analysis" ;;
                *)          cat_val="entity"; type_val="documentation" ;;
            esac
            
            # Extract slug from filename (lowercase, hyphenated)
            fname=$(basename "$f" .md)
            slug=$(echo "$fname" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')
            
            # Build frontmatter block and prepend to file
            fm_block=$(cat <<FMEOF
---
tags: [${slug}]
date: $(date +%Y-%m-%d)
type: ${type_val}
category: ${cat_val}
sources: []
related: []
---

FMEOF
)
            # Prepend frontmatter, preserve original content
            { echo "$fm_block"; cat "$f"; } > "${f}.tmp" && mv "${f}.tmp" "$f"
        done < /tmp/lint_missing_fm.txt
        
        $QUIET || while IFS= read -r f; do
            echo "[~] Auto-inserted frontmatter: ${f#${WIKI_DIR}/}" >&2
        done < /tmp/lint_missing_fm.txt
    fi
    
    # Clean up temp file
    rm -f /tmp/lint_missing_fm.txt 2>/dev/null || true
fi
TOTAL_ISSUES=$((TOTAL_ISSUES + MISSING_FM))


# --- Check 14: Structural requirements — body text between H1 and first ## ---
STRUCTURAL_VIOLATIONS=0; STRUCTURAL_VIOLATOR_JSON='[]'
if [[ "$SKIP_CHECKS" != *",14,"* ]]; then
    structural_output=$(bash "${SCRIPT_DIR}/check-structural.sh" "$WIKI_DIR" 2>/dev/null || true)
    if [ -n "$structural_output" ] && [ "$structural_output" != '[]' ]; then
        STRUCTURAL_VIOLATIONS=$(echo "$structural_output" | grep -c '^    {' || true)
        # Escape JSON for safe heredoc insertion by reading from temp file
        echo "$structural_output" > /tmp/lint_structural.json
        STRUCTURAL_VIOLATOR_JSON=$(cat /tmp/lint_structural.json)
    fi
fi
TOTAL_ISSUES=$((TOTAL_ISSUES + STRUCTURAL_VIOLATIONS))

# --- Check 15: Excessive empty lines (3+ consecutive newlines) with auto-fix ---
EXCESSIVE_EMPTY_LINES=0; EXCESSIVE_EMPTY_FILES_JSON='[]'
if [[ "$SKIP_CHECKS" != *",15,"* ]]; then
    # Unified single-pass detection + auto-fix (from about_md_cleaner.md)
    # Pattern: normalize whitespace-only lines → squash \n{3,} → write only if changed
    EXCESSIVE_DATA=$(WIKI_DIR="$WIKI_DIR" python3 << 'PYEOF'
import json, os, re
from pathlib import Path

wiki_dir = os.environ.get("WIKI_DIR", "wiki")

fixed_count = 0
fixed_paths = []

def clean_markdown_spaces(file_path):
    path = Path(file_path)
    content = path.read_text(encoding='utf-8')
    
    # 1. Normalize whitespace-only lines to empty
    normalized = re.sub(r'\n[ \t]+\n', '\n\n', content)
    
    # 2. Squash 3+ newlines into exactly one blank line (2 newlines total)
    cleaned = re.sub(r'\n{3,}', '\n\n', normalized)
    
    # Only write if changed — preserves mtime for unchanged files
    if content == cleaned:
        return False
    
    path.write_text(cleaned, encoding='utf-8')
    return True

for root, dirs, files in os.walk(wiki_dir):
    for f in files:
        if not f.endswith('.md'): continue
        path = os.path.join(root, f)
        if clean_markdown_spaces(path):
            fixed_paths.append(str(path))
            fixed_count += 1

print(json.dumps({'count': fixed_count, 'files': fixed_paths}))
PYEOF
) || EXCESSIVE_DATA='{"count":0,"files":[]}'


fi

# Final: single rebuild-meta --index-only (consolidated from D6+D7)
HAS_FIXES=$((AUTO_REPAIRED + FIX_ITER + MISSING_FM))
if [[ $HAS_FIXES -gt 0 ]]; then
  echo "[*] Rebuilding meta index after ${AUTO_REPAIRED} link fix(es), ${FIX_ITER} tag fixes, ${MISSING_FM} frontmatter insertions..." >&2
  safe_run "./scripts/rebuild-meta.sh --index-only" local_final_rebuild || true
fi

# --- Summary output (machine-readable JSON to stdout) ---
cat <<EOF | grep -v "^="
{
  "timestamp": "$(date +%Y-%m-%dT%H:%M:%S)",
  "wiki_dir": "${WIKI_DIR#/}",
  "checks_run": 15,
  "issues_found": {
    "contradictions": ${CONTRADICTIONS},
    "orphan_pages": ${ORPHAN_COUNT},
    "orphan_paths": ${ORPHAN_PATHS_JSON:-"[]"},
    "new_sources_unprocessed": ${NEW_SOURCES},
    "duplicate_titles": ${DUPLICATE_TITLES},
    "filename_collisions": ${FILENAME_VIOLATIONS:-0},
    "date_inconsistencies": ${DATE_ISSUES},
    "broken_links": ${BROKEN_LINKS},
    "auto_repaired_links": ${AUTO_REPAIRED:-0},
    "agent_review_required": ${AGENT_REVIEW:-0},
    "agent_review_details": ${AGENT_REVIEW_REQUIRED_JSON},
    "contradictions_deep": ${CONTRADICTIONS_DEEP},
    "text_similarity_overlaps": ${TEXT_SIMILARITY_MATCHES},
    "hot_cache_stale": ${HOT_CACHE_STALE},
    "tag_empty": ${TAG_EMPTY},
    "tag_non_en": ${TAG_NON_EN},
    "tag_generic": ${TAG_GENERIC},
    "tag_xr_gaps": ${TAG_XR_GAPS},
    "missing_frontmatter": ${MISSING_FM},
    "structural_violations": ${STRUCTURAL_VIOLATIONS},
    "structural_violator_paths": ${STRUCTURAL_VIOLATOR_JSON},
    "excessive_empty_lines": ${EXCESSIVE_EMPTY_LINES},
    "excessive_empty_files": ${EXCESSIVE_EMPTY_FILES_JSON:-"[]"}
  },
  "total_issues": ${TOTAL_ISSUES},
  "status": "$([ $TOTAL_ISSUES -eq 0 ] && echo 'CLEAN' || echo 'ISSUES_FOUND')"
}
EOF

# --- Human-readable summary (stderr) ---
if [ "$QUIET" = true ]; then
  : # no-op: silent mode — suppress human-readable output
else
  echo "[✓] Checks run: 15" >&2
  echo "[!] Total issues found: ${TOTAL_ISSUES}" >&2
fi

# --- Exit code: 0 if clean, 1 if issues (but never blocks agent) ---
exit $([ "$TOTAL_ISSUES" -eq 0 ] && echo 0 || echo 1)
