---
tags: [cli, agent-tools, development-workflow, skill-system]
date: 2026-07-07
type: documentation
category: docs
aliases: [ai-factory, aif]
sources:
  - web_search
related:
  - entities/ai-factory
  - concepts/workflow-state-machine
---
- [[wiki/concepts/ai-factory-vs-pi.md]] (score: 4)
- [[wiki/entities/ai-factory.md]] (score: 5)

# AI Factory Documentation — CLI Tool & Skill System for Coding Agents

> Brief intro paragraph defining scope, audience, and purpose — 2-3 sentences in plain language.

AI Factory is a **stack-agnostic** CLI tool that orchestrates AI coding agents (Claude Code, Codex, Cursor, etc.) with structured workflows: explore → plan → implement → verify → commit. It downloads and secures skills from [skills.sh](https://skills.sh), configures MCP servers automatically, and enforces quality gates throughout the development lifecycle. This page covers installation, core commands, reflex loop architecture, and extension system.

[Back to Index](../docs-index.md)

## What Is AI Factory?

AI Factory is a **stack-agnostic** CLI tool that works with any language, framework, or platform:

1. **Analyzes your project** — understands codebase structure and conventions
2. **Installs relevant skills** — downloads from [skills.sh](https://skills.sh) or generates custom ones via `/aif-skill-generator`
3. **Configures MCP servers** — GitHub, Postgres, Filesystem, Playwright based on your needs
4. **Provides spec-driven workflow** — structured feature development with plans, tasks, and commits

### Supported Agents

| Agent | Config Directory | Skills Directory |
|-------|-----------------|-----------------|
| Claude Code | `.claude/` | `.claude/skills/` |
| Cursor | `.cursor/` | `.cursor/skills/` |
| Windsurf | `.windsurf/` | `.windsurf/skills/` |
| Roo Code | `.roo/` | `.roo/skills/` |
| Kilo Code | `.kilocode/` | `.kilocode/skills/`, `.kilocode/workflows/` |
| Antigravity | `.agent/` | `.agent/skills/`, `.agent/workflows/` |
| OpenCode | `.opencode/` | `.opencode/skills/` |
| Warp | `.warp/` | `.warp/skills/` |
| Zencoder | `.zencoder/` | `.zencoder/skills/` |
| Codex CLI | `.codex/` | `.codex/skills/` |
| GitHub Copilot | `.github/` | `.github/skills/` |
| Gemini CLI | `.gemini/` | `.gemini/skills/` |

When Claude Code is selected, AI Factory installs bundled Claude agent files into `.claude/agents/`. When Codex CLI is selected, it also bundles native TOML agent files. MCP configuration supports most agents; Universal writes standard MCP settings to `.mcp.json`.

## Getting Started

### Installation & First Project

```bash
# 1. Install AI Factory globally
npm install -g ai-factory

# 2. Navigate to your project
cd my-project

# 3. Initialize — pick agents, install skills, configure MCP
ai-factory init
# Or non-interactively:
ai-factory init --agents claude,codex --mcp github,playwright

# 4. Open AI agent and run:
/aif
# Codex CLI/App use: $aif

# 5. Optional discovery before planning
/aif-explore Add user authentication with OAuth

# 6. Start building
/aif-plan Add user authentication with OAuth
```

### Upgrade from v1 to v2

Run `ai-factory upgrade` to migrate old bare-named skills (`commit`, `feature`) to `aif-*` names. Custom skills are preserved.

## Core Workflow Skills

The repeatable development loop forms the core workflow:

| Command | Use Case | Creates Branch? |
|---------|----------|-----------------|
| `/aif-explore` | Discovery, option comparison before planning | No |
| `/aif-grounded` | Evidence-only answers, strict verification | No |
| `/aif-plan fast` | Small tasks, quick fixes | No |
| `/aif-plan full` | Full features, stories (branch optional) | Optional |
| `/aif-improve` | Refine plan with deeper analysis | No |
| `/aif-loop` | Iterative quality loop with phase-based cycles | No |
| `/aif-implement` | Execute the plan step by step | No |
| `/aif-verify` | Post-implementation quality check | No |
| `/aif-fix` | Bug fixes, errors, hotfixes | No |
| `/aif-evolve` | Self-improve skills based on project experience | No |

### `/aif-explore [topic]` — Discovery Before Planning

Thinking-partner mode for exploring ideas, constraints, and trade-offs without implementing code. Reads the resolved description, architecture, rules, and research artifacts plus active plan files for context.

```bash
/aif-explore real-time collaboration
/aif-explore add-auth-system
```

### `/aif-grounded [question]` — Certainty Before Action

Reliability gate that prevents guessing: only provides answers when confidence is **100/100** based on evidence. Returns `INSUFFICIENT INFORMATION` if gaps exist.

```bash
/aif-grounded Does this repo support feature flags?
```

### `/aif-plan [fast\|full] <description>` — Plan the Work

Two modes:
- **Fast**: no git branch, saves to `.ai-factory/PLAN.md`, asks fewer questions
- **Full**: creates plans in `paths.plans/<branch-or-slug>.md`, optionally creates git branches

Plan file structure includes `Original Request`, `Research Context`, commit checkpoints, and task dependencies.

```bash
/aif-plan fast Add product search API
/aif-plan full Add user authentication with OAuth
/aif-plan full --parallel Add Stripe checkout  # Parallel worktrees
```

### `/aif-improve [--list] [+check] [@plan-file]` — Refine the Plan

Second-pass analysis that finds missing tasks, fixes dependencies, and removes redundant work. Shows improvement report before applying changes.

```bash
/aif-improve                                    # Auto-review gaps
/aif-improve +check                             # Validate via fresh-context subagent
/aif-improve @my-custom-plan.md                 # Improve explicit plan file
```

### `/aif-loop [new\|resume\|status]` — Reflex Loop

Strict iterative workflow with 6 phases: PLAN → PRODUCE||PREPARE → EVALUATE → CRITIQUE → REFINE. Uses weighted rules, quality gates, and persistable state in `paths.evolution/`.

```bash
/aif-loop new OpenAPI 3.1 spec + DDD notes
/aif-loop resume
/aif-loop status
```

Default `max_iterations` is 4. Stops on threshold reached, no major issues, iteration limit, stagnation, or user stop.

### `/aif-implement [--list] [@plan-file]` — Execute the Plan

Executes tasks one by one with commit checkpoints. Reads skill-context rules first, uses limited recent patch fallback when needed. Handles dependency graphs and parallel task execution via worktrees.

```bash
/aif-implement        # Continue from where you left off
/aif-implement --list # Show available plans only
/aif-implement 5      # Start from task #5
```

### `/aif-verify [--strict]` — Check Completeness

Optional step after `/aif-implement`. Goes through every task in the plan and verifies code actually implements it. Checks build, tests, lint, looks for TODOs, undocumented env vars.

### `/aif-fix [bug description]` — Bug Fixes

Investigates root cause, applies fix with logging (`[FIX]` prefix), creates self-improvement patches in `paths.patches/`. Follows Canonical Regression-First Policy before implementation.

## Quality Gates & Verification

AI Factory appends machine-readable JSON blocks to gate outputs for automated parsing:

```aif-gate-result
{
  "schema_version": 1,
  "gate": "verify",
  "status": "fail|warn|pass",
  "blocking": true,
  "blockers": [...],
  "affected_files": ["src/example.ts"],
  "suggested_next": {
    "command": "/aif-fix"
  }
}
```

Supported gates: `/aif-verify`, `/aif-review`, `/aif-security-checklist`, `/aif-rules-check`.

## Plan Files & Artifact Management

Plans are tracked in markdown files with lightweight YAML frontmatter metadata:

```markdown
---
id: spec-auth-login
type: spec
status: accepted
depends_on: [adr-auth-session]
affects: [plan-auth-login, docs-auth]
---
```

**Archive lifecycle**: `/aif-archive` moves completed plans to `.ai-factory/archive/plans/`. Plans with `workflow.plan_id_format: sequential` get 4-digit prefixes (`NNNN_<stem>.md`).

## Reflex Loop Architecture

The reflex loop uses **subagents** for Claude Code and Codex CLI. Each subagent has a narrow responsibility:

### Subagent Roles

| Agent | Purpose | Model |
|-------|---------|-------|
| `plan-coordinator` | Iterate critique→improve loop until plan passes | `inherit` |
| `plan-polisher` | Create/refine one implementation plan | `inherit` |
| `implement-coordinator` | Parse dependency graph, dispatch workers | `inherit` |
| `implement-worker` | Execute one bounded task in isolation | `inherit` |

### Quality Sidecars

Read-only background workers for the implementation coordinator:
- `best-practices-sidecar` — maintainability audit
- `commit-preparer` — commit-readiness check
- `docs-auditor` — documentation drift audit
- `review-sidecar` — correctness review
- `security-sidecar` — security review

### Loop Phases & Subagent Mapping

| Phase | Subagent |
|-------|----------|
| PLAN | `loop-planner` (haiku) |
| PRODUCE | `loop-producer` (inherit) |
| PREPARE | `loop-test-prep`, `loop-perf-prep`, `loop-invariant-prep` (haiku) |
| EVALUATE | `loop-evaluator` (inherit) |
| CRITIQUE | `loop-critic` (sonnet) |
| REFINE | `loop-refiner` (inherit) |

## Skill System & Evolution

### How Skills Work

1. **Search** `npx skills search <name>` on [skills.sh](https://skills.sh)
2. **Install** `npx skills install --agent <agent> <name>`
3. **Security scan** → two-level scanning before use (see Security section below)
4. **Generate custom skills** via `/aif-skill-generator`

### Self-Improvement Loop (`/aif-evolve`)

Every bug fix creates a **patch**. `/aif-evolve` reads patches incrementally and turns recurring patterns into skill-context rules:

```
/aif-fix → finds bug → fixes it → creates patch → /aif-evolve distills new rules → smarter future runs
```

**Skill-Context**: Project-specific overrides in `.ai-factory/skill-context/<skill>/SKILL.md` that survive `ai-factory update`. Higher priority than base rules.

## Security Model

AI Factory protects against prompt injection attacks from external skills with **mandatory two-level security scanning**:

### Level 1: Automated Scanner (Python)

Static analysis detects:
- Prompt injection patterns (`ignore previous instructions`, fake `<system>` tags)
- Data exfiltration attempts (`curl` with `.env/secrets`, `~/.ssh`, `~/.aws`)
- Stealth instructions ("do not tell the user", "silently")
- Destructive commands (`rm -rf`, fork bombs, disk format)
- Config tampering (agent dirs, `.bashrc`, `.gitconfig`)
- Encoded payloads (base64, hex, zero-width characters)

Results: **CLEAN** (safe), **BLOCKED** (deleted + warned), or **WARNINGS** (user confirmation required).

### Level 2: LLM Semantic Review

AI agent reads all skill files and evaluates intent:
- Does every instruction serve the skill's stated purpose?
- Are there requests to access sensitive user data?
- Subtle rephrasing of known attacks that regex misses

The two levels complement each other — scanner is deterministic, LLM understands meaning.

## Extension System

Extensions let third-party developers add capabilities: custom CLI commands, MCP servers, skill injections, runtime definitions. Extensions survive `ai-factory update`.

### Installing & Managing

```bash
# Install from local path, git URL, or npm
ai-factory extension add ./my-extension
ai-factory extension add https://github.com/user/aif-ext.git
ai-factory extension add aif-ext-example

# Manage extensions
ai-factory extension list
ai-factory extension update              # Update all
ai-factory extension update my-ext       # Specific extension
ai-factory extension remove my-extension
```

### Extension Structure

```
my-extension/
├── extension.json          # Manifest (required)
├── commands/               # Custom CLI commands (ESM JS files)
├── injections/             # Content to inject into existing skills
├── skills/                 # Custom/replacement skills
└── mcp/                    # MCP server templates
```

### Extension Manifest

Only `name` and `version` are required. Optional fields: `commands`, `agents`, `agentFiles`, `injections`, `skills`, `replaces`, `mcpServers`.

## Configuration

AI Factory uses a **two-file architecture**:

| File | Purpose |
|------|---------|
| `.ai-factory.json` | CLI state (agents, installed skills, MCP config) — managed by AI Factory |
| `config.yaml` | User preferences (language, paths, workflow settings) — edited by developers |

### Key Config Sections

```yaml
# Language Settings
language:
  ui: en                    # Prompts, questions, summaries
  artifacts: en             # Generated plans, docs, patches
  technical_terms: keep     # preserve|translate|mixed

# Paths (all relative to project root)
paths:
  description: .ai-factory/DESCRIPTION.md
  architecture: .ai-factory/ARCHITECTURE.md
  plan: .ai-factory/PLAN.md
  plans: .ai-factory/plans/
  docs: docs/
  rules_file: .ai-factory/RULES.md

# Workflow Settings
workflow:
  auto_create_dirs: true
  verify_mode: normal       # strict|normal|lenient

# Git Settings
git:
  enabled: true
  base_branch: main
  create_branches: true
```

### Rules Hierarchy (Three-Level)

1. `paths.rules_file` — Axioms (universal project rules)
2. `rules/base.md` — Project-specific conventions
3. `rules.<area>` — Area-specific rules (`api`, `frontend`, `backend`)

**Priority**: More specific wins → `rules.api` > `rules/base.md` > `paths.rules_file`.

## See Also

- **[Development Workflow](../concepts/development-workflow.md)** — full workflow diagram and command sequence (pending)
- **[Reflex Loop](../concepts/reflex-loop.md)** — contracts and state management for iterative quality loops (pending)
- **[Subagents](../concepts/subagents-claude-codex.md)** — Claude/Codex agent orchestration architecture (pending)
- **[Extensions](../concepts/extensions-system.md)** — writing third-party extensions (pending)
- **[Security Model](../concepts/security-scanning.md)** — two-level security scanning model (pending)
- **[Plan Files](../concepts/plan-files-artifacts.md)** — artifact metadata schema and lifecycle (pending)
