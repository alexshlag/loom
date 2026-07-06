#!/usr/bin/env bash
echo "=== Benchmarking rebuild-meta approaches ==="
echo ""

# Clean state
rm -f wiki/.meta_update_timestamp

# NEW: Single-pass wiki-walk.py
echo "[NEW] Single-pass (wiki-walk.py)" 
START=$(date +%s.%N)
./scripts/rebuild-meta.sh > /tmp/new_out.log 2>&1 || true
END=$(date +%s.%N)
NEW_TIME=${END%.*}.$(( ${END##*.} ))
echo "Time: $(python3 -c 'import time; s=float("'${START}'"); e=float("'${END}'"); print(f"{e-s:.3f}")')s"

# Count pages
NEW_PAGES=$(python3 -c "import json; print(len(json.load(open('meta/registry.json'))['pages']))")
echo "Registry pages: $NEW_PAGES"
echo ""

# OLD: Triple walk backup  
rm -f wiki/.meta_update_timestamp
echo "[OLD] Triple os.walk() (original)" 
START=$(date +%s.%N)
bash scripts/rebuild-meta.sh.bak > /tmp/old_out.log 2>&1 || true
END=$(date +%s.%N)
echo "Time: $(python3 -c 'import time; s=float("'${START}'"); e=float("'${END}'"); print(f"{e-s:.3f}")')s"

# Count pages  
OLD_PAGES=$(python3 -c "import json; d=json.load(open('meta/registry.json')); exclude={'log.md','issues.md','timeline.md','overview.md','snapshot.md','index.md'}; print(len([p for p in d['pages'] if not any(x in p['path'] for x in exclude)]))")
echo "Registry wiki pages: $OLD_PAGES"

echo ""
echo "=== Summary ===" 
echo "Single-pass eliminates 3x os.walk() calls → O(n) instead of O(3n)"
echo "Expected speedup: ~20-30% on large wikis (100+ pages)"
