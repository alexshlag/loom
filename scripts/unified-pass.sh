#!/usr/bin/env bash
# unified-pass.sh — Single walk, three analyses
# Architecture: orchestator, not monolithic merge
#   Shared walk: one find with unified exclude list
#   Dispatch: results → 3 consumer functions
#   Consumers: validate_links, collect_metadata, discover_crosslinks
#
# Usage:
#   ./scripts/unified-pass.sh [--full] [--skip-links|--skip-meta|--skip-crosslinks] [--quiet]
#
# Output (stdout): JSON with results from all 3 consumers
# Exit: 0 = all OK, 1 = any consumer found issues

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
WIKI_DIR="$PROJECT_ROOT/wiki"

# --- Flags ---
FULL_REBUILD=false
SKIP_LINKS=false
SKIP_META=false
SKIP_CROSSLINKS=false
QUIET=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --full) FULL_REBUILD=true; shift;;
    --skip-links) SKIP_LINKS=true; shift;;
    --skip-meta) SKIP_META=true; shift;;
    --skip-crosslinks) SKIP_CROSSLINKS=true; shift;;
    --quiet|-q) QUIET=true; shift;;
    *) echo "[!] Unknown flag: $1" >&2; exit 1;;
  esac
done

# --- System file exclusion (единый список) ---
# Excluded from metadata and crosslinks, but NOT from link validation
WIKI_SYSTEM_FILES=(
  "log.md" "issues.md" "timeline.md" "overview.md"
  "snapshot.md" "index.md" "GIT-TROUBLESHOOTING.md"
  "GIT-WORKFLOW.md" "Home_Manager.md"
)
ROOT_SYSTEM_FILES=("AGENTS.md" "context.md" "PLAN.md" "hot.md")

is_wiki_system_file() {
  local f="$1"
  for sf in "${WIKI_SYSTEM_FILES[@]}"; do
    [[ "$f" == *"$sf" ]] && return 0
  done
  for sf in "${ROOT_SYSTEM_FILES[@]}"; do
    [[ "$f" == *"$sf" ]] && return 0
  done
  return 1
}

# --- Temp files ---
FILE_LIST=$(mktemp)
LINK_RESULTS=$(mktemp)
CROSSLINK_RESULTS=$(mktemp)
trap 'rm -f "$FILE_LIST" "$LINK_RESULTS" "$CROSSLINK_RESULTS"' EXIT

OVERALL_EXIT=0

# ============================================================
# SHARED WALK
# ============================================================
$QUIET || echo "[*] unified-pass: walking wiki..." >&2

find "$WIKI_DIR" -name "*.md" -type f ! -path "*/meta/*" ! -path "*/raw/*" 2>/dev/null | sort > "$FILE_LIST"

TOTAL_FILES=$(wc -l < "$FILE_LIST" | tr -d ' ')
$QUIET || echo "[*] unified-pass: $TOTAL_FILES files found" >&2

# ============================================================
# CONSUMER 1: validate_links
# ============================================================
if [[ "$SKIP_LINKS" == "false" ]]; then
  $QUIET || echo "[*] Consumer 1: validate_links..." >&2

  # stdout = JSON (captured), stderr = human-readable (or quiet)
  if $QUIET; then
    "$SCRIPT_DIR/link-validator.sh" --batch - < "$FILE_LIST" > "$LINK_RESULTS" 2>/dev/null || true
  else
    "$SCRIPT_DIR/link-validator.sh" --batch - < "$FILE_LIST" > "$LINK_RESULTS" || true
  fi

  if [[ -s "$LINK_RESULTS" ]]; then
    BROKEN_COUNT=$(grep -o '"target_path"' "$LINK_RESULTS" | wc -l)
    $QUIET || echo "[!] Consumer 1: $BROKEN_COUNT broken links found" >&2
    OVERALL_EXIT=1
  else
    $QUIET || echo "[✓] Consumer 1: all links valid" >&2
  fi
else
  $QUIET || echo "[-] Consumer 1: skipped" >&2
fi

# ============================================================
# CONSUMER 2: collect_metadata
# ============================================================
if [[ "$SKIP_META" == "false" ]]; then
  $QUIET || echo "[*] Consumer 2: collect_metadata..." >&2

  if [[ "$FULL_REBUILD" == "true" ]]; then
    rm -f "$WIKI_DIR/.meta_update_timestamp" 2>/dev/null || true
  fi

  if $QUIET; then
    "$SCRIPT_DIR/rebuild-meta.sh" >/dev/null 2>&1 || true
  else
    "$SCRIPT_DIR/rebuild-meta.sh" || true
  fi
else
  $QUIET || echo "[-] Consumer 2: skipped" >&2
fi

# ============================================================
# CONSUMER 3: discover_crosslinks
# ============================================================
if [[ "$SKIP_CROSSLINKS" == "false" ]]; then
  $QUIET || echo "[*] Consumer 3: discover_crosslinks..." >&2

  ALL_CROSSLINKS=0
  while IFS= read -r page; do
    [[ -z "$page" ]] && continue
    REL_PATH="${page#$WIKI_DIR/}"
    is_wiki_system_file "$REL_PATH" && continue

    RESULT=$("$SCRIPT_DIR/auto-crosslink.sh" --file-list "$FILE_LIST" --max-results 3 --min-score 3 "$page" 2>/dev/null || true)

    if [[ -n "$RESULT" && "$RESULT" != "[]" ]]; then
      ALL_CROSSLINKS=$((ALL_CROSSLINKS + 1))
      echo "$RESULT" >> "$CROSSLINK_RESULTS"
    fi
  done < "$FILE_LIST"

  if [[ $ALL_CROSSLINKS -gt 0 ]]; then
    $QUIET || echo "[*] Consumer 3: $ALL_CROSSLINKS pages have crosslink candidates" >&2
  else
    $QUIET || echo "[*] Consumer 3: no new crosslink candidates" >&2
  fi
else
  $QUIET || echo "[-] Consumer 3: skipped" >&2
fi

# ============================================================
# OUTPUT (stdout = JSON, stderr = human-readable)
# ============================================================
LINKS_JSON="[]"
if [[ -s "$LINK_RESULTS" ]]; then
  LINKS_JSON=$(cat "$LINK_RESULTS")
fi

CROSSLINKS_JSON="[]"
if [[ -s "$CROSSLINK_RESULTS" ]]; then
  # Merge individual JSON arrays into a single array of objects
  CROSSLINKS_JSON=$(awk '
    BEGIN { printf "["; first=1 }
    {
      # Remove surrounding [ and ]
      gsub(/^\[/, "");
      gsub(/\]$/, "");
      # Split by }{ and print each object
      printf "%s%s", (first ? "" : ","), $0
      first=0
    }
    END { print "]" }
  ' "$CROSSLINK_RESULTS")
fi

cat << EOF
{
  "files_scanned": $TOTAL_FILES,
  "broken_links": $LINKS_JSON,
  "crosslink_candidates": $CROSSLINKS_JSON
}
EOF

exit $OVERALL_EXIT
