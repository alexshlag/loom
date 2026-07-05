# Hot Cache Update Spec — Check-Only Mode Optimization

**Target**: `scripts/memory/hot-cache-update.sh`  
**Phase**: Phase 16.1, Task #4 (hot cache optimization)  
**Goal**: Skip unnecessary hot.md rebuilds when wiki hasn't changed between sessions.

---

## Problem

`load-hot-cache.sh` runs on every session start — reads all wiki files → context bloat from unnecessary I/O.

## Solution

Check-only mode: compare timestamps of wiki .md files vs `hot.md` mtime. Skip rebuild if no changes detected.

### Algorithm

1. Get `hot.md` modification timestamp (epoch seconds)
2. Find all `.md` files in `wiki/` EXCEPT `hot.md` itself
3. Track the most recent file mtime among those
4. If latest_mtime > hot_mtime → "changes detected" → exit 1, trigger rebuild  
5. Otherwise → "no changes" → exit 0, skip reload

### Integration

**Before:** `./scripts/load-hot-cache.sh || true` — always runs  
**After:** `./scripts/memory/hot-cache-update.sh --check-only || ./scripts/load-hot-cache.sh` — check first, load only if needed

### Output Format (stderr)

```
[*] HOT CACHE STALE: wiki files modified since last session (2026-07-06 02:36)
[✓] HOT CACHE FRESH: no wiki changes since 2026-07-06 02:34
[*] HOT CACHE FORCED: rebuilding regardless of timestamp
```

### Exit Codes

| Code | Meaning | Action |
|------|---------|--------|
| 0    | No changes detected | Skip reload (silent) |
| 1    | Changes detected or --rebuild flag | Trigger rebuild via load-hot-cache.sh |

---

## Success Criteria

1. ✅ Check-only mode works — detects file modifications correctly  
2. ✅ Excludes hot.md from comparison (avoids self-referential max mtime issue)  
3. ✅ process-query.json step_0.25 uses check-only first, loads only on changes  
4. ✅ --rebuild flag forces exit 1 regardless of timestamps
