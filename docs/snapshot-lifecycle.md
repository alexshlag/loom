# Snapshot Lifecycle & Active Projects Tracking in Loomana

This document describes `wiki/snapshot.md` — a one-page active context tracker that maintains a current view of ongoing projects, their status, and related wiki pages. It provides cross-session continuity for multi-project workflows without bloating the agent's working memory with unnecessary details.

---

## Overview: What Is Wiki Snapshot?

`wiki/snapshot.md` is a **living project register** — a single markdown file that summarizes all active projects currently tracked by the wiki system. It sits at `wiki/snapshot.md` and is read/written by the agent during project-mode sessions.

### Why It Exists

The working memory (`working_memory.json`) stores turn-to-turn context (focus_node, open_pages), but it's too granular for multi-project overviews. The snapshot provides:

- **High-level status** of all active projects in one place
- **Cross-session continuity** — next bootstrap can read snapshot to understand what was happening
- **Reduced context bloat** — agent doesn't need to hold full project details in WM; it reads only what's relevant from snapshot

### When It's Read vs Ignored

```yaml
# rules/snapshot_format.json load_conditions:
read_when: "WORK_MODE is project AND snapshot contains entry for this project"
never_read: [
    "oneoff questions",              # Not needed — query mode reads wiki/index.md + recall.sh
    "deep-dive study (query/discussion modes)"  # Snapshot is about projects, not topics
]
```

**Rule:** Agent never loads `wiki/snapshot.md` unless the user explicitly switches to project mode or the session context indicates ongoing multi-project work. For one-off queries or deep-dives on a single topic, snapshot is irrelevant and skipped.

---

## Snapshot Format Structure

### Frontmatter (Universal)

```yaml
---
tags: [snapshot, active-projects]
date: YYYY-MM-DD                   # Current system date, not project-specific
type: documentation                # Always documentation — it's a meta page
category: note                     # Meta category — not entity/concept/synthesis
aliases: []                        # Discoverability synonyms (e.g., "status", "projects")
sources: []                        # Data origins — usually empty or references to process files
related: []                        # Links to wiki pages related to active projects
---
```

### Body Structure

```markdown
# Wiki Snapshot — Active Projects

## Active Projects

### [Project Name]
- **Статус**: active | completed | on-hold
- **Контекст**: Brief description of project goal and current status
- **Связанные wiki-страницы**:
  - `[[wiki/concepts/related-page.md]]` — page name + one-line relevance note

---

*Last updated: YYYY-MM-DD*
```

**Rules for each entry:**
1. Status is always one of: `active`, `completed`, or `on-hold`
2. Context must be ≤3 sentences — no deep dives; see wiki pages for details
3. Related pages are links to actual wiki content that the project depends on or produces
4. Completed projects are **removed from snapshot** (see lifecycle below)

### Example Entry

```markdown
### Управление памятью и контекстом ИИ-агента (Memory Architecture)
- **Статус**: active
- **Контекст**: Интегрируем working_memory.json, CONTEXT_BUBBLE, Grep Contract. Цель: оптимизация памяти без потери важного контекста.
- **Связанные wiki-страницы**:
  - `[[wiki/concepts/llm-wiki.md]]` — incremental knowledge base building через LLM.
  - `[[wiki/syntheses/rag-vs-llm-wiki-pattern.md]]` — comparison of standard RAG with compounding KB pattern.

### Harness-Independent Session & Git Operations (Phase 5)
- **Статус**: completed (2026-06-28)
- **Контекст**: Интегрировали 4 скрипта для автономной работы без зависимости от harness...
```

---

## Lifecycle: Create → Update → Archive

### Creation Trigger

When the user declares a new project or the agent detects multi-project context:

```bash
# Agent creates snapshot.md if it doesn't exist (rare — usually exists)
cat >> wiki/snapshot.md <<EOF
### [Project Name]
- **Статус**: active
- **Контекст**: Brief goal description...
- **Связанные wiki-страницы**:
  - [[wiki/related-page.md]] — relevance note
EOF

# Updates frontmatter date automatically (current system date)
```

**Decision logic:** Before creating a new entry, agent checks:
1. Does snapshot.md already exist? → Append to existing file
2. Is the project name unique? → If duplicate name exists → append "(Phase X)" suffix or merge context into existing entry

### Update Trigger

Every time an ingest or query operation adds/changes related wiki pages:

```yaml
# rules/snapshot_format.json update_rules:
update_trigger: "every ingest/query that adds or changes related wiki pages"
action: "Update context description + add/remove related_pages entries"
```

**What gets updated:**
- **Context field**: New information about current status → replace old text with latest state
- **Related pages**: Add new links to created/updated wiki pages; remove stale references
- **Frontmatter date**: Always set to current system date (never use source dates — `rules/date_convention.json`)

**When NOT to update:** Query operations that don't create or modify wiki pages → snapshot stays unchanged. Only content-producing operations trigger updates.

### Archive Trigger

When a project is completed:

```yaml
# rules/snapshot_format.json update_rules:
archive_trigger: "project completed — entry moved to wiki/projects/, removed from snapshot.md"
```

**Archive process:**
1. Entry is **removed entirely** from `wiki/snapshot.md` (not marked as archived)
2. If the project generated wiki pages, those pages remain in their categories (entities/concepts/syntheses/) — they're not deleted
3. The project itself may be moved to `wiki/projects/` if it has dedicated documentation

**Why remove instead of archive-in-place?** Keeping completed projects in snapshot causes clutter and false sense of ongoing relevance. Completed = no longer active context → clean removal preserves signal-to-noise ratio.

---

## Reading Snapshot: How the Agent Uses It

### Session Bootstrap Integration

Snapshot is read as part of session bootstrap (`session_bootstrap.json`), but **only conditionally**:

```bash
# Step 1-2 (always): Read working_memory.json + wiki/hot.md
read working_memory.json
read wiki/hot.md

# Step 3 (conditional): Read snapshot only if relevant
if [[ "$CURRENT_MODE" == "project" ]]; then
    # Check if any entry matches current focus_node or active_project
    grep -m 5 'focus_keyword' wiki/snapshot.md | head -20 || true
fi
```

**Never read entire snapshot.** Only grep for keywords relevant to current session context. The file can grow over time (multiple projects), so full reads waste tokens.

### Context Bubble Integration

When agent reads snapshot entries:
- Max 3 wiki pages in context bubble per `session_context_rules.json#operational_rules`
- Snapshot provides the **high-level overview**; actual page reading happens via grep/fetch on related wiki paths from snapshot's `related:` field

---

## Relationship With Other Memory Layers

### vs Working Memory (WM)

| Aspect | WM (`working_memory.json`) | Snapshot (`wiki/snapshot.md`) |
|--------|---------------------------|------------------------------|
| **Scope** | Single session, turn-to-turn | Multi-session, project-level |
| **Detail level** | Granular (current focus, open pages) | High-level (status, context summary) |
| **Read frequency** | Every turn | Only when entering project mode |
| **Write trigger** | After every action | After content-producing operations only |

Snapshot is the **bridge between sessions for project tracking**; WM is the **operational memory within a single session**. They complement each other: snapshot tells you "what projects are active," WM tells you "where we're at right now."

### vs Hot.md (`wiki/hot.md`)

Hot.md aggregates WM content and provides next-session bootstrap data. Snapshot sits alongside hot.md but serves a different purpose:
- **Hot.md**: Session continuity — "where was I?" (focus_node, pending_tasks)
- **Snapshot**: Project registry — "what projects exist and their status"

Both can be read during bootstrap; agent chooses which based on current mode.

### vs Log.md (`wiki/log.md`)

Log.md is the chronological chronicle of all actions. Snapshot is a **curated summary** — only active/completed projects with human-readable context, not raw action logs. They're complementary: log.md for audit trail, snapshot for project overview.

---

## Maintenance & Cleanup

### Staleness Check

If `wiki/snapshot.md` hasn't been updated in >30 days (check `last_updated` date), agent treats it as stale and suggests regeneration:
```bash
# Check if snapshot is stale (>30 days)
if [[ $(date -d "$(grep 'Last updated:' wiki/snapshot.md | cut -d' ' -f4)" +%s) -lt $(date -d "today" +%s) ]]; then
    echo "[!] Snapshot appears stale — consider regenerating from recent log entries" >&2
fi
```

### Cleanup Triggers

The agent runs snapshot cleanup periodically (during lint or batch operations):
1. **Remove completed projects** → archived as described above
2. **Merge duplicate project names** → if two entries for same topic, combine their context
3. **Verify related pages exist** → check that linked wiki pages still exist; remove broken references

### Grep Contract (Safe Reading)

When reading snapshot:
```bash
# ✅ Allowed: grep with -m flag to limit output
grep -m 5 'keyword' wiki/snapshot.md | head -20

# ❌ Prohibited: cat entire file or grep without -m
cat wiki/snapshot.md          # Can be large over time → token waste
grep 'pattern' wiki/snapshot.md   # No -m flag → could output all entries
```

---

## Quick Reference Commands

| Action | Command | Notes |
|--------|---------|-------|
| View current snapshot | `cat wiki/snapshot.md` (manually) or read via agent grep | Full file only for manual review, not by agent in sessions |
| Check staleness | Compare date from "Last updated" line with today's date | >30 days → stale |
| Add project entry | Agent appends via `cat >> wiki/snapshot.md` during ingest/query | Never overwrite — always append or rewrite complete file |
| Remove completed entry | Rewrite snapshot without the completed section | Use sed/grep to filter out old entries before writing back |

---

## Summary

Wiki snapshot lifecycle in Loomana:

1. **Create** → when user declares a new project or multi-project context detected; written with status (active/completed/on-hold), brief context, related wiki pages
2. **Update** → after every content-producing operation that adds/modifies wiki pages; replaces old context text, updates date to current system date, adjusts related pages list
3. **Archive** → when project completes: entry removed entirely from snapshot; related wiki pages stay in their categories (not deleted); project may move to `wiki/projects/` if it has dedicated docs

Reading rules: only loaded during project-mode sessions; never for oneoff queries or deep-dives; use grep with `-m N` flag — never cat entire file. Complements WM and hot.md by providing cross-session project overview without context bloat.

For format spec details: read `rules/snapshot_format.json`. For bootstrap integration: see `session_bootstrap.json#snapshot_load_conditions`.