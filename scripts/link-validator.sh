#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
WIKI_DIR="${2:-$PROJECT_ROOT/wiki}"
DEFAULT_MAX=100
MODE=""
PATTERN=""
MAX_MATCHES=$DEFAULT_MAX
BROKEN_COUNT=0

# Parse arguments  
if [[ "${1:-}" == "--full" ]]; then
  MODE="full"; shift
  while [[ $# -gt 0 ]]; do
    case "$1" in --max) MAX_MATCHES="${2:-$DEFAULT_MAX}"; shift 2;; *) shift;; esac
  done
elif [[ -n "${1:-}" ]]; then
  MODE="pattern"; PATTERN="$1"; shift
  if [[ $# -ge 3 ]]; then MAX_MATCHES="$3"; fi
else
  echo "Usage:" >&2
  echo "  $0 --full [wiki_dir] [--max N]" >&2
  echo "  $0 <pattern> [wiki_dir] [max_matches]" >&2
  exit 2
fi

TMP_RESULTS=$(mktemp)
echo -n "" > "$TMP_RESULTS"
trap 'rm -f "$TMP_RESULTS"' EXIT

check_file() {
  local file="$1"
  local linenum=0
  
  while IFS= read -r line || [[ -n "$line" ]]; do
    linenum=$((linenum + 1))
    
    # Check if this line has markdown links before processing
    if echo "$line" | grep -qE '\[[^]]+\]\([^)]+\)'; then
      while IFS= read -r match; do
        local target_path=$(echo "$match" | grep -oP '(?<=\]\()[^)]+(?=\))' || true)
        
        # Skip external URLs, mailto, empty paths
        case "$target_path" in https://*|http://*|mailto:*|raw/*) continue ;; esac
        # Skip anchor-only targets (issues.md#...) — validate base path without hash
        local base_target=$(echo "$target_path" | sed 's/#.*//')
        if [[ -z "$base_target" ]]; then continue; fi
        
        local full_target="$WIKI_DIR/$base_target"
        if [[ ! -f "$full_target" ]]; then
          BROKEN_COUNT=$((BROKEN_COUNT + 1))
          
          # Escape for JSON
          local safe_file=$(echo "$file" | sed 's/\\/\\\\/g; s/"/\\"/g')
          local safe_match=$(echo "$match" | sed 's/\\/\\\\/g; s/"/\\"/g')
          
          # Comma separator
          if [[ $BROKEN_COUNT -gt 1 ]]; then
            printf ',' >> "$TMP_RESULTS"
          fi
          printf '{"file":"%s","line":%d,"link":"%s","target_path":"%s"}' \
            "$safe_file" "$linenum" "$safe_match" "$target_path" >> "$TMP_RESULTS"
        fi
      done < <(echo "$line" | grep -oE '\[[^]]+\]\([^)]+\)')
    fi
  done < "$file"
}

# --- Main execution ---

if [[ "$MODE" == "full" ]]; then
  echo "[*] Scanning all wiki files for broken internal links (max: $MAX_MATCHES)" >&2
  
  while IFS= read -r file; do
    check_file "$file"
  done < <(find "$WIKI_DIR" -name "*.md" -type f 2>/dev/null | head -500)

elif [[ "$MODE" == "pattern" ]]; then
  echo "[*] Scanning wiki for references to: $PATTERN (max: $MAX_MATCHES)" >&2
  
  local_matches=$(grep -rn "$PATTERN" "$WIKI_DIR/" --include="*.md" -m "$MAX_MATCHES" 2>/dev/null || true)
  
  if [[ -n "$local_matches" ]]; then
    while IFS= read -r match_line; do
      local_filepath="${match_line%%:*}"
      local_rest="${match_line#*:}"
      local_linenum="${local_rest%%:*}"
      local_content="${local_rest#*:}"
      
      if echo "$local_content" | grep -qE '\[[^]]+\]\([^)]*\)'; then
        while IFS= read -r match; do
          local_target=$(echo "$match" | sed 's/^[^(]*(\([^)]*\)).*/\1/')
          
          case "$local_target" in https://*|http://*|mailto:*|"") continue ;; esac
          
          local_full="$WIKI_DIR/$local_target"
          if [[ ! -f "$local_full" ]]; then
            BROKEN_COUNT=$((BROKEN_COUNT + 1))
            
            local safe_filepath=$(echo "$local_filepath" | sed 's/\\/\\\\/g; s/"/\\"/g')
            local safe_match=$(echo "$match" | sed 's/\\/\\\\/g; s/"/\\"/g')
            
            if [[ $BROKEN_COUNT -gt 1 ]]; then
              printf ',' >> "$TMP_RESULTS"
            fi
            printf '{"file":"%s","line":%d,"link":"%s","target_path":"%s"}' \
              "$safe_filepath" "$local_linenum" "$safe_match" "$local_target" >> "$TMP_RESULTS"
          fi
        done < <(echo "$local_content" | grep -oE '\[[^]]+\]\([^)]+\)')
      fi
    done <<< "$local_matches"
  fi
fi

# --- Output results ---

if [[ $BROKEN_COUNT -gt 0 ]]; then
  RESULT_JSON="[$(cat "$TMP_RESULTS")]"
  
  echo "[!] Broken links found ($BROKEN_COUNT):" >&2
  
  # Parse and print broken links to stderr
  while IFS= read -r jline; do
    local_ef=$(echo "$jline" | sed 's/.*"file":"\([^"]*\)".*/\1/')
    local_el=$(echo "$jline" | sed 's/.*"link":"\([^"]*\)".*/\1/')
    echo "    $local_ef -> $local_el" >&2
  done < <(grep -oE '"file":[^}]*}' "$TMP_RESULTS")
  
  echo "$RESULT_JSON"
  exit 1
fi

echo "[✓] All internal links are valid" >&2
exit 0
