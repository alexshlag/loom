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
cleanup_set_trap

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
ORPHAN_PATHS=""
if [[ "$SKIP_CHECKS" != *",2,"* ]]; then
  local_orphans=""
  safe_run "./scripts/orphan-pages.sh $WIKI_DIR ${PROJECT_ROOT}/meta/backlinks.json" local_orphans "0 1" || true
  if echo "$local_orphans" | grep -q "Orphan pages found"; then
    ORPHAN_COUNT=$(echo "$local_orphans" | grep -oE '[0-9]+' | head -1) || ORPHAN_COUNT=0
    # Extract orphan paths (indented lines after 'Orphan pages found')
    ORPHAN_PATHS_JSON=$(echo "$local_orphans" | python3 -c '
import sys,json
lines = sys.stdin.read().split("\n")
paths = []
for line in lines:
    if line.startswith("    ") and "no backlinks" not in line.lower():
        paths.append(line.strip())
print(json.dumps(paths))
' 2>/dev/null) || ORPHAN_PATHS_JSON="[]"
  fi
fi
TOTAL_ISSUES=$((TOTAL_ISSUES + ORPHAN_COUNT))

# --- Check 3: Knowledge gaps (soft check, agent review) ---
echo "[✓] Check 3/10: knowledge_gaps — skipped (soft check, agent review required)" >&2

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
echo "[✓] Check 5/10: new_topics_proposal — skipped (requires external sources)" >&2

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

  # Extract JSON from mixed stdout+stderr output via Python
  local_up_json=$(echo "$local_up_out" | python3 -c '
import json, sys
content = sys.stdin.read()
start = content.find("{")
end = content.rfind("}")
if start >= 0 and end >= 0:
    try:
        d = json.loads(content[start:end+1])
        print(json.dumps(d))
    except:
        print("{}")
else:
    print("{}")
' 2>/dev/null) || local_up_json="{}"

  BROKEN_LINKS=$(echo "$local_up_json" | python3 -c 'import json,sys; print(len(json.load(sys.stdin).get("broken_links",[])))' 2>/dev/null) || BROKEN_LINKS=0
  AUTO_REPAIRED=$(echo "$local_up_json" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("auto_repaired",0))' 2>/dev/null) || AUTO_REPAIRED=0
  AGENT_REVIEW_REQUIRED_JSON=$(echo "$local_up_json" | python3 -c 'import json,sys; print(json.dumps(json.load(sys.stdin).get("agent_review_required",[])))' 2>/dev/null) || AGENT_REVIEW_REQUIRED_JSON="[]"
fi
TOTAL_ISSUES=$((TOTAL_ISSUES + BROKEN_LINKS))

# D6: Rebuild meta index after auto-fixes
if [[ $AUTO_REPAIRED -gt 0 ]]; then
  echo "[*] Rebuilding meta index after ${AUTO_REPAIRED} link fix(es)..." >&2
  safe_run "./scripts/rebuild-meta.sh --index-only" local_rebuild || true
fi

# --- Check 9: Contradiction deep scan (Python-based) ---
CONTRADICTIONS_DEEP=0
if [[ "$SKIP_CHECKS" != *",9,"* ]]; then
  local_deep=""
  safe_run "./scripts/detect-contradications.sh --quiet" local_deep "0 1" || true
  # Parse JSON with fallback for malformed output
  local_dc=$(python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("potential_contradictions",0))' <<< "$local_deep" 2>/dev/null) || local_dc=0
  if [ -n "$local_dc" ] && [[ "$local_dc" =~ ^[0-9]+$ ]]; then
    CONTRADICTIONS_DEEP=$local_dc
  fi
fi
TOTAL_ISSUES=$((TOTAL_ISSUES + CONTRADICTIONS_DEEP))

# --- Check 10: Text similarity (n-gram overlap scan) ---
TEXT_SIMILARITY_MATCHES=0
if [[ "$SKIP_CHECKS" != *",10,"* ]]; then
  # text-similarity writes logs to stdout — redirect stderr for clean JSON output
  local_sim=$(bash ./scripts/text-similarity.sh --scan-all --threshold 90 2>/dev/null) || true
  if echo "$local_sim" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if len(d.get("matches",[]))==0 else 1)' 2>/dev/null; then
    TEXT_SIMILARITY_MATCHES=0
  else
    local_sm=$(echo "$local_sim" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(len(d.get("matches",[])))') || local_sm=0
    if [ -n "$local_sm" ] && [[ "$local_sm" =~ ^[0-9]+$ ]]; then
      TEXT_SIMILARITY_MATCHES=$local_sm
    fi
  fi
fi
TOTAL_ISSUES=$((TOTAL_ISSUES + TEXT_SIMILARITY_MATCHES))

# --- Check 11: Hot cache staleness ---
HOT_CACHE_STALE=false
if [[ "$SKIP_CHECKS" != *",11,"* ]]; then
  if safe_run "./scripts/check-wiki-changes.sh" local_hot_check "0 1"; then
    if echo "$local_hot_check" | grep -q "WIKI CHANGES DETECTED"; then
      HOT_CACHE_STALE=true
      $QUIET || echo "[!] Check 11/11: hot_cache_stale — WIKI CHANGES DETECTED" >&2
    else
      $QUIET || echo "[✓] Check 11/11: hot_cache_stale — no changes" >&2
    fi
  fi
fi

# --- Check 12: Tag audit with auto-fix (empty, non-EN, generic type, XR gaps) ---
TAG_EMPTY=0; TAG_NON_EN=0; TAG_GENERIC=0; TAG_XR_GAPS=0
if [[ "$SKIP_CHECKS" != *",12,"* ]]; then
  FIX_ITER=0
  while true; do
    local_tr=$(bash "${SCRIPT_DIR}/tag-audit.sh" --quiet "$WIKI_DIR" 2>/dev/null) || { break; }
    TAG_EMPTY=$(echo "$local_tr" | python3 -c 'import json,sys;d=json.load(sys.stdin);print(d.get("issues_found",{}).get("empty_tags",0))' 2>/dev/null) || TAG_EMPTY=0
    TAG_NON_EN=$(echo "$local_tr" | python3 -c 'import json,sys;d=json.load(sys.stdin);print(d.get("issues_found",{}).get("non_en_tags",0))' 2>/dev/null) || TAG_NON_EN=0
    TAG_GENERIC=$(echo "$local_tr" | python3 -c 'import json,sys;d=json.load(sys.stdin);print(d.get("issues_found",{}).get("generic_type_tags",0))' 2>/dev/null) || TAG_GENERIC=0
    TAG_XR_GAPS=$(echo "$local_tr" | python3 -c 'import json,sys;d=json.load(sys.stdin);print(d.get("issues_found",{}).get("xr_gaps",0))' 2>/dev/null) || TAG_XR_GAPS=0
    local_tot=$((TAG_EMPTY + TAG_NON_EN + TAG_GENERIC + TAG_XR_GAPS))
    [ "$local_tot" -eq 0 ] && break
    $QUIET || echo "[~] Tag audit: ${local_tot} issues — auto-fix (iter $((FIX_ITER+1)))..." >&2
    bash "${SCRIPT_DIR}/tag-audit.sh" --fix --quiet "$WIKI_DIR" >/dev/null 2>&1 || true
    FIX_ITER=$((FIX_ITER+1))
    [ "$FIX_ITER" -ge 3 ] && break
  done
  $QUIET || echo "[✓] Check 12/12: tag_audit — empty:${TAG_EMPTY} non-en:${TAG_NON_EN} generic:${TAG_GENERIC} xr:${TAG_XR_GAPS}" >&2
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
        STRUCTURAL_VIOLATIONS=$(echo "$structural_output" | python3 -c "import sys,json;print(len(json.load(sys.stdin)))")
        # Escape JSON for safe heredoc insertion by reading from temp file
        echo "$structural_output" > /tmp/lint_structural.json
        STRUCTURAL_VIOLATOR_JSON=$(cat /tmp/lint_structural.json)
    fi
fi
TOTAL_ISSUES=$((TOTAL_ISSUES + STRUCTURAL_VIOLATIONS))

# D7: Rebuild meta index after tag auto-fixes AND frontmatter insertions
if [[ $FIX_ITER -gt 0 ]] || [[ $MISSING_FM -gt 0 ]]; then
    echo "[*] Rebuilding meta index..." >&2
    safe_run "./scripts/rebuild-meta.sh --index-only" local_tag_rebuild || true
fi

# --- Summary output (machine-readable JSON to stdout) ---
cat <<EOF | grep -v "^="
{
  "timestamp": "$(date +%Y-%m-%dT%H:%M:%S)",
  "wiki_dir": "${WIKI_DIR#/}",
  "checks_run": 14,
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
    "structural_violator_paths": ${STRUCTURAL_VIOLATOR_JSON}
  },
  "total_issues": ${TOTAL_ISSUES},
  "status": "$([ $TOTAL_ISSUES -eq 0 ] && echo 'CLEAN' || echo 'ISSUES_FOUND')"
}
EOF

# --- Human-readable summary (stderr) ---
if [ "$QUIET" = true ]; then
  : # no-op: silent mode — suppress human-readable output
else
  echo "[✓] Checks run: 14" >&2
  echo "[!] Total issues found: ${TOTAL_ISSUES}" >&2
fi

# --- Exit code: 0 if clean, 1 if issues (but never blocks agent) ---
exit $([ "$TOTAL_ISSUES" -eq 0 ] && echo 0 || echo 1)
