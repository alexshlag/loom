# Memory Sync at Task End — Context Saving Contract (V1)

## Purpose

After completing any task (ingest, query, lint, script creation), the agent MUST save context before committing or moving to next step. This prevents context loss across session boundaries and ensures wiki/hot.md reflects current state.

## When to Sync

| Trigger | Action Required |
|---------|-----------------|
| Task completed successfully | Update WM + refresh hot cache |
| Task failed / interrupted | Update WM with error details, log in wiki/log.md |
| Wiki files modified | Refresh hot cache immediately (not wait for commit) |
| Working memory updated | Regenerate hot cache from WM + log.md |

## Procedure

### Step 1: Update working_memory.json

After task completion, call `scripts/memory/sync-working-memory.sh` with parameters:
```bash
./scripts/memory/sync-working-memory.sh \
    --focus-node "Task name or operational focus" \
    --task-status completed \
    --next-steps "step1, step2" \
    --quiet > /dev/null 2>&1 || true
```

**What to update:**
- `focus_node` → current operational focus (what we're doing RIGHT NOW)
- `recent_activity` → append entry with timestamp and task status
- `next_steps_todo` → filter completed items, add next pending tasks

### Step 2: Refresh wiki/hot.md

Run hot cache refresh to incorporate WM changes + recent log entries:
```bash
./scripts/memory/hot-cache-auto-refresh.sh --quiet > /dev/null 2>&1 || true
```

**Note:** This reads working_memory.json and wiki/log.md, regenerates wiki/hot.md from both sources. Must run AFTER WM update (Step 1) so hot.md reflects latest focus_node + next_steps.

### Step 3: Commit with Git Conventions

After sync complete → follow git_conventions.json#pre_commit_workflow:
```bash
git add -A && git commit -m "<type> | <scope>: <description>"
```

## Constraints

- **NEVER** skip memory sync before commit — context saved to WM/hot.md is the only mechanism for next-session bootstrap
- **NEVER** write WM via append (cat >>) — always use atomic read→modify→write pattern
- **NEVER** update hot.md manually — always run hot-cache-auto-refresh.sh after WM changes

## Schema References

- `rules/git_conventions.json#memory_sync_on_dev_commit` — commit workflow integration
- `rules/session_context_rules.json#write_triggers` — when to trigger sync (HOT-SAVE-ACTION-V1, etc.)
- `scripts/memory/sync-working-memory.sh` — atomic WM update script
- `scripts/memory/hot-cache-auto-refresh.sh` — hot cache regeneration

## Example: Post-Lint Sync

After lint.sh completes with changes:
```bash
# Step 1: Update WM
./scripts/memory/sync-working-memory.sh \
    --focus-node "Lint completed, structural fixes applied" \
    --task-status completed \
    --next-steps "review orphan suggestions, commit changes" \
    --quiet > /dev/null

# Step 2: Refresh hot cache (reads updated WM + log)
./scripts/memory/hot-cache-auto-refresh.sh --quiet > /dev/null || true

# Step 3: Commit via git_conventions.json workflow
git add -A && git commit -m "lint | mechanical_linting: structural fixes applied"
```

## Example: Post-Ingest Sync

After ingesting new source documents:
```bash
# Step 1: Update WM with current focus and pending tasks
./scripts/memory/sync-working-memory.sh \
    --focus-node "Ingested docs/ sources, verify STI-V1 rule" \
    --task-status completed \
    --next-steps "Deep-dive wiki/docs/, consider faq/glossary for new users" \
    --quiet > /dev/null

# Step 2: Refresh hot cache (reads updated WM + log)
./scripts/memory/hot-cache-auto-refresh.sh --quiet > /dev/null || true

# Step 3: Commit
git add wiki/docs/* && git commit -m "ingest | docs: phase 23 completed"
```
