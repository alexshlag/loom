#!/usr/bin/env bash
# regenerate-backlinks.sh — regenerates meta/backlinks.json from wiki files
# Usage: ./scripts/regenerate-backlinks.sh [wiki_dir] [output_json]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/.."
WIKI_DIR="${1:-$PROJECT_ROOT/wiki}"
OUTPUT_JSON="${2:-$PROJECT_ROOT/meta/backlinks.json}"

mkdir -p "$(dirname "$OUTPUT_JSON")"

python3 << EOF
import os, json, re

wiki_dir = "${WIKI_DIR}"
output_path = "${OUTPUT_JSON}"

# Collect all markdown files
all_md = []
for root, dirs, files in os.walk(wiki_dir):
    if 'meta' in dirs:
        dirs.remove('meta')
    for f in files:
        if f.endswith('.md'):
            full_path = os.path.join(root, f)
            rel_path = os.path.relpath(full_path, wiki_dir)
            all_md.append((full_path, rel_path))

# Extract wikilinks from each file
backlinks = {}  # {target_rel: [{from_source, ...}]}

for full_path, rel_path in all_md:
    with open(full_path, 'r') as f:
        content = f.read()
    
    # Find [[wiki/path]] or [[path]] wikilinks
    for match in re.finditer(r'\[\[(?:wiki/)?([\w./\-]+\.md)\]\]', content):
        target = match.group(1)
        if 'meta' not in rel_path:  # skip meta files
            source_key = rel_path.replace('/', '-').replace('.md', '')
            
            if target not in backlinks:
                backlinks[target] = []
            backlinks[target].append({
                "from": source_key,
                "context": f"wikilink from {rel_path}"
            })

# Convert to index format: {dash-path: [{from, context}]}
index = {}
for target, sources in backlinks.items():
    # Only include wiki pages (not raw/)
    if 'raw/' not in target:
        key = target.replace('/', '-').replace('.md', '')
        index[key] = {
            "to": target,
            "sources": sources
        }

data = {"backlinks": index}
with open(output_path, 'w') as f:
    json.dump(data, f, indent=2)

print(f"Regenerated backlinks.json with {len(index)} indexed pages")
EOF


echo "[✓] Backlinks regenerated at $OUTPUT_JSON" >&2
