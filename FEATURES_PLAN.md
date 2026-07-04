---
tags: [feature-plan, ingest-architecture, research-followup]
date: 2026-07-04
type: documentation
category: note
sources: ["wiki/research/ingest-algorithms-comparison.md"]
related: []
---

# Features Plan — Ingest Architecture Improvements

Research-driven initiative based on **[ingest algorithms comparison](wiki/research/ingest-algorithms-comparison.md)**.

---

## 📍 Current Status

**Last updated**: 2026-07-04 | **Active phase**: Phase 1 (Critical fixes) | **Completed**: Advisory Locking ✅

---

## 📊 Priority Matrix

| Feature | Priority | Complexity | Impact | Status |
|---------|----------|------------|--------|--------|
| ~~Advisory Locking~~ | 🔴 Critical | Medium | Prevents silent corruption from parallel writes | ✅ **Implemented** (Phase 1) |
| Real-time Contradiction Flagging | 🟡 High | Low | Prevents silent overwrites (data loss prevention) | ⬜ Pending |
| Background Synthesis & Deterministic Commit | 🟠 High | Medium | Non-blocking ingest, better UX + testability | ⬜ Backlog |
| Mode-Aware Routing | 🟢 Medium | Low | Future-proof for PARA/LYT/Zettelkasten | ⬜ Backlog |
| Address Assignment System | 🟢 Low-Medium | Low-Medium | Stable identifiers across renames | ⬜ Backlog |

---

## 2️⃣ Real-time Contradiction Flagging — Prevent Data Loss

**Problem**: New info contradicts existing wiki pages → agent silently overwrites old facts (no audit trail).

**Solution**: Bidirectional `[!contradiction]` callouts added to BOTH pages.

### Implementation Plan

Modify `process-ingest.json#step_3_analysis`:
```json
{
  "action": "check_for_contradications",
  "rule": "NEVER silently overwrite conflicting facts — always add bidirectional callouts"
}
```

---

## 3️⃣ Background Synthesis & Deterministic Commit — Non-blocking Ingest

**Problem**: Synchronous ingest blocks user until pages are written.

### Implementation Plan

1. **Structured schema definition** → `scripts/synthesis-subagent.py` with structured tool validation
2. **Background sub-agent integration** → async task in process-ingest.json
3. **Deterministic persistence layer** → `scripts/deterministic-commit.py` (pure I/O writes)

---

## 4️⃣ Mode-Aware Routing — Dynamic Path Resolution

**Problem**: Ingest always writes to hardcoded folders; no support for PARA/LYT/Zettelkasten modes.

### Implementation Plan

1. Create `scripts/wiki-mode.py` with mode routing logic
2. Integrate into ingest flow (process-ingest.json → step_9_post_checks)
3. Document mode-specific behaviors in AGENTS.md

---

## 5️⃣ Address Assignment System — Stable Identifiers Across Renames

**Problem**: Page renames break cross-references; no stable identifier system.

### Implementation Plan

1. Create `scripts/allocate-address.sh` with atomic counter
2. Integrate into delta-tracking manifest (raw/.manifest.json)
3. Add address field to wiki page templates

---

## 📅 Implementation Roadmap

### Phase 1: Critical fixes (Immediate)
| Feature | Action | Effort |
|---------|--------|--------|
| ~~Advisory Locking~~ | ✅ Implemented | Low-Medium |
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

*Last updated: 2026-07-04 | Status: Advisory Locking ✅, pending approval for remaining features.*
