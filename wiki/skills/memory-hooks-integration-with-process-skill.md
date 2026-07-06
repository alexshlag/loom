---
tags: [skill, memory, skill-process]
date: 2026-07-06
name: memory-hooks-integration-with-process
description: Extract reusable process hook patterns from trajectories and integrate them into ingest/query/lint workflows.
type: documentation
category: note
aliases: []
sources: ["raw/trajectories/TRJ-20260706-0653-fcc8626d"]
related_docs: []
---

# Skill: Memory Hooks Integration With Process

## Procedure
- read: OK | edit: REQUIRED | write: NEVER

## Algorithm
1. **Identify process workflow** — check if current operation (ingest/query/lint) has memory hooks defined in its steps
2. **Check existing hooks**: `grep -r "memory_hooks" process-*` → verify integration points
3. **Distill pattern**: Extract reusable hook logic from trajectory → create wiki/skills/<name>.md with Algorithm section
4. **Update process files**: Add schema_ref to rules/skill_format.json, integrate memory hooks into appropriate step
5. **Validate**: Run `lint.sh` → ensure no structural violations

## Context
- Trigger: Pattern found in distillation pipeline from trajectory capture
- Outcome: success
- Complexity: medium

## Dependencies
- rules/skill_format.json (SKILL-FORMAT-V1) — format specification
- process-ingest.json — ingest workflow with memory hooks integration step

## Notes
- Distilled from trajectory "TRJ-20260706-0653-fcc8626d".
- Timestamp: 2026-07-06T06:53:13+0300
