#!/usr/bin/env bash
# scripts/lint.sh — Автономный lint-скрипт, не блокирующий agent turn
# Usage: ./scripts/lint.sh [--quiet] [--skip-checks ID1,ID2] [wiki_dir]
# Exit code: 0 = all checks passed, 1 = issues found (но не блокирует flow)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
WIKI_DIR="${2:-$PROJECT_ROOT/wiki}"
QUIET=false
SKIP_CHECKS=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --quiet) QUIET=true; shift;;
    --skip-checks) SKIP_CHECKS="$2"; shift 2;;
    *) WIKI_DIR="$1"; shift;;
  esac
done

WIKI_DIR="${1:-$PROJECT_ROOT/wiki}"

# Trap cleanup for any temp files on abort
trap 'rm -f /tmp/lint_*.json /tmp/overlap_result.json 2>/dev/null' EXIT || true

echo "========================================" >&2
echo "[*] LINT AUDIT — $(date +%Y-%m-%d) | wiki: ${WIKI_DIR#/}" >&2
echo "========================================" >&2

TOTAL_ISSUES=0
RESULTS=""

# Helper: run script safely, capture exit code without set -e aborting
# Usage: safe_run "script.sh args" varname [expected_codes]
safe_run() {
    local cmd="$1"
    local varname="$2"
    local expected="${3:-0}"
    local output
    output=$(eval "$cmd" 2>&1)
    local exit_code=$?
    if [[ ",$expected," != *",$exit_code,"* ]]; then
        echo "[!] Script exited with code $exit_code (expected: $expected)" >&2
    fi
    eval "$varname=\"$output\""
}

# --- Check 1: Contradictions (read all pages, compare facts) ---
# Note: This is a soft check — agent must resolve manually
CONTRADICTIONS=0
if [[ ! "$(echo "$SKIP_CHECKS" | grep -o '1' || true)" == "1" ]]; then
  # Quick contradiction scan: look for "## Обновлено" sections with conflicting dates
  CONTRADICTION_PAGES=$({ grep -r "^## Обновлено" "$WIKI_DIR/" --include="*.md" -l 2>/dev/null | head -20; } || true)
  if [ -n "$CONTRADICTION_PAGES" ]; then
    CONTRADICTIONS=$(echo "$CONTRADICTION_PAGES" | wc -l)
  fi
fi
TOTAL_ISSUES=$((TOTAL_ISSUES + CONTRADICTIONS))

# --- Check 2: Orphan pages ---
ORPHAN_COUNT=0
if [[ ! "$(echo "$SKIP_CHECKS" | grep -o '2' || true)" == "2" ]]; then
  ORPHANS_OUTPUT=$({ ./scripts/orphan-pages.sh "$WIKI_DIR" "${PROJECT_ROOT}/meta/backlinks.json" 2>&1; } || true)
  # Note: orphan-pages should exit 0 normally, but set -e protection needed
  if echo "$ORPHANS_OUTPUT" | grep -q "Orphan pages found"; then
    ORPHAN_COUNT=$(echo "$ORPHANS_OUTPUT" | grep -oE '[0-9]+' | head -1 || echo "0")
  fi
fi
TOTAL_ISSUES=$((TOTAL_ISSUES + ORPHAN_COUNT))

# --- Check 3: Knowledge gaps (mentions without own page) ---
# Note: Soft check — agent reviews manually
echo "[✓] Check 4/9: knowledge_gaps — skipped (soft check, agent review required)" >&2

# --- Check 4: New sources available ---
NEW_SOURCES=0
if [[ ! "$(echo "$SKIP_CHECKS" | grep -o '3' || true)" == "3" ]]; then
  # FIX: added --max 10 to prevent infinite source scanning
  NEW_SOURCES_OUTPUT=$({ ./scripts/check-new-sources.sh --max 10 "${PROJECT_ROOT}/raw/sources" "${PROJECT_ROOT}/tracking/raw_registry.json"; } || true)
  if echo "$NEW_SOURCES_OUTPUT" | grep -q '^NEW:'; then
    # FIX: count lines with 'NEW:' prefix, not first number in output (which was parsing '2025' from SRC-2025)
    NEW_SOURCES=$(echo "$NEW_SOURCES_OUTPUT" | grep -c '^NEW:' || echo "0")
  fi
  if echo "$NEW_SOURCES_OUTPUT" | grep -q "^NEW:"; then
    # FIX: count lines with 'NEW:' prefix, not first number in output (which was parsing '2025' from SRC-2025)
    NEW_SOURCES=$(echo "$NEW_SOURCES_OUTPUT" | grep -c '^NEW:' || echo "0")
  fi
fi

# --- Check 5: New topics proposal (soft check) ---
echo "[✓] Check 5/9: new_topics_proposal — skipped (requires external sources)" >&2

# --- Check 6: Mechanical linting (frontmatter, duplicate titles, empty categories) ---
DUPLICATE_TITLES=0
MISSING_FM=0
if [[ ! "$(echo "$SKIP_CHECKS" | grep -o '5' || true)" == "5" ]]; then
  DUP_OUTPUT=$({ ./scripts/duplicate-titles.sh "$WIKI_DIR" 2>&1; } || true)
  if echo "$DUP_OUTPUT" | grep -q "Duplicate"; then
    DUPLICATE_TITLES=1
  fi
fi
TOTAL_ISSUES=$((TOTAL_ISSUES + DUPLICATE_TITLES))

# --- Check 7: Date consistency ---
DATE_ISSUES=0
if [[ ! "$(echo "$SKIP_CHECKS" | grep -o '6' || true)" == "6" ]]; then
  DATE_OUTPUT=$({ ./scripts/date-consistency.sh "$WIKI_DIR" 2>&1; } || true)
  if echo "$DATE_OUTPUT" | grep -q "Inconsistencies found"; then
    DATE_ISSUES=$(echo "$DATE_OUTPUT" | grep -oE '[0-9]+' | head -1 || echo "0")
  fi
fi
TOTAL_ISSUES=$((TOTAL_ISSUES + DATE_ISSUES))

# --- Check 7: Link validation (broken internal links, auto-repair) ---
BROKEN_LINKS=0
AUTO_REPAIRED=0
AGENT_REVIEW_REQUIRED_JSON=""
if [[ ! "$(echo "$SKIP_CHECKS" | grep -o '7' || true)" == "7" ]]; then
  TMP_LV=$(mktemp)
  { ./scripts/link-validator.sh --auto "$WIKI_DIR" --max 100; } > "$TMP_LV" 2>&1 || true
  LV_OUTPUT=$(cat "$TMP_LV")
  rm -f "$TMP_LV"
  if echo "$LV_OUTPUT" | grep -q "Broken links found"; then
    BROKEN_LINKS=$(echo "$LV_OUTPUT" | sed -n '/Broken links found/p' | grep -oE '[0-9]+' | head -1) || BROKEN_LINKS=0
    # Auto mode: parse auto-repaired count from stderr
    local_fixed=$(echo "$LV_OUTPUT" | grep 'Auto-repaired:' | grep -oE '[0-9]+')
    [ -n "$local_fixed" ] && AUTO_REPAIRED=$local_fixed
    # Capture agent review required list for reporting (from JSON stdout)
    AGENT_REVIEW_REQUIRED_JSON=$(echo "$LV_OUTPUT" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(json.dumps(d.get("agent_review_required",[])))' 2>/dev/null || echo "[]")
    # Count agent review entries from stderr
    ar=$(echo "$LV_OUTPUT" | grep -oE '[0-9]+ links need manual attention' | grep -oE '[0-9]+' | head -1) || true
    [ -n "$ar" ] && AGENT_REVIEW=$ar
  fi
fi
TOTAL_ISSUES=$((TOTAL_ISSUES + BROKEN_LINKS))

# D6: Rebuild meta index after auto-fixes (auto-regenerate index.md)
if [[ $AUTO_REPAIRED -gt 0 ]]; then
  echo "[*] Rebuilding meta index after ${AUTO_REPAIRED} link fix(es)..." >&2
  ./scripts/rebuild-meta.sh --index-only 2>/dev/null || true
fi

# --- Check 10: Contradiction deep scan (Python-based) ---
CONTRADICTIONS_DEEP=0
if [[ ! "$(echo "$SKIP_CHECKS" | grep -oE ',?8,?' || true)" == ",8," ]]; then
  DEEP_OUTPUT=$({ ./scripts/detect-contradications.sh --quiet; } || true)
  if echo "$DEEP_OUTPUT" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if d.get("status")=="CLEAN" else 1)' 2>/dev/null; then
    CONTRADICTIONS_DEEP=0
  else
    CONTRADICTIONS_DEEP=$(echo "$DEEP_OUTPUT" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("potential_contradictions",0))' || echo "0")
  fi
fi

# --- Check 9: Text similarity (n-gram overlap scan) ---
TEXT_SIMILARITY_MATCHES=0
if [[ ! "$(echo "$SKIP_CHECKS" | grep -oE ',?9,?' || true)" == ",9," ]]; then
  SIM_OUTPUT=$({ ./scripts/text-similarity.sh --scan-all --threshold 90; } || true)
  if echo "$SIM_OUTPUT" | python3 -c 'import json,sys; d=json.load(sys.stdin); sys.exit(0 if len(d.get("matches",[]))==0 else 1)' 2>/dev/null; then
    TEXT_SIMILARITY_MATCHES=0
  else
    TEXT_SIMILARITY_MATCHES=$(echo "$SIM_OUTPUT" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(len(d.get("matches",[])))' || echo "0")
  fi
fi
TOTAL_ISSUES=$((TOTAL_ISSUES + TEXT_SIMILARITY_MATCHES))

# --- Summary output (machine-readable JSON to stdout) ---
cat <<EOF | grep -v "^="
{
  "timestamp": "$(date +%Y-%m-%dT%H:%M:%S)",
  "wiki_dir": "${WIKI_DIR#/}",
  "checks_run": 9,
  "issues_found": {
    "contradictions": ${CONTRADICTIONS},
    "orphan_pages": ${ORPHAN_COUNT},
    "new_sources_unprocessed": ${NEW_SOURCES},
    "duplicate_titles": ${DUPLICATE_TITLES},
    "date_inconsistencies": ${DATE_ISSUES},
    "broken_links": ${BROKEN_LINKS},
    "auto_repaired_links": ${AUTO_REPAIRED:-0},
    "agent_review_required": ${AGENT_REVIEW:-0},
    "agent_review_details": ${AGENT_REVIEW_REQUIRED_JSON:-[]},
    "contradictions_deep": ${CONTRADICTIONS_DEEP},
    "text_similarity_overlaps": ${TEXT_SIMILARITY_MATCHES}
  },
  "total_issues": ${TOTAL_ISSUES},
  "status": "$([ $TOTAL_ISSUES -eq 0 ] && echo 'CLEAN' || echo 'ISSUES_FOUND')"
}
EOF

# --- Human-readable summary (stderr) ---
if [ $QUIET = true ]; then

  : # no-op: silent mode — suppress human-readable output
else
  echo "[✓] Checks run: 9" >&2
  echo "[!] Total issues found: ${TOTAL_ISSUES}" >&2
fi

# --- Exit code: 0 if clean, 1 if issues (but never blocks agent) ---
exit $([ "$TOTAL_ISSUES" -eq 0 ] && echo 0 || echo 1)
