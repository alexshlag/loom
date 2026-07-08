import json, os, sys, re
from pathlib import Path
import subprocess

wiki_dir = os.environ.get('WIKI_DIR', './wiki')
backlinks_json_path = os.environ.get('BACKLINKS_JSON', './meta/backlinks.json')
quiet = os.environ.get('QUIET', 'false').lower() == 'true'
project_root = os.environ.get('PROJECT_ROOT', '.')

SYSTEM_FILES = {
    'log.md', 'issues.md', 'timeline.md', 'overview.md',
    'snapshot.md', 'index.md', 'hot.md', 'GIT-TROUBLESHOOTING.md',
    'GIT-WORKFLOW.md', 'Home_Manager.md'
}
EXCLUDED_DIRS = {'skills'}
EXCLUDED_FILES = {'test-excess-empty.md'}
TRAJECTORY_PATTERNS = {'_TRJ-', 'TRJ-'}

all_pages = []
for root, dirs, files in os.walk(wiki_dir):
    if 'meta' in dirs:
        dirs.remove('meta')
    for f in files:
        if not f.endswith('.md'):
            continue
        
        basename = os.path.basename(f)
        
        # Skip system files
        if basename in SYSTEM_FILES:
            continue
        
        rel_path = os.path.relpath(os.path.join(root, f), wiki_dir)
        if any(d in root.replace(wiki_dir, '').lstrip('/') for d in EXCLUDED_DIRS):
            continue
        if basename in EXCLUDED_FILES:
            continue
            
        skip = False
        for pattern in TRAJECTORY_PATTERNS:
            if pattern in f:
                skip = True
                break
        if skip:
            continue
            
        full_path = os.path.join(root, f)
        rel_path = os.path.relpath(full_path, wiki_dir)
        all_pages.append(rel_path)

# Load backlinks.json → extract all target keys (JSON keys)
backlink_targets = set()
if os.path.exists(backlinks_json_path):
    with open(backlinks_json_path) as f:
        data = json.load(f)
    if isinstance(data, dict):
        if 'backlinks' in data:
            keys = list(data['backlinks'].keys())
        else:
            keys = list(data.keys())
        for key in keys:
            backlink_targets.add(key.lower().replace('-', '').replace(' ', ''))

# Find orphans — pages without incoming links (no key in backlinks.json)
orphans = []
for page in all_pages:
    normalized_key = page.replace('.md', '').lower()
    
    if normalized_key not in [k.lower() for k in backlink_targets]:
        orphans.append(page)

# For each orphan, suggest top crosslink candidates (score ≥5 via auto-crosslink.sh logic)
suggestions = []
if len(orphans) > 0 and os.path.exists(os.path.join(project_root, 'scripts', 'auto-crosslink.sh')):
    for orphan_path in orphans:
        # Use auto-crosslink.sh to get suggestions (without --auto-fix)
        cmd = ['./scripts/auto-crosslink.sh', orphan_path, '--max-results', '3', '--min-score', '5']
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
            
            # Parse JSON output from auto-crosslink.sh
            if result.stdout.strip():
                candidates = json.loads(result.stdout)
                
                for c in candidates:
                    score = c.get('score', 0)
                    path = c['path']
                    match_types = c.get('match_types', [])
                    
                    # Build suggestion entry
                    suggestion = {
                        'orphan_page': orphan_path,
                        'candidate_page': f"wiki/{path}",
                        'suggested_score': score,
                        'reason': ', '.join(match_types),
                        'action_required': True  # agent must review before applying
                    }
                    
                    suggestions.append(suggestion)
        except Exception:
            pass

# Output JSON to stdout (machine-parseable for process-lint.json post_lint_actions)
print(json.dumps({
    'orphans_count': len(orphans),
    'orphans_list': orphans,
    'suggestions': suggestions if len(suggestions) > 0 else [],
    'agent_review_required': True,
    'note': 'Auto-crosslink scoring detected candidates, but agent must review before applying links'
}, indent=2))

# Print summary on stderr (human-readable for debugging/logging)
if not quiet:
    if len(orphans) > 0:
        print(f"[!] Orphan pages found ({len(orphans)}):", file=sys.stderr)
        for o in orphans[:5]:  # Show max 5 paths
            print(f"   {o}", file=sys.stderr)
        
        if len(suggestions) > 0:
            print(f"\n[*] Suggested crosslinks ({len(suggestions)} candidates):", file=sys.stderr)
            for s in suggestions[:5]:
                print(f"   {s['orphan_page']} → {s['candidate_page']} (score: {s['suggested_score']}) — {s['reason']}", file=sys.stderr)

sys.exit(0)  # Never fail — report is always informational
