---
tags: [feature-plan, ingest-architecture, research-followup]
date: 2026-07-03
type: documentation
category: note
sources: ["wiki/research/ingest-algorithms-comparison.md"]
related: []
---

# Features Plan — Ingest Architecture Improvements

Research-driven initiative based on **[ingest algorithms comparison](wiki/research/ingest-algorithms-comparison.md)** — analysis of best practices from pi-llm-wiki, claude-obsidian, and other LLM wiki implementations.

---

## 📊 Priority Matrix

| Feature | Priority | Complexity | Impact | Status |
|---------|----------|------------|--------|--------|
| 1. Advisory Locking | 🔴 Critical | Medium | Prevents silent corruption from parallel writes | ⬜ Pending |
| 2. Real-time Contradiction Flagging | 🟡 High | Low | Prevents silent overwrites (data loss prevention) | ⬜ Pending |
| 3. Background Synthesis & Deterministic Commit | 🟠 High | Medium | Non-blocking ingest, better UX + testability | ⬜ Pending |
| 4. Mode-Aware Routing | 🟢 Medium | Low | Future-proof for PARA/LYT/Zettelkasten | ⬜ Backlog |
| 5. Address Assignment System | 🟢 Low-Medium | Low-Medium | Stable identifiers across renames | ⬜ Backlog |

---

## 1️⃣ Advisory Locking (wiki-lock.sh) — Prevent Silent Corruption

**Source**: `scripts/wiki-lock.sh` from [claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian/blob/master/scripts/wiki-lock.sh)

### Problem
Parallel writes to the same wiki page can silently corrupt content without any error messages.

### Solution
Per-file advisory locking with:
- **Noclobber atomic creation** (POSIX race-safe locks)
- **Age-based staleness**: crashed writer unblocks automatically after 60 seconds
- **Cross-process release**: simple `rm -f`, no PID tracking needed

### Implementation Plan

```bash
# Step 1: Copy wiki-lock.sh from reference implementation
cp /tmp/pi-github-repos/AgriciDaniel/claude-obsidian/scripts/wiki-lock.sh scripts/wiki-lock.sh

# Step 2: Integrate into ingest flow (process-ingest.json)
# Add acquire → write → release pattern before every page write
```

**Schema integration**: Modify `process-ingest.json` steps to wrap writes with:
```json
{
  "action": "acquire_lock",
  "tool_call": "bash scripts/wiki-lock.sh acquire wiki/entities/Person.md"
}
```

### Dependencies
- No external dependencies — single script, self-contained

---

## 2️⃣ Real-time Contradiction Flagging — Prevent Data Loss

**Source**: `skills/wiki-ingest/SKILL.md` from [claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian/blob/master/skills/wiki-ingest/SKILL.md)

### Problem
When new info contradicts existing wiki pages, agent silently overwrites old facts — no audit trail.

### Solution
Bidirectional `[!contradiction]` callouts added to BOTH pages:

```markdown
> [!contradiction] Conflict with [[New Source]]
> [[Existing Page]] claims X. [[New Source]] says Y.
> Needs resolution. Check dates, context, and primary sources.
```

### Implementation Plan

Modify `process-ingest.json#step_3_analysis`:
```json
{
  "action": "check_for_contradications",
  "output_format": {
    "on_existing_page": "> [!contradiction] Conflict with [[<new_source>]]\n- <existing claim>\n- <new claim>\n- Needs resolution.",
    "on_new_page": "> [!contradiction] Contradicts [[<existing_page>]]\n- This source says Y, but existing wiki says X."
  },
  "rule": "NEVER silently overwrite conflicting facts — always add bidirectional callouts"
}
```

### Dependencies
- Custom CSS snippet for `[!contradiction]` styling (optional, Obsidian fallback works)

---

## 3️⃣ Background Synthesis & Deterministic Commit — Non-blocking Ingest

**Source**: `extensions/llm-wiki/lib/ingest-worker.ts` from [pi-llm-wiki](https://github.com/zosmaai/pi-llm-wiki/blob/master/extensions/llm-wiki/lib/ingest-worker.ts)

### Problem
Current synchronous ingest blocks user until pages are written; LLM directly writes files (hallucination risk).

### Solution
1. **Sub-agent produces ONE structured tool call** (`commit_synthesis`)
2. **Deterministic persistence layer** writes files WITHOUT LLM involvement after structured output is produced
3. **Idempotent create-or-link**: `existsSync()` → link if present, create if absent

### Architecture

```bash
scripts/ingest-worker.sh --source "path/to/file.md"
├── extract-content.sh       # Parallel extraction from raw/
├── synthesis-subagent.py    # Background sub-agent with structured output
└── deterministic-commit.py  # Pure I/O persistence layer (no LLM)
```

### Implementation Plan

**Phase 1: Structured Schema Definition**
```json
{
  "schema": {
    "summary": {"type": "string", "minLength": 1},
    "key_takeaways": {"type": "array"},
    "entities": [{"title": string, "description": string}],
    "concepts": [{"title": string, "definition": string}]
  }
}
```

**Phase 2: Background Sub-agent Integration**
- Create `scripts/synthesis-subagent.py` with structured tool call validation
- Integrate into process-ingest.json as async task

**Phase 3: Deterministic Persistence Layer**
- Create `scripts/deterministic-commit.py` — pure I/O writes from structured output
- Unit-testable without LLM involvement

### Dependencies
- Python scripting infrastructure
- Structured tool validation (TypeBox or equivalent)

---

## 4️⃣ Mode-Aware Routing — Dynamic Path Resolution

**Source**: `scripts/wiki-mode.py` from [claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian/blob/master/scripts/wiki-mode.py)

### Problem
Ingest always writes to hardcoded folders; no support for PARA/LYT/Zettelkasten methodology modes.

### Solution
Single router script that returns vault-relative path based on mode:
```bash
python3 scripts/wiki-mode.py route entity "Andrej Karpathy"
# generic:      wiki/entities/Andrej-Karpathy.md
# lyt:          wiki/mocs/Karpathy-moc.md (atomic note + MOC update)
# para:         wiki/resources/people/Andrej-Karpathy.md
# zettelkasten: wiki/20260517123456-Andrej-Karpathy.md
```

### Implementation Plan

**Step 1**: Create `scripts/wiki-mode.py` with mode routing logic
**Step 2**: Integrate into ingest flow (process-ingest.json → step_9_post_checks)
**Step 3**: Document mode-specific behaviors in AGENTS.md

### Dependencies
- Python scripting infrastructure

---

## 5️⃣ Address Assignment System — Stable Identifiers Across Renames

**Source**: `scripts/allocate-address.sh` from [claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian/blob/master/scripts/allocate-address.sh)

### Problem
Page renames break cross-references; no stable identifier system.

### Solution
Atomic counter under exclusive flock assigns unique addresses (`c-000042`) to each page in frontmatter:
```markdown
---
address: c-000042  # ← Stable across renames!
title: Person Name
type: entity
---
```

### Implementation Plan

**Step 1**: Create `scripts/allocate-address.sh` with atomic counter
**Step 2**: Integrate into delta-tracking manifest (raw/.manifest.json)
**Step 3**: Add address field to wiki page templates

### Dependencies
- Bash flock for atomic counter increments

---

## 📅 Implementation Roadmap

### Phase 1: Critical fixes (Immediate)
| Feature | Action | Effort |
|---------|--------|--------|
| Advisory Locking | Copy script → integrate into ingest flow | Low-Medium |
| Contradiction Flagging | Modify process-ingest.json schema_refs | Low |

### Phase 2: High-impact improvements (Next Sprint)
| Feature | Action | Effort |
|---------|--------|--------|
| Background Synthesis | Create orchestrator scripts → sub-agent integration | Medium |
| Mode-Aware Routing | Create wiki-mode.py → integrate into routing | Low-Medium |

### Phase 3: Future-proofing (Backlog)
| Feature | Action | Effort |
|---------|--------|--------|
| Address Assignment System | Create allocate-address.sh → delta-tracking integration | Low-Medium |

---

## 📊 Success Metrics

| Metric | Current State | Target State |
|--------|---------------|--------------|
| Silent corruption incidents | Unknown (no protection) | 0 (advisory locks prevent races) |
| Silent overwrite rate | High | 0 (contradiction callouts required) |
| User stall time during ingest | ~5s per page | 0s (background synthesis) |
| Methodology mode support | None | Full (generic/lyt/para/zk) |
| Cross-reference breakage on rename | High | 0 (stable addresses) |

---

## 🔗 References & Sources

- **Primary research**: [ingest-algorithms-comparison.md](wiki/research/ingest-algorithms-comparison.md) — detailed analysis of all features with code examples and comparisons
- **Advisory locking**: `scripts/wiki-lock.sh` from [claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian/blob/master/scripts/wiki-lock.sh)
- **Background synthesis**: `extensions/llm-wiki/lib/ingest-worker.ts` from [pi-llm-wiki](https://github.com/zosmaai/pi-llm-wiki/blob/master/extensions/llm-wiki/lib/ingest-worker.ts)
- **Contradiction flagging**: `skills/wiki-ingest/SKILL.md` from [claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian/blob/master/skills/wiki-ingest/SKILL.md)
- **Mode routing**: `scripts/wiki-mode.py` from [claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian/blob/master/scripts/wiki-mode.py)
- **Address assignment**: `scripts/allocate-address.sh` from [claude-obsidian](https://github.com/AgriciDaniel/claude-obsidian/blob/master/scripts/allocate-address.sh)

---

*Last updated: 2026-07-03 | Status: Research-driven, pending approval for implementation*
