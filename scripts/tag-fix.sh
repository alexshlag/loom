#!/usr/bin/env bash
# Fix generic tags → domain-specific tags in wiki pages
set -euo pipefail

cd "$(dirname "$0")/.." || exit 1

# Tag replacements: generic → specific, based on audit findings
declare -A REPLACEMENTS=(
    # entities/
    ["wiki/entities/ibexa-dxp.md"]="cms→commerce-cms"
    ["wiki/entities/nvidia.md"]="ai→gpu-manufacturer"
    ["wiki/entities/nodejs.md"]="runtime→node-runtime"

    # concepts/
    ["wiki/concepts/hexagonal-architecture.md"]="hexagonal→hexagonal-pattern, clean-architecture→clean-architecture-pattern"
    ["wiki/concepts/easyadmin-bundle.md"]="admin→easyadmin-admin-ui"
    ["wiki/concepts/symfony-ai.md"]="ai→llm-integration"
    ["wiki/concepts/ai-factory-vs-pi.md"]="methodology→agent-workflow-comparison"
    ["wiki/concepts/testing-strategy.md"]="testing→test-framework-comparison"
    ["wiki/concepts/workflow-state-machine.md"]="workflow→state-machinery-pattern"
    ["wiki/concepts/sonata-admin-bundle.md"]="admin→sonata-admin-ui, cms→content-management"
    ["wiki/concepts/assetmapper.md"]="frontend→asset-pipeline"
    ["wiki/concepts/messenger-component.md"]="messenger→async-message-queue"
    ["wiki/concepts/cache-system.md"]="cache→psr6-caching"
    ["wiki/concepts/security-system.md"]="security→access-control-voters"

    # comparisons/
    ["wiki/comparisons/loom-vs-claude-obsidian.md"]="architecture→vault-architecture, workflow→knowledge-workflow"
    ["wiki/comparisons/llm-wiki-implementations.md"]="platform→implementation-pattern"
)

# Apply fixes
for file in "${!REPLACEMENTS[@]}"; do
    replacements="${REPLACEMENTS[$file]}"
    
    IFS=','
    for pair in $replacements; do
        from=$(echo "$pair" | cut -d'→' -f1)
        to=$(echo "$pair" | cut -d'→' -f2)
        
        if grep -q "tags:.*$from" "$file"; then
            echo "Fixing $file: $from → $to"
            
            # Read file, replace tag, write back
            content=$(cat "$file")
            new_content="${content//$from/$to}"
            
            # Write atomically via temp + mv
            tmp_file=$(mktemp)
            echo "$new_content" > "$tmp_file"
            mv "$tmp_file" "$file"
        fi
    done
done

echo "✅ Tag fixes applied to ${#REPLACEMENTS[@]} files"
