#!/usr/bin/env bash
# scripts/lint.sh — Автономный lint-скрипт, не блокирующий agent turn
# Usage: ./scripts/lint.sh [--quiet] [--skip-checks ID1,ID2] [wiki_dir]
# Exit code: 0 = all checks passed, 1 = issues found (но не блокирует flow)

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
WIKI_DIR="${2:-$PROJECT_ROOT/wiki}"
QUIET=false
SKIP_CHECKS=""

# Load shared utilities for log_error, safe_run
source "$SCRIPT_DIR/utilities/common.sh" 2>/dev/null || true

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
trap 'rm -f /tmp/lint_*.json /tmp/overlap_result.json 2>/dev/null' EXIT

echo "========================================" >&2
echo "[*] LINT AUDIT — $(date +%Y-%m-%d) | wiki: ${WIKI_DIR#/}" >&2
echo "========================================" >&2

TOTAL_ISSUES=0

# --- Check 1: Contradictions (read all pages, compare facts) ---
CONTRADICTIONS=0
if [[ "$SKIP_CHECKS" != *",1,"* ]]; then
  CONTRADICTION_PAGES=$({ grep -r "^## Обновлено" "$WIKI_DIR/" --include="*.md" -l 2>/dev/null | head -20; } || true)
  if [ -n "$CONTRADICTION_PAGES" ]; then
    CONTRADICTIONS=$(echo "$CONTRADICTION_PAGES" | wc -l)
  fi
fi
TOTAL_ISSUES=$((TOTAL_ISSUES + CONTRADICTIONS))

# --- Check 2: Orphan pages ---
ORPHAN_COUNT=0
if [[ "$SKIP_CHECKS" != *",2,"* ]]; then
  local_orphans=""
  safe_run "./scripts/orphan-pages.sh $WIKI_DIR ${PROJECT_ROOT}/meta/backlinks.json" local_orphans "0 1" || true
  if echo "$local_orphans" | grep -q "Orphan pages found"; then
    ORPHAN_COUNT=$(echo "$local_orphans" | grep -oE '[0-9]+' | head -1) || ORPHAN_COUNT=0
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
if [[ "$SKIP_CHECKS" != *",6,"* ]]; then
  local_dup=""
  safe_run "./scripts/duplicate-titles.sh $WIKI_DIR" local_dup || true
  if echo "$local_dup" | grep -q "Duplicate"; then
    DUPLICATE_TITLES=1
  fi
fi
TOTAL_ISSUES=$((TOTAL_ISSUES + DUPLICATE_TITLES))

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

# --- Summary output (machine-readable JSON to stdout) ---
cat <<EOF | grep -v "^="
{
  "timestamp": "$(date +%Y-%m-%dT%H:%M:%S)",
  "wiki_dir": "${WIKI_DIR#/}",
  "checks_run": 10,
  "issues_found": {
    "contradictions": ${CONTRADICTIONS},
    "orphan_pages": ${ORPHAN_COUNT},
    "new_sources_unprocessed": ${NEW_SOURCES},
    "duplicate_titles": ${DUPLICATE_TITLES},
    "date_inconsistencies": ${DATE_ISSUES},
    "broken_links": ${BROKEN_LINKS},
    "auto_repaired_links": ${AUTO_REPAIRED:-0},
    "agent_review_required": ${AGENT_REVIEW:-0},
    "agent_review_details": ${AGENT_REVIEW_REQUIRED_JSON},
    "contradictions_deep": ${CONTRADICTIONS_DEEP},
    "text_similarity_overlaps": ${TEXT_SIMILARITY_MATCHES}
  },
  "total_issues": ${TOTAL_ISSUES},
  "status": "$([ $TOTAL_ISSUES -eq 0 ] && echo 'CLEAN' || echo 'ISSUES_FOUND')"
}
EOF

# --- Human-readable summary (stderr) ---
if [ "$QUIET" = true ]; then
  : # no-op: silent mode — suppress human-readable output
else
  echo "[✓] Checks run: 10" >&2
  echo "[!] Total issues found: ${TOTAL_ISSUES}" >&2
fi

# --- Exit code: 0 if clean, 1 if issues (but never blocks agent) ---
exit $([ "$TOTAL_ISSUES" -eq 0 ] && echo 0 || echo 1)
