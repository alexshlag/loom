# Trajectory Capture Spec — Session Recording → Distillable Artifacts

**Target**: `scripts/memory/traj-capture.sh`  
**Phase**: Phase 16.1, Task #6: Trajectory capture system  

---

## Problem Statement

Agent experience is ephemeral — tool-call sequences, user interactions, and outcomes are lost after session ends. No systematic way to record or reuse agent expertise.

## Solution: Trajectory Logging

Record raw tool-call sequences as immutable artifacts → distill into reusable skills/cases.

### Data Model

```json
{
  "id": "TRJ-20260706-1430-abc",
  "timestamp": "YYYY-MM-DDTHH:MM:SS+TZ",
  "prompt": "User task description",
  "tool_calls": [
    {"name": "read", "path": "...", "is_error": false},
    {"name": "edit", "path": "...", "is_error": false}
  ],
  "outcome": "success | partial | failure",
  "complexity": "low | medium | high"
}
```

### Directory Structure

```
raw/trajectories/
├── index.log                    # Append-only log of trajectory IDs
├── TRJ-{timestamp}-{random}/    # Per-trajectory directory
│   ├── packet.json              # Full sequence (immutable)
│   └── extracted.md             # Human-readable summary
```

### Usage from Process Hooks

**In `process-query.json`:**
- Trigger: `on_search_complete` → capture if `compounding_flagged OR task_complexity >= medium`
- Command: `./scripts/memory/traj-capture.sh --prompt "<query>" --steps "<tool_calls>" --outcome "success" --complexity "medium"`

**In `process-ingest.json`:**
- Trigger: `on_ingest_complete` → capture if `new_page_created OR page_updated`
- Command: Same as above, with complexity="high" for ingest tasks.

### Quality Gates (from design document)

| Criterion | Check | Implementation |
|-----------|-------|----------------|
| **Full Coverage** | All effective steps captured in pattern | `packet.json` → `extracted.md` comparison |
| **Frequency Awareness** | Patterns covering more cases get priority | Track trajectory reuse count in metadata |
| **Procedure over Outcome** | Describes procedure, not just result | Distillation script checks for procedural content |
| **Cross-task Generalization** | Works for similar tasks, not just one | Test against 2+ existing wiki scenarios |

---

## Complexity Thresholds

Trajectories are captured based on complexity classification:

| Level | Criteria | Captured? |
|-------|----------|-----------|
| low | Single tool call or trivial read-only operation | ❌ No (unless explicitly requested) |
| medium | ≥2 steps with meaningful reasoning, some conditional logic | ✅ Yes |
| high | Multi-step workflow, user interaction, page creation/update | ✅ Always |

---

## Distillation Integration

Trajectories feed into the distillation pipeline (`scripts/memory/distill.sh`):

```
raw/trajectories/TRJ-* → packet.json + extracted.md
    ↓ (distill.sh reads and analyzes)
wiki/skills/*.md OR wiki/cases/*
    ↓ (via generate_skill_template / generate_case_template)
crosslinks added to related pages
```

**Trigger conditions:**
- Skill: Trajectory has ≥3 tool calls AND successful outcome → `wiki/skills/`
- Case: Trajectory has failure + analysis → `wiki/cases/`

---

## Success Criteria

1. ✅ Trajectories recorded with consistent format (packet.json + extracted.md)  
2. ✅ Complexity classification works for filtering trivial operations  
3. ✅ Distillation pipeline can extract reusable patterns from trajectories  
4. ✅ Duplicate detection prevents redundant skill/case pages  
