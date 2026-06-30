#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/.."
WIKI_DIR="$PROJECT_ROOT/wiki"
DEFAULT_MAX=100
MODE=""
PATTERN=""
MAX_MATCHES=$DEFAULT_MAX
BROKEN_COUNT=0
AUTO_MODE=false

# Parse arguments — flexible order: flags can come before/after wiki_dir
# Usage: link-validator.sh [--full|--auto] [wiki_dir?] [target_file?]
FILE_TARGET=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --full) MODE="full"; shift;;
    --auto|-a) AUTO_MODE=true; MODE="full-auto"; shift;;
    --max) MAX_MATCHES="$2"; shift 2;;
    --file|-f) FILE_TARGET="$2"; shift 2;;
    *)
      if [[ -d "$1" ]]; then
        # Directory arg: treat as wiki_dir override
        WIKI_DIR="$1"
      elif [[ -n "$FILE_TARGET" && "$MODE" == "full" ]] || [[ -z "$FILE_TARGET" && "$MODE" != "" ]]; then
        # Second positional arg after mode is always a file target
        FILE_TARGET="$1"
      elif [[ "$MODE" == "" ]]; then
        # First positional arg before any flag: wiki_dir
        WIKI_DIR="$1"
        MODE="full"
      else
        FILE_TARGET="$1"
      fi
      shift
      ;;
  esac
done

TMP_RESULTS=$(mktemp)
echo -n "" > "$TMP_RESULTS"
TMP_FIXED=$(mktemp)
trap 'rm -f "$TMP_RESULTS" "$TMP_FIXED"' EXIT

# --- Fuzzy matching utility ---
normalize() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[-_ ]//g' | sed 's/\.\w\+$//'
}

fuzzy_score() {
  local broken="$1"       # e.g. "./Home_Manager.md" or "concepts/home-manager"
  local candidate="$2"    # e.g. "wiki/concepts/some-page.md"
  
  # Strip ./ prefix from broken path
  local clean_broken="${broken#./}"
  
  # Extract basename without extension
  local base_broken="${clean_broken##*/}"
  base_broken="${base_broken%.md}"
  
  # Get candidate relative path (strip wiki/ prefix)
  local rel_candidate="${candidate#wiki/}"
  
  # Extract candidate basename without extension
  local base_candidate="${rel_candidate##*/}"
  base_candidate="${base_candidate%.md}"
  
  # Normalize both for comparison
  local norm_broken=$(echo "$base_broken" | tr '[:upper:]' '[:lower:]' | sed 's/[-_ ]//g')
  local norm_candidate=$(echo "$base_candidate" | tr '[:upper:]' '[:lower:]' | sed 's/[-_ ]//g')
  
  # Strategy 1: exact match after normalization → score 100
  if [[ "$norm_broken" == "$norm_candidate" ]]; then
    echo "100"; return; fi
  
  # Strategy 2: one contains the other → score 90
  if [[ "$norm_broken" == *"$norm_candidate"* || "$norm_candidate" == *"$norm_broken"* ]]; then
    echo "90"; return; fi
    
  # Strategy 3: same directory, basename close → score 85
  local dir_broken="${clean_broken%/*}"
  local dir_candidate="${rel_candidate%/*}"
  
  if [[ "$dir_broken" == "$dir_candidate" ]]; then
    echo "85"; return; fi
    
  # Strategy 4: character overlap (Levenshtein approx)
  local len=${#norm_broken}
  [ ${#norm_candidate} -gt $len ] && len=${#norm_candidate}
  
  [[ $len -eq 0 ]] && echo "0" && return
  
  local common=0
  local tmp="$norm_candidate"
  for ((i=0; i<${#norm_broken}; i++)); do
    if [[ "$tmp" == *"${norm_broken:$i:1}"* ]]; then
      common=$((common + 1))
      tmp="${tmp#"${norm_broken:$i:1}"}"
    fi
  done
  
  local score=$(( (common * 100) / len ))
  
  [[ $score -ge 80 ]] && echo "$score" || echo "0"
}

# Find best match for a broken target among existing wiki files
find_best_match() {
  local target="$1"
  local score=0
  local best_file=""
  
  # Get base path (strip ./ and extension)
  local clean_target="${target#./}"
  
  while IFS= read -r candidate; do
    local cand_score=$(fuzzy_score "$clean_target" "$candidate")
    if [[ $cand_score -gt $score ]]; then
      score=$cand_score
      best_file="$candidate"
    fi
    
    # Early exit: perfect match found
    [[ $score -eq 100 ]] && break
  done < <(find "$WIKI_DIR" -name "*.md" -type f -maxdepth 5 2>/dev/null | head -$MAX_MATCHES)
  
  echo "${score}:${best_file}"
}

# Auto-fix a broken link by rewriting it to the best matching file
auto_fix_link() {
  local file="$1"       # The file containing the broken link
  local linenum="$2"    # Line number of the broken link
  local match="$3"      # The markdown link text (e.g. [text](broken))
  local target="$4"     # The broken target path
  local best_candidate="$5"   # Path to auto-fixed file
  
  # Extract link text (everything between [ and ])
  local link_text="${match#\[}"
  link_text="${link_text%%\]*}"
  
  # Build new markdown link with fixed path
  local new_target="${best_candidate#wiki/}"
  local new_link="[${link_text}](${new_target})"
  
  # Escape for sed: escape special characters in old and new patterns
  local old_pattern="][${target})]"
  local escaped_old=$(echo "$old_pattern" | sed 's/[\\&/\]/\\&/g')
  
  local escaped_new=$(echo "][${new_target})]" | sed 's/[\\&/\]/\\&/g')
  
  # Read file, replace the broken link with fixed one (atomic write)
  local tmp_file=$(mktemp)
  awk -v ln="$linenum" -v old="$escaped_old" -v new="$escaped_new" 'NR==ln{gsub(old,new)}1' "$file" > "$tmp_file"
  
  if [[ $? -eq 0 ]]; then
    cp "$file" "${file}.bak"
    mv "$tmp_file" "$file"
    
    # Track this fix for reporting
    echo "FIX:${file}:${linenum}:[${link_text}](${target}) -> [${link_text}](${new_target})" >> "$TMP_FIXED"
    
    rm -f "${file}.bak" 2>/dev/null || true
    return 0
  else
    rm -f "$tmp_file" 2>/dev/null || true
    return 1
  fi
}

check_file() {
  local file="$1"
  local linenum=0
  
  while IFS= read -r line || [[ -n "$line" ]]; do
    linenum=$((linenum + 1))
    
    if echo "$line" | grep -qE '\[[^]]+\]\([^)]+\)'; then
      while IFS= read -r match; do
        local target_path=$(echo "$match" | grep -oP '(?<=\]\()[^)]+(?=\))' || true)
        
        # Skip external URLs and mailto; raw/ is internal — must exist on disk
        case "$target_path" in
            https://*|http://*|mailto:*) continue ;;
            raw/*)
                # Check if raw file exists relative to project root
                local full_raw="$PROJECT_ROOT/$target_path"
                [[ ! -f "$full_raw" ]] && BROKEN_COUNT=$((BROKEN_COUNT + 1)) || continue
                ;;
        esac
        
        local base_target=$(echo "$target_path" | sed 's/#.*//')
        if [[ -z "$base_target" ]]; then continue; fi
        
        # Resolve relative path against the file's directory (not WIKI_DIR)
        local full_target="$WIKI_DIR/$base_target"
        if [[ "$target_path" == ../* ]]; then
            local target_dir=$(dirname "$file")
            local resolved=$(cd "$target_dir" 2>/dev/null && realpath -m "$base_target" 2>/dev/null) || true
            if [[ -n "$resolved" ]]; then full_target="$resolved"; fi
        fi
        
        if [[ ! -f "$full_target" ]]; then
          BROKEN_COUNT=$((BROKEN_COUNT + 1))
          
          # Auto mode: try to find best match
          if [[ "$AUTO_MODE" == "true" || "$MODE" == "full-auto" ]]; then
            local result=$(find_best_match "$target_path")
            local score="${result%%:*}"
            local best_file="${result##*:}"
            
            if [[ $score -ge 80 && -n "$best_file" ]]; then
              if auto_fix_link "$file" "$linenum" "$match" "$target_path" "$best_file"; then
                # Auto-fix succeeded — report but still add to results for audit trail
                echo "[✓] Auto-fixed: $file:$linenum -> $(echo "$match" | sed "s/](${target_path})/]($best_file/")" >&2
                
                # Rewrite JSON with auto_fixed flag and corrected target
                local safe_file=$(echo "$file" | sed 's/\\/\\\\/g; s/"/\\"/g')
                local safe_link=$(echo "$match" | sed 's/\\/\\\\/g; s/"/\\"/g')
                
                if [[ $BROKEN_COUNT -gt 1 ]]; then
                  printf ',' >> "$TMP_RESULTS"
                fi
                
                # Use the fixed target path in JSON output for audit trail
                local fixed_target="${best_file#wiki/}"
                local safe_fixed=$(echo "$fixed_target" | sed 's/\\/\\\\/g; s/"/\\"/g')
                printf '{"file":"%s","line":%d,"link":"%s","target_path":"%s","auto_fixed":true}' \
                  "$safe_file" "$linenum" "$safe_link" "$safe_fixed" >> "$TMP_RESULTS"
              fi
            else
              # Auto mode but no good match — add to results as not auto-fixed
              local safe_file=$(echo "$file" | sed 's/\\/\\\\/g; s/"/\\"/g')
              local safe_match=$(echo "$match" | sed 's/\\/\\\\/g; s/"/\\"/g')
              
              if [[ $BROKEN_COUNT -gt 1 ]]; then
                printf ',' >> "$TMP_RESULTS"
              fi
              printf '{"file":"%s","line":%d,"link":"%s","target_path":"%s","auto_fixed":false}' \
                "$safe_file" "$linenum" "$safe_match" "$target_path" >> "$TMP_RESULTS"
            fi
          else
            # Normal mode: just add to results
            local safe_file=$(echo "$file" | sed 's/\\/\\\\/g; s/"/\\"/g')
            local safe_match=$(echo "$match" | sed 's/\\/\\\\/g; s/"/\\"/g')
            
            if [[ $BROKEN_COUNT -gt 1 ]]; then
              printf ',' >> "$TMP_RESULTS"
            fi
            printf '{"file":"%s","line":%d,"link":"%s","target_path":"%s"}' \
              "$safe_file" "$linenum" "$safe_match" "$target_path" >> "$TMP_RESULTS"
          fi
        fi
      done < <(echo "$line" | grep -oE '\[[^]]+\]\([^)]+\)')
    fi
  done < "$file"
}

# --- Main execution ---

if [[ "$MODE" == "full" || "$MODE" == "full-auto" ]]; then
  if [[ -n "$FILE_TARGET" ]]; then
    # Single file mode: check only the specified target file
    local_file="$FILE_TARGET"
    [[ -f "$local_file" ]] || { echo "[!] File not found: $local_file" >&2; exit 1; }
    echo "[*] Scanning $local_file for broken internal links (auto-repair: $([ "$AUTO_MODE" = true ] && echo enabled || echo disabled))" >&2
    check_file "$local_file"
  else
    # Full wiki scan mode
    echo "[*] Scanning all wiki files for broken internal links (auto-repair: $([ "$AUTO_MODE" = true ] && echo enabled || echo disabled))" >&2
    
    while IFS= read -r file; do
      check_file "$file"
    done < <(find "$WIKI_DIR" -name "*.md" -type f -maxdepth 5 2>/dev/null | head -$MAX_MATCHES)
  fi

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
            
            # Auto mode: try to find best match
            if [[ "$AUTO_MODE" == "true" || "$MODE" == "full-auto" ]]; then
              local result=$(find_best_match "$local_target")
              local score="${result%%:*}"
              local best_file="${result##*:}"
              
              if [[ $score -ge 80 && -n "$best_file" ]]; then
                auto_fix_link "$local_filepath" "$local_linenum" "$match" "$local_target" "$best_file"
                echo "[✓] Auto-fixed: $local_filepath:$local_linenum -> $(echo "$match" | sed "s/](${local_target})/]($best_file/")" >&2
              fi
            fi
            
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
  
  while IFS= read -r jline; do
    ef=$(echo "$jline" | sed 's/.*"file":"\([^"]*\)".*/\1/')
    el=$(echo "$jline" | sed 's/.*"link":"\([^"]*\)".*/\1/')
    echo "    $ef -> $el" >&2
  done < <(grep -oE '"file":[^}]*}' "$TMP_RESULTS")
  
  # Auto mode: report auto-fixed count and agent review list
  if [[ "$AUTO_MODE" == "true" || "$MODE" == "full-auto" ]]; then
    fixed_count=0
    [ -s "$TMP_FIXED" ] && fixed_count=$(wc -l < "$TMP_FIXED")
    
    echo "[✓] Auto-repaired: $fixed_count broken links" >&2
    
    if [[ $fixed_count -gt 0 ]]; then
      while IFS= read -r fix_line; do
        echo "  $fix_line" >&2
      done < "$TMP_FIXED"
    fi
    
    # Build agent review list (auto_fixed=false entries)
    local_review_json="[]"
    remaining=$(grep -c '"auto_fixed":false' "$TMP_RESULTS" 2>/dev/null || true)
    if [[ $remaining -gt 0 ]]; then
      echo "[!] Agent review required: $remaining links need manual attention" >&2
      # Extract agent_review_required entries to a separate file
      TMP_REVIEW=$(mktemp)
      grep '"auto_fixed":false' "$TMP_RESULTS" | while IFS= read -r entry; do
        local_file=$(echo "$entry" | sed 's/.*"file":"\([^"]*\)".*/\1/')
        local_link=$(echo "$entry" | sed 's/.*"link":"\([^"]*\)".*/\1/')
        local_target=$(echo "$entry" | sed 's/.*"target_path":"\([^"]*\)".*/\1/')
        echo "{\"file\": \"$local_file\", \"link\": \"$local_link\", \"target\": \"$local_target\"}" >> "$TMP_REVIEW"
      done
      # Wrap in array
      local_review_json="[$(cat "$TMP_REVIEW")]" 2>/dev/null || local_review_json="[]"
      rm -f "$TMP_REVIEW"
    fi
    
    # Wrap everything in proper JSON object and append agent_review_required
    RESULT_JSON="{\"broken_links\":$RESULT_JSON,\"agent_review_required\":${local_review_json}}"
  fi
  
  echo "$RESULT_JSON"
  exit 1
fi

echo "[✓] All internal links are valid" >&2
exit 0
