#!/usr/bin/env bash
# docs-audit.sh — Audit wiki/docs/ pages for structural issues
# Checks: missing nav headers, broken links, orphaned pages, duplicate content
# Usage: ./scripts/docs-audit.sh [--fix-automatically]
# Exit code: 0 = all good, 1 = issues found

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/.."
WIKI_DIR="${PROJECT_ROOT}/wiki"
DOCS_DIR="${WIKI_DIR}/docs"
BACKLINKS_JSON="${PROJECT_ROOT}/meta/backlinks.json"

# Create docs dir if not exists (STATE A scenario)
if [ ! -d "$DOCS_DIR" ]; then
    echo "[✓] STATE A: wiki/docs/ does not exist — no audit needed, generate overview first." >&2
    exit 0
fi

python3 << PYEOF
import json, os, sys, re
from pathlib import Path

docs_dir = "${DOCS_DIR}"
backlinks_json_path = "${BACKLINKS_JSON}"
fix_auto = "--fix-automatically" in sys.argv

# ─── Load backlinks index ───
backlinks_map = {}
if os.path.exists(backlinks_json_path):
    with open(backlinks_json_path) as f:
        backlinks_map = json.load(f)

issues_found = []
warnings_found = []
auto_fixes_applied = []

# ─── 1. Check nav headers on doc pages ───
nav_header_pattern = re.compile(r'\[←\s.*?Back to Index.*?\](?:.*)\[Next Topic →\]|Back to Index.*?\]')

for md_file in Path(docs_dir).rglob('*.md'):
    if 'docs-index.md' in str(md_file):
        continue  # index page doesn't need nav header
    
    content = md_file.read_text()
    
    # Check if nav header exists
    has_nav_header = bool(nav_header_pattern.search(content))
    
    if not has_nav_header:
        issues_found.append({
            'file': str(md_file).replace(f'{docs_dir}/', ''),
            'issue': 'missing_nav_header',
            'severity': 'HIGH',
            'fix_suggestion': f'Add nav header at top:\n[← Previous Topic](prev.md) · [Back to Index]({md_file.parent.name == "docs" and "../docs-index.md" or "../../docs-index.md"}) · [Next Topic →](next.md)'
        })

# ─── 2. Check broken links in docs ───
for md_file in Path(docs_dir).rglob('*.md'):
    content = md_file.read_text()
    
    # Extract wiki-relative links (wiki/path/to/file.md or relative paths)
    wiki_links = re.findall(r'\[.*?\]\((wiki/[^)]+\.md)\)', content)
    relative_links = re.findall(r'\[.*?\]\((?<!wiki/)(?!../)([^)\'"\s]+\.md)\)', content)
    
    all_links = wiki_links + [f'{docs_dir}/{l}' for l in relative_links]
    
    for link_path in set(all_links):
        full_path = os.path.join(docs_dir, link_path) if not link_path.startswith('wiki') else f'..{link_path}'
        
        # Normalize path
        full_path = os.path.normpath(full_path)
        
        if not os.path.exists(full_path):
            issues_found.append({
                'file': str(md_file).replace(f'{docs_dir}/', ''),
                'issue': 'broken_link',
                'severity': 'HIGH',
                'link_target': link_path,
                'fix_suggestion': f'Remove or fix broken link to {link_path}'
            })

# ─── 3. Check orphaned docs pages (no backlinks) ───
for md_file in Path(docs_dir).rglob('*.md'):
    if 'docs-index.md' in str(md_file):
        continue
    
    rel_path = str(md_file).replace(f'{docs_dir}/', '')
    
    # Check if page has incoming links
    has_backlinks = backlinks_map.get(rel_path, [])
    
    if not has_backlinks:
        issues_found.append({
            'file': rel_path,
            'issue': 'orphaned_page',
            'severity': 'MEDIUM',
            'fix_suggestion': f'Add incoming crosslink to this page from related entity/concept pages'
        })

# ─── 4. Check duplicate/overlapping content ───
doc_contents = {}
for md_file in Path(docs_dir).rglob('*.md'):
    if 'docs-index.md' not in str(md_file):
        doc_contents[str(md_file).replace(f'{docs_dir}/', '')] = md_file.read_text()

# Simple overlap detection: check for similar first paragraphs
doc_items = list(doc_contents.items())
for i, (name1, content1) in enumerate(doc_items):
    for j, (name2, content2) in enumerate(doc_items):
        if j <= i:
            continue
        
        # Check if both have very similar intro sections (first 200 chars)
        intro1 = content1[:200].lower().replace('\n', ' ').strip()
        intro2 = content2[:200].lower().replace('\n', ' ').strip()
        
        # Simple word overlap check
        words1 = set(intro1.split())
        words2 = set(intro2.split())
        overlap = len(words1 & words2) / max(len(words1), len(words2), 1)
        
        if overlap > 0.7 and len(content1) > 500:  # High overlap threshold
            warnings_found.append({
                'files': [name1, name2],
                'issue': 'potential_duplicate',
                'severity': 'LOW',
                'fix_suggestion': f'Consider merging {name1} and {name2} — they have overlapping content ({int(overlap*100)}% intro overlap)'
            })

# ─── Output Results ───
print(f"📊 Docs Audit Report")
print(f"{'=' * 60}")
print(f"\n🔴 Issues Found: {len(issues_found)}")
for issue in issues_found:
    print(f"   [{issue['severity']}] {issue['file']} — {issue['issue']}")
    if 'fix_suggestion' in issue:
        print(f"      Fix: {issue['fix_suggestion']}")

print(f"\n🟡 Warnings Found: {len(warnings_found)}")
for warning in warnings_found:
    print(f"   [{warning['severity']}] {', '.join(warning['files'])} — {warning['issue']}")
    if 'fix_suggestion' in warning:
        print(f"      Suggestion: {warning['fix_suggestion']}")

print(f"\n{'=' * 60}")

# Auto-fix mode (if enabled)
if fix_auto and issues_found:
    print("\n🔧 Auto-fixing high-severity issues...")
    # TODO: implement auto-fix logic for nav headers, broken links
    
exit(1 if issues_found else 0)
PYEOF
