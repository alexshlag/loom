# CODE DEVELOPMENT SYSTEM REGULATION (FOR AI AGENT)

## 1. FUNDAMENTAL PRINCIPLES
* **KISS:** The simplest solution. No super-architecture needed.
* **DRY:** Do not duplicate logic — extract to functions/modules.
* **YAGNI:** Implement only what is requested. No "for the future."
* **Single Responsibility:** One module = one task.

## 2. READABILITY & STYLE
* Meaningful names in English (no `a`, `b`).
* Official language style guide (PEP 8, effective Go, TS guidelines).
* Minimal comments — code is self-documenting. Bash/awk/jq: "what it does" comments mandatory at beginning and on complex pipes.

**AGENT INSTRUCTION LANGUAGE:** All agent instructions for wiki (process files, rules/*.json, AGENTS.md) must be written **only in English**. File names, variables, comments — in English. Exception: wiki page content may be in any language.

**SCRIPT COMMENTS:** All script code and comments (**every `.sh` file**) must use English exclusively. This matches the instruction language rule above — no Russian/other-language comments anywhere in scripts.

## 3. RELIABILITY
* Validate all external data (null/undefined checks).
* Explicit error handling — never swallow exceptions.
* Pure functions, minimize side effects.

## 4. OUTPUT FORMAT
* Only working code — no "fluff."
* No stubs `// logic goes here`.
* Brief explanation only for key architectural decisions.

## 5. SCRIPT ARCHITECTURE (JSON & LLM-WIKI)
* JSON parsing → `jq`, Markdown → `awk/sed/grep` in separate scripts, not in prompts.
* Idempotency — re-running does not duplicate entries.
* Every script: `set -euo pipefail`, paths quoted.

## 6. LINT AUTOMATION
* Input data validation → exit code >0 on error (so agent can fix).
* Atomic write: `.tmp` + `mv` only on success.
* Smart search: Bash script with built-in Regex-injection cleanup, not AI-driven.

## AUTOMATION RULE (TRANSFER TO BASH)
* Every task → separate Bash script with arguments and exit code.
* Logging: clear messages "Error in line X: JSON format."
* `--help` in every script for quick flag recall.

## 7. FIX PRINCIPLE — Fix tools, not documents
Wiki bugs → fixed in `scripts/` and instructions, not in `wiki/**`. Contradictory data = symptom of process error (ingest/query/lint). Wiki page rewritten only if source changed.

## 8. SCHEMA REF OPTIMIZATION — Link optimization

`process-*.json` instructions reference rules via `schema_ref`. Broken links → fix per algorithm:

### Fix Algorithm
1. **Search in `rules/*.json`** — rule may have been moved but link not updated.
2. **Intelligent matching**: keywords + semantics (not just exact matches).
3. **If not found:**
   - Implemented in script → **remove link** (script is self-documenting)
   - Used repeatedly → **create `rules/<name>.json`** + `schema_ref`
   - Single-use rule → **write inline**, do not remove

### Examples and practice: `rules/schema-ref-examples.md`

## 8.1 GIT WORKFLOW — Commit after task

After completing a task:
1. Verify wiki functionality
2. **Update dev documents:**
   - `issues.md` → fully close resolved bugs, leave only open + current ones
   - `PLAN.md`, `FEATURES_PLAN.md` → update phase statuses, mark current task
3. **Git commit:**
   ```bash
   git add -A && git commit -m "<type> | <scope>: <description>"
   ```

**Commit format:** `<type> | <scope>: <description>` (type: feat|fix|refactor|schema|lint|ingest|query)

## 9. INSTRUCTION COMPACTIFICATION — Conciseness without losing logic

LLM agent has limited context window. Every token competes with real data.

**R01: Do not duplicate existing rules (schema_ref)**
Exists in `rules/` → use `schema_ref`. Writing full description inline is prohibited if file exists.

**R02: Do not repeat the same meaning**
Each rule written ONCE. name/description/instruction say one thing — remove duplication. Different aspects (what/constraints/examples) — this is multi-layer spec, not duplicate.

**R03: Minimal context without losing logic**
Remove verbose lists (>5 → move to `rules/`). Examples and edge cases → in process files or `rules/`. Default assumption: agent already knows basic concepts.

**R04: Process-specific details → process files (progressive disclosure)**
Instructions for specific process → corresponding `process-*` file. AGENTS.md → only schema_ref, not full descriptions.

**R05: Contracts → AGENTS.md, examples → references/**
Mandatory rules (output contracts, validation) — in AGENTS.md. Examples and edge cases → in `rules/`. Check: "If agent forgets this rule, what breaks?" → critical = AGENTS.md.

**R06: Most important last (recency bias)**
Critical contracts ("never do X") should be at end of document or before them — LLM remembers last elements better.

**🚨 R07: EXAMPLES AS CONDITIONAL LOGIC — NEVER REMOVE WITHOUT AUDIT**
Examples/edge cases in JSON instructions often work as `if-else` construct:
```
{
  "when": "conflicting_priorities OR multiple_live_state",
  "action": "create_comparison_page_for_complex_conflicts"
}
```
This is NOT meta-information — it is **conditional behavior specification**. Agent uses this logic at runtime.

**Rules:**
1. Before removing example/edge case → check: does it form part of `when/action` or `if/then` logic?
2. If example describes situation → behavior ("if X, then Y") → **DO NOT REMOVE**. This is conditional logic.
3. If example — just illustration without affecting agent behavior → can be removed.
4. Skepticism: if in doubt — keep and add `schema_ref` to description instead of removing.

**Strictly prohibited:** removing examples from `resolution_actions`, `fallback_chain`, `constraints`, `arbitration_layer` without auditing their role in conditional flow.

## 10. Development Success Check - Fulfillment of Wiki Workflow Conditions

1. Agent does not perform tasks in `wiki` outside of wiki instructions;
2. Role separation principle maintained: ingest | query | lint;
3. All logical connections and transitions between roles ensured — before completing any instruction and receiving expected result.
4. No gaps and/or conflicts in instructions — agent doesn't need to wonder: "what to do in this situation"

## 11. TASK EXECUTION CYCLE — Problem → Plan → Implement → Verify → Document → Git

**Workflow for any non-trivial change:**

```
1. PROBLEM IDENTIFIED → documented in issues.md (or new issue created)
2. DISCUSSION → agent proposes solution, user approves approach
3. PLAN CREATED → explicit steps in PLAN.md with dependencies, priorities, expected outputs
4. IMPLEMENTATION → execute plan tasks one by one, validate after each step
5. VERIFICATION → test functionality, check no regressions, run existing checks (lint/shellcheck)
6. DOCUMENT UPDATE → refresh issues.md (close resolved), update PLAN.md (mark done), update AGENTS.md if needed
7. COMMIT & SYNC → git_conventions.json#pre_commit_workflow + memory_sync_on_dev_commit
```

**Critical rules:**
- Never implement without plan (unless trivial one-liner)
- Never update documentation after implementation — must be step 6, before commit
- Never skip verification — test on real data before committing
- Commit & memory sync via git_conventions.json (never duplicate logic)
