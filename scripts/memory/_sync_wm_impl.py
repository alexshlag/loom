import json, os, sys, datetime, tempfile

wm_file = os.environ.get('WM_FILE', './working_memory.json')
focus_node = os.environ.get('FOCUS_NODE', '')
task_status = os.environ.get('TASK_STATUS', 'completed')
next_steps_str = os.environ.get('NEXT_STEPS', '')
quiet = os.environ.get('QUIET', 'false').lower() == 'true'

# Read existing WM — NEVER append, always complete rewrite
try:
    with open(wm_file) as f:
        wm = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    # Create new WM if missing/corrupted
    wm = {}

# Update timestamp
wm['last_updated'] = datetime.datetime.now().strftime('%Y-%m-%dT%H:%M%z')

# Update focus_node if provided
focus_updated = False
if focus_node:
    wm['focus_node'] = focus_node
    # Log to recent_activity if exists
    activity_list = wm.get('recent_activity', [])
    activity_list.append(f"{datetime.datetime.now().strftime('%Y-%m-%d %H:%M')} | {task_status} | {focus_node}")
    wm['recent_activity'] = activity_list[-20:]  # Keep last 20 entries
    focus_updated = True

# Update next_steps if provided (comma-separated)
next_steps_updated = False
if next_steps_str:
    steps = [s.strip() for s in next_steps_str.split(',') if s.strip()]
    wm['next_steps_todo'] = steps
    next_steps_updated = True

# Write atomically via temp file + mv
import os as _os
tmp_fd, tmp_path = tempfile.mkstemp(dir=_os.path.dirname(wm_file))
with _os.fdopen(tmp_fd, 'w') as f:
    json.dump(wm, f, indent=2, ensure_ascii=False)
_os.replace(tmp_path, wm_file)

# Output JSON report to stdout (for process-lint.json downstream processing)
print(json.dumps({
    'synced': True,
    'focus_node_updated': focus_updated,
    'next_steps_updated': next_steps_updated,
    'file': os.path.basename(wm_file),
    'focus_node_value': focus_node[:50] if focus_node else None,
    'next_steps_count': len(next_steps_str.split(',')) if next_steps_str else 0
}, indent=2))

if not quiet and (focus_updated or next_steps_updated):
    print(f"[✓] WM synced: task_status={task_status}", file=sys.stderr)
    if focus_updated:
        print(f"   focus_node={focus_node[:50]}...", file=sys.stderr)
