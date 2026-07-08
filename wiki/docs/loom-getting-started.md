---
tags: [Loomana, loom, getting-started, onboarding, wiki-creation]
date: 2026-07-08
type: documentation
category: docs
aliases: [first-session, clone-repository, ai-harness-setup]
sources: [docs/getting-started.md]
related: [docs/architecture.md, docs/scripts-guide.md, wiki/entities/pi-coding-agent.md]
---
# Getting Started with Loomana

# Getting Started with Loomana

Page covering Getting Started with Loomana — overview, usage patterns, and related resources.
## Overview

Loomana is an **LLM-powered personal knowledge base** that grows automatically as you feed it sources (URLs, files, text) or ask questions. Unlike standard RAG systems that rediscover context on every query, Loomana **compounds knowledge incrementally** — each source enriches the wiki permanently.

> _Based on Andrej Karpathy's [LLM Wiki concept](https://gist.github.com/karpathy/ed8f28479605148297b7a8be01eb580)._

**Key idea:** You don't write wiki pages manually. Give the agent sources or ask questions — it creates structured knowledge with proper metadata, cross-links, and citations automatically.

---

## Prerequisites

- **Git** installed (for cloning repository)
- **AI coding harness/agent** — any LLM-based coding assistant that can read files, execute commands, and edit code:
  - [Pi Coding Agent](https://pi-coding-agent.github.io/) (recommended, designed for this project)
  - Claude Code, Cursor, or similar

No databases, no servers, no complex setup — just markdown + scripts on disk.

---

## Workflow Overview

### Step 1: Clone & Open

```bash
git clone https://github.com/alexshlag/loom.git
cd loom
```

Repository contains schemas, rules, scripts, and templates. `wiki/` starts empty — you'll populate it with an agent or manually.

### Step 2: Introduce the Agent

Tell your AI harness to read AGENTS.md first:

> "Read AGENTS.md — this is our wiki schema."

The agent will:
1. **Bootstrap session** — load `working_memory.json` + `wiki/hot.md` for current context
2. **Explain what it found** — wiki page counts, categories populated
3. **Follow process files** — ingest/query/lint workflows defined in JSON schemas

### Step 3: Add Your First Source

Three ways to feed information:

| Method | Example | Result |
|--------|---------|--------|
| Web URL | `"Ingest https://example.com/article"` | Agent fetches, classifies, writes wiki page |
| Local file | `"Ingest ~/Downloads/paper.pdf"` | Agent captures → validates → creates page |
| Direct text | Paste content directly | Agent parses and saves with proper frontmatter |

### Step 4: Ask Questions

Once you have pages, ask freely:

> "What do I know about [topic]?"  
> "Compare X and Y in my knowledge base."  
> "Summarize everything about [concept]."

The agent searches index.md → semantic/grep fallback → reads relevant pages → synthesizes answer with citations.

### Step 5: Auto-Maintenance

Agent handles maintenance automatically:
- **Lint checks**: Detect contradictions, orphans, broken links (`scripts/lint.sh`)
- **Git commits**: Automatic staging + commit messages following convention `type | scope: description`
- **Contradiction resolution**: Priority cascade (Code Reality > Live State > Documentation)

---

## Data Flow Architecture

```
USER PROVIDES SOURCE (URL/file/text)
    ↓
raw/sources/SRC-YYYY-MM-DD-NNN/      ← Capture (immutable, never committed)
    ↓ (content analysis + classification)
process-ingest.json                    ← Generate frontmatter + crosslinks
    ↓ (write via agent)
wiki/entities/concepts/syntheses/     ← New page created with metadata
```

### Privacy Guarantees

| Data Type | Where It Lives | In Git? |
|-----------|---------------|---------|
| Raw sources | `raw/sources/` | ❌ Never — excluded by `.gitignore` |
| Wiki pages | `wiki/**/*.md` | ✅ Yes (committed knowledge) |
| Session memory | `working_memory.json`, `hot.md` | ❌ Not tracked |
| Metadata indexes | `meta/**` | ❌ Auto-generated, never committed |

---

## Next Steps After Getting Started

1. Explore [`docs/architecture.md`](architecture.md) — understand how layers work together
2. Read `rules/` directory — see technical specs and what they govern
3. Check `scripts/` for advanced tools (auto-crosslink, similarity index)

---

## Quick Reference Commands

| Action | Command |
|--------|---------|
| Validate raw source path | `./scripts/validate-path.sh <path>` |
| Run all lint checks | `./scripts/lint.sh` |
| Rebuild metadata + index | `./scripts/rebuild-meta.sh` |
| Check for new sources | `./scripts/check-new-sources.sh --scan` |

---

## See Also

- [`docs/architecture.md`](architecture.md) — Layer architecture and design patterns
- [`docs/scripts-guide.md`](scripts-guide.md) — Complete scripts reference
- [`rules/session_context_rules.json`](../../rules/session_context_rules.md) — Memory layers and context management
