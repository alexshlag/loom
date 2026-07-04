#!/bin/bash
# scripts/tag-audit.sh — Tag audit with auto-fix capability
# Usage: ./scripts/tag-audit.sh [--fix] [--quiet] [wiki_dir]
# Returns JSON on stdout + human-readable report to stderr

set -uo pipefail

WIKI_DIR="${1:-$(dirname "$0")/../wiki}"
FIX_MODE=false
QUIET=false
GENERIC_TAGS=("concept" "entity" "synthesis" "comparison" "summary" "analysis")

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --fix) FIX_MODE=true; shift;;
    --quiet) QUIET=true; shift;;
    *) WIKI_DIR="$1"; shift;;
  esac
done

# Map common non-English tags to English equivalents
declare -A TAG_MAP=(
  ["концепция"]="concept"
  ["сущность"]="entity"
  ["домен"]="domain"
  ["архитектура"]="architecture"
  ["паттерн"]="pattern"
)

# Helper function: convert non-EN tags to English using TAG_MAP
convert_tags() {
    local tags="$1"
    local cleaned="${tags#[}"
    cleaned="${cleaned%}}"
    
    IFS=',' read -ra tag_arr <<< "$cleaned"
    local result=""
    for tag in "${tag_arr[@]}"; do
        tag=$(echo "$tag" | xargs 2>/dev/null || echo "$tag")
        
        # Skip empty
        [[ -z "$tag" ]] && continue
        
        # Check if non-EN
        if echo "$tag" | grep -qP '[а-яА-ЯёЁ]'; then
            local mapped="${TAG_MAP[$tag]:-}"
            if [[ -n "$mapped" ]]; then
                tag="$mapped"
            else
                continue
            fi
        fi
        
        # Skip generic type tags
        local is_generic=false
        for gen in "${GENERIC_TAGS[@]}"; do
            if [[ "$tag" == "$gen" ]]; then
                is_generic=true
                break
            fi
        done
        $is_generic && continue
        
        # Add to result (avoid duplicates)
        if [[ -z "$result" ]]; then
            result="$tag"
        else
            local has_dup=false
            IFS=',' read -ra existing <<< "${result}"
            for ex in "${existing[@]}"; do
                if [[ "$ex" == "$tag" ]]; then
                    has_dup=true
                    break
                fi
            done
            $has_dup || result="$result,$tag"
        fi
    done
    
    echo "[$result]"
}

# Helper: check if tag is generic type
is_generic() {
    local tag="$1"
    for gen in "${GENERIC_TAGS[@]}"; do
        [[ "$tag" == "$gen" ]] && return 0
    done
    return 1
}

# Count issues and optionally fix
empty_count=0
non_en_count=0
generic_count=0
xr_count=0
aliases_missing=0

all_pages=$(find "$WIKI_DIR/entities" "$WIKI_DIR/concepts" "$WIKI_DIR/syntheses" "$WIKI_DIR/comparisons" -name "*.md" 2>/dev/null | sort)

# Process each page for issues and fixes
while IFS= read -r f; do
    rel_path="${f#wiki/}"
    
    tags_line=$(head -10 "$f" | grep "^tags:" 2>/dev/null || true)
    [[ -z "$tags_line" ]] && continue
    
    tag_content="${tags_line#*tags: *}"
    tag_content="${tag_content#[}"
    tag_content="${tag_content%]}"
    
    # Check empty tags (TAG-P4)
    if [[ -z "$tag_content" ]] || ! echo "$tag_content" | grep -qP '[a-z]'; then
        ((empty_count++)) || true
        continue
    fi
    
    # Count tags for aliases_missing check (high search-potential pages need aliases)
    tag_num=$(echo "${my_tags[@]}" | tr ' ' '\n' | grep -c '.' || true)
    if [[ "$tag_num" -ge 5 ]]; then
        alias_line=$(head -10 "$f" | grep '^aliases:' 2>/dev/null || true)
        if [[ -z "$alias_line" ]] || [[ "$alias_line" == *"aliases: []"* ]] || [[ "$alias_line" == *"aliases:" ]]; then
            ((aliases_missing++)) || true
        fi
    fi
    
    IFS=',' read -ra my_tags <<< "$tag_content"
    
    # Check non-EN tags (TAG-P6) and fix if --fix mode
    has_non_en=false
    for tag in "${my_tags[@]}"; do
        tag=$(echo "$tag" | xargs 2>/dev/null || echo "$tag")
        [[ -z "$tag" ]] && continue
        
        if echo "$tag" | grep -qP '[а-яА-ЯёЁ]'; then
            has_non_en=true
            ((non_en_count++)) || true
            
            # FIX: convert to English using TAG_MAP
            if $FIX_MODE; then
                mapped="${TAG_MAP[$tag]:-}"
                if [[ -n "$mapped" ]]; then
                    sed -i "s/${tag}/${mapped}/g" "$f"
                fi
            fi
        fi
        
        # Check generic type tags (TAG-P1) and fix if --fix mode
        for gen in "${GENERIC_TAGS[@]}"; do
            if [[ "$tag" == "$gen" ]]; then
                ((generic_count++)) || true
                
                # FIX: remove generic tag from array
                if $FIX_MODE; then
                    sed -i "s/${tag},//g;s/,${tag}//g" "$f"
                fi
            fi
        done
    done
    
    # Check XR gaps (TAG-P3) — only count, don't auto-fix (needs semantic judgment)
    if $has_non_en || [[ -z "$tag_content" ]]; then continue; fi
    
    links=$(grep -oP '\[\[[^\]]+\]\]' "$f" 2>/dev/null || true)
    [[ -z "$links" ]] && continue
    
    while IFS= read -r link; do
        target_path=$(echo "$link" | sed 's/\[\[\(.*\)\]\]/\1/')
        
        # Handle .md extension
        if [[ "$target_path" == *.md ]]; then
            target_file="$WIKI_DIR/${target_path}"
        else
            target_file="$WIKI_DIR/${target_path}.md"
        fi
        
        [[ ! -f "$target_file" ]] && continue
        
        # Get target's tags (skip empty/generic)
        target_tags_line=$(head -10 "$target_file" | grep "^tags:" 2>/dev/null || true)
        [[ -z "$target_tags_line" ]] && continue
        
        target_tag_content="${target_tags_line#*tags: *}"
        target_tag_content="${target_tag_content#[}"
        target_tag_content="${target_tag_content%}}"
        
        # Skip empty or all-generic tags
        IFS=',' read -ra tt_arr <<< "$target_tag_content"
        has_domain=false
        for tt in "${tt_arr[@]}"; do
            tt=$(echo "$tt" | xargs 2>/dev/null || echo "$tt")
            [[ -z "$tt" ]] && continue
            
            skip_gen=true
            if ! is_generic "$tt"; then
                skip_gen=false
            fi
            $skip_gen && continue
            
            has_domain=true
            break
        done
        
        # Check shared tags (domain-level, not generic)
        IFS=',' read -ra target_tags <<< "$target_tag_content"
        has_shared=false
        for mt in "${my_tags[@]}"; do
            [[ -z "$mt" ]] && continue
            skip_mt=true
            if ! is_generic "$mt"; then
                skip_mt=false
            fi
            $skip_mt && continue
            
            for tt in "${target_tags[@]}"; do
                [[ -z "$tt" ]] && continue
                skip_tt=true
                if ! is_generic "$tt"; then
                    skip_tt=false
                fi
                $skip_tt && continue
                
                if [[ "$mt" == "$tt" ]]; then
                    has_shared=true
                    break
                fi
            done
            $has_shared && break
        done
        
        if ! $has_shared; then
            ((xr_count++)) || true
        fi
    done <<< "$links"
done <<< "$all_pages"

# Build JSON output
cat <<EOF
{
  "timestamp": "$(date +%Y-%m-%dT%H:%M:%S)",
  "wiki_dir": "${WIKI_DIR#/}",
  "issues_found": {
    "empty_tags": ${empty_count},
    "non_en_tags": ${non_en_count},
    "generic_type_tags": ${generic_count},
    "xr_gaps": ${xr_count},
    "aliases_missing": ${aliases_missing}
  },
  "total_issues": $((empty_count + non_en_count + generic_count + xr_count + aliases_missing)),
  "status": "$([ $((empty_count + non_en_count + generic_count + xr_count)) -eq 0 ] && echo 'CLEAN' || echo 'ISSUES_FOUND')"
}
EOF

# Human-readable summary to stderr
if [ "$QUIET" != true ]; then
    cat >&2 <<ERRSUMMARY
=== Tag Audit Report — $(date +%Y-%m-%d) ===

Issues found:
- Empty/missing tags (TAG-P4): ${empty_count}
- Non-English tags (TAG-P6): ${non_en_count}
- Generic type duplicates (TAG-P1): ${generic_count}
- Cross-reference gaps (TAG-P3): ${xr_count}
- Missing aliases for high-potential pages (≥5 tags): ${aliases_missing}

$(if $FIX_MODE; then echo "Fix mode enabled — auto-fix applied."; fi)
ERRSUMMARY
fi

exit $([ "$((empty_count + non_en_count + generic_count + xr_count + aliases_missing))" -eq 0 ] && echo 0 || echo 1)
