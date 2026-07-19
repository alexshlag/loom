#!/usr/bin/env bash
# scripts/orphan-report.sh — Detect orphan pages and suggest high-confidence crosslinks
# Outputs: JSON { "orphans": [...], "suggestions": [...] }
# Usage: ./scripts/orphan-report.sh [--scan-all]
#   --scan-all (default) — scan entire wiki, return all orphans
#   --quiet             — suppress non-JSON stderr output
#
# Notes:
# - Only reports pages where H1 is not a valid wiki-relative path (e.g., "git troubleshooting")
# - Scores orphans using the same heuristic as unified-pass.sh (score >= 5 considered high-confidence)
# - SUGGESTIONS: Only pages with score >= 5 are included; agent must review before linking.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
WIKI_DIR="$PROJECT_ROOT/wiki"
ORPHANS_TMP="$PROJECT_ROOT/tracking/orphans.json.tmp"

# ─── Parse args ──────────────────────────────────────────────────────
SCAN_ALL=true
QUIET=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --scan-all) SCAN_ALL=true; shift ;;
        --quiet)  QUIET=true; shift ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# ─── Helper: score orphan (same heuristic as unified-pass.sh) ────────
# Returns 0 if orphan, 1 otherwise
score_orphan() {
    local path="$1"
    local content
    content=$(cat "$path" 2>/dev/null) || return 1

    # Strip frontmatter and get body
    local body
    body=$(echo "$content" | sed -n '/^---$/,$p' | tail -n +2 | sed '1{/^---$/d}' | tr '\n' ' ')

    # Remove wiki links, anchors, and headings
    body=$(echo "$body" | sed -E 's/\[.*?\]\([^)]*\)//g; s/\[.*?\]\[[^]]*\]//g; s/#[^#]*//g; s/\<[^>]*\>//g')
    body=$(echo "$body" | tr -s ' ')

    local score=0
    # +2 for each orphaned link (non-wiki pattern): (text)
    orphan_links=$(echo "$body" | grep -oE '\([^)]*\)' | wc -l | tr -d '[:space:]')
    ((score += 2 * orphan_links))
    # +1 for each heading that does NOT exist as a page
    while [[ "$body" =~ ^([^ \n#]+)[[:space:]]*# ]]; do
        local heading="${BASH_REMATCH[1]}"
        if [[ ! -f "$WIKI_DIR/$heading.md" ]] && [[ "$heading" != "Wiki" ]] && [[ "$heading" != "Timeline" ]]; then
            ((score += 1))
        fi
    done

    echo "$score"
}

# ─── Collect all orphan pages ───────────────────────────────────────
ORPHANS_JSON="[]"
if $SCAN_ALL; then
    ORPHANS_JSON="["
    FIRST=true

    for root in "$WIKI_DIR"/*/; do
        [[ -d "$root" ]] || continue

        for page in "$root"*.md; do
            [[ -f "$page" ]] || continue

            score=$(score_orphan "$page")
            if [[ "$score" -ge 1 ]]; then
                if $FIRST; then
                    FIRST=false
                else
                    ORPHANS_JSON+=","
                fi
                # Escape path for JSON
                escaped_path=$(echo "$page" | sed 's/\\/\\\\/g; s/"/\\"/g')
                ORPHANS_JSON+="{\"path\":\"$escaped_path\",\"score\":$score}"
            fi
        done
    done

    ORPHANS_JSON+="]"
fi

# ─── Generate suggestions (high-confidence only, score ≥ 5) ──────────
SUGGESTIONS_JSON="["
FIRST=true

for root in "$WIKI_DIR"/*/; do
    [[ -d "$root" ]] || continue

    for page in "$root"*.md; do
        [[ -f "$page" ]] || continue

        score=$(score_orphan "$page")
        if [[ "$score" -ge 5 ]]; then
            if $FIRST; then
                FIRST=false
            else
                SUGGESTIONS_JSON+=","
            fi
            escaped_path=$(echo "$page" | sed 's/\\/\\\\/g; s/"/\\"/g')
            SUGGESTIONS_JSON+="{\"path\":\"$escaped_path\",\"score\":$score}"
        fi
    done
done

SUGGESTIONS_JSON+="]"

# ─── Output JSON to temp file ───────────────────────────────────────
# Write full result as JSON (both orphans and suggestions)
cat > "$ORPHANS_TMP" << EOF
{
  "orphans": $ORPHANS_JSON,
  "suggestions": $SUGGESTIONS_JSON
}
EOF

# If not quiet, also print summary to stderr
if ! $QUIET; then
    echo "Orphans: $ORPHANS_JSON" >&2
    echo "Suggestions (score ≥5): $SUGGESTIONS_JSON" >&2
fi

# Return JSON object for machine consumption
cat "$ORPHANS_TMP"
