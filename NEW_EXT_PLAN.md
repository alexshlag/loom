# Harness-Independent Session & Git Automation — Plan v1

## 🎯 Goal

Adopt `claude-obsidian`'s session management and git auto-commit patterns into LOOM, but **adapt to our existing architecture** rather than blindly copying. The goal is harness-independent operation (works in Pi, Claude Code, Codex, etc.) without breaking existing processes.

---

## 🔍 Architecture Fit Analysis

### What `claude-obsidian` does:
| Hook | Trigger | Action |
|------|---------|--------|
| `SessionStart` | New session | Load `wiki/hot.md` via prompt injection |
| `PostToolUse` | After Write/Edit | `git add wiki/.raw/ && git commit -m "..."` |
| `PostCompact` | Context compacted | Re-read + inject `wiki/hot.md` again |
| `Stop` | End of response | Check changes → update hot.md |

### Our current architecture:
| Component | Purpose | Gap to fill |
|-----------|---------|-------------|
| `working_memory.json` | Session bridge (focus, next_steps, open_pages) | ❌ Doesn't contain wiki facts — only session metadata |
| `process-ingest.json` | Ingest pipeline with post-checks | ✅ Has `rebuild-meta.sh`, `link-validator.sh`, `auto-crosslink.sh` |
| `process-query.json` | Query with grep_contract, compounding logic | ❌ No hot.md loading at start; no restore after compact |
| `process-lint.json` → `lint.sh` | Non-blocking health checks | ✅ Uses scripts already (orphan-pages, link-validator) |
| `.git/hooks/pre-commit` | Blocks protected zones | ❌ Doesn't auto-commit wiki changes |

### Key insight:
We **don't replace** working_memory.json — it serves a different purpose. We **add** hot.md as the *fact layer* complement to WM's *session metadata*. They co-exist and are read at different points in the lifecycle.

---

## 📋 Implementation Plan

### Phase 1: Create 4 Scripts (from research.md)

#### `scripts/git-auto-commit.sh`
- Stages only: `wiki/`, `.raw/`, `.vault-meta/`
- Respects existing wiki-lock.sh concurrency checks
- Checks for `.vault-meta/auto-commit.disabled` flag
- Uses git diff --cached to avoid empty commits
- **Does NOT conflict** with pre-commit hook — complementary

#### `scripts/load-hot-cache.sh`
- Reads `wiki/hot.md` from disk, outputs to stdout wrapped in markers
- Returns exit 1 if vault doesn't exist (graceful no-op)
- Silent consumption by agent (no announcement required)

#### `scripts/restore-hot-cache.sh`  
- Identical to load-hot-cache.sh but with different marker text
- Triggered explicitly after context compaction
- Restores wiki fact context lost during compact

#### `scripts/check-wiki-changes.sh`
- Uses git diff --name-only HEAD | grep '^wiki/'
- Returns exit 0 if changes detected, 1 otherwise
- Outputs structured prompt to guide hot.md update at session end

### Phase 2: Initialize `wiki/hot.md`

Structure:
```markdown
# Wiki Hot Cache — Last Updated: YYYY-MM-DD

## Active Threads
- [Ongoing topic]: brief status

## Recent Changes  
- YYYY-MM-DD: Page X updated with Y
- YYYY-MM-DD: New page Z created

## Key Recent Facts
- Most important facts from recent updates (3-5 items)
```

### Phase 3: Update AGENTS.md — Add Section

Add new section after "🔧 Auto-Rebuild Metadata":
```markdown
## 🔁 Harness-Independent Session & Git Operations

### Bootstrap: Load Hot Cache
At session start → silently run:
```bash
bash scripts/load-hot-cache.sh || true   # no-op if vault absent
```
Agent reads output internally without announcement.

### After Write/Edit on Wiki Files  
After each write that touches wiki/ files:
```bash
bash scripts/git-auto-commit.sh
```
Never run `git add *` directly — the script stages only wiki/, .raw/, and .vault-meta/. It also respects wiki-lock concurrency checks.

### After Context Compaction
If context was compacted during a long session:
```bash
bash scripts/restore-hot-cache.sh || true
```
Compacted context discards injected content; this restores it.

### End of Session Hygiene  
Before ending a session where wiki work happened → check and update hot.md:
```bash
if bash scripts/check-wiki-changes.sh 2>/dev/null; then
  # Agent reads prompt output from script, updates wiki/hot.md accordingly
fi
```
If no changes detected, skip silently.

### Integration with Working Memory
- `working_memory.json` = session metadata (focus, next_steps) — already exists
- `wiki/hot.md` = fact context (recent wiki changes, active threads) — NEW addition
- Both co-exist: WM for agent state flow, hot.md for user knowledge continuity

### Concurrency Awareness
Before writing any wiki page:
1. Check if `scripts/wiki-lock.sh` exists
2. If yes → acquire lock before Write/Edit, release after
3. Skip auto-commit while locks active (another writer may be in-flight)

### Delta Tracking
Before ingesting new files → check `.raw/.manifest.json`:
- Hash match → skip, report "Already ingested"  
- No hash or missing → proceed with ingest + update manifest after
```

### Phase 4: Update Existing Skills

#### `process-ingest.json` — Add to step_3a / step_3b post_operations
After page creation/update → add:
```json
{
  "trigger": "page_created_or_updated",
  "command": "./scripts/git-auto-commit.sh",
  "note": "Harness-independent auto-commit for wiki changes"
}
```

#### `process-query.json` — Add to bootstrap section  
Add new step at query start:
```json
{
  "step": "bootstrap_hot_cache",
  "command": "./scripts/load-hot-cache.sh || true",
  "purpose": "Load recent wiki facts for context continuity"
}
```

#### `process-lint.json` — Add to lint_checks check_id_7 (after link_validation)
Add:
```json
{
  "check_id": "8",
  "name": "hot_cache_stale_check",
  "command": "./scripts/check-wiki-changes.sh || true"
}
```

### Phase 5: Update AGENTS.md — Add Compaction Rule

In the Memory Architecture Contract section, add:
```json
{
  "context_compaction_handling": {
    "rule": "After context compaction during long sessions → agent must call scripts/restore-hot-cache.sh to restore wiki fact context",
    "reason": "Compacted context discards injected content including hot.md",
    "trigger": "agent_detects_context_was_compacted"
  }
}
```

---

## 🛡 Compatibility Guarantees

### What this does NOT break:
- ✅ `working_memory.json` flow remains unchanged — co-exists with hot.md
- ✅ Existing scripts (wiki-lock.sh, raw-link-repair.sh, rebuild-meta.sh) are untouched  
- ✅ process-ingest.json post_operations already call rebuild-meta.sh + link-validator.sh; git-auto-commit adds to the chain
- ✅ process-query.json grep_contract remains unchanged; load-hot-cache is a new bootstrap step
- ✅ process-lint.json non-blocking model remains intact
- ✅ pre-commit hook continues blocking protected zones — git-auto-commit only stages wiki/.raw/.vault-meta/

### New constraints introduced:
- Agent must call `load-hot-cache.sh` at session start (new habit)
- Agent must call `git-auto-commit.sh` after wiki writes (new habit)  
- Agent must call `restore-hot-cache.sh` when detecting compaction (new habit)
- `wiki/hot.md` is a new file agent manages autonomously

### Conflict resolution:
- If git-auto-commit fails → skip silently, don't halt the pipeline
- If load-hot-cache returns 1 (no vault) → no-op, proceed normally
- If check-wiki-changes returns 1 → no changes detected, skip hot.md update silently

---

## ✅ Implementation Order

1. Create `scripts/git-auto-commit.sh` — core dependency for all others
2. Create `scripts/load-hot-cache.sh`, `scripts/restore-hot-cache.sh`, `scripts/check-wiki-changes.sh`
3. Initialize `wiki/hot.md` with initial content from current wiki state
4. Update AGENTS.md — add Harness-Independent Session & Git Operations section
5. Add to process-ingest.json post_operations (after page creation/update)
6. Add bootstrap step to process-query.json  
7. Add hot_cache_stale_check as check_id_8 in process-lint.json

---

## 📊 Success Criteria

| Criterion | How Measured |
|-----------|-------------|
| Auto-commit fires after wiki writes | git log shows commits without manual user intervention |
| Hot cache loads at session start | Agent reads hot.md content silently on each new session |
| Compaction recovery works | After compact, agent re-reads hot.md via restore script |
| No conflicts with existing processes | All three process files (ingest/query/lint) continue working without errors |
| Harness independence verified | Scripts work in Pi; same scripts would work identically in Claude Code or Codex |
