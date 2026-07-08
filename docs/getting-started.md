# Getting Started with Loomana

Welcome to **Loomana** — your LLM-powered personal knowledge base. This guide walks you through everything: from cloning the repository to asking your first question and having the wiki grow automatically.

---

## What Is Loomana?

A **personal wiki that grows with every source and question**. You feed it information (URLs, files, text) or ask questions — and an AI agent builds pages for you, maintains links between facts, and keeps everything organized.

> _Based on Andrej Karpathy's [LLM Wiki concept](https://gist.github.com/karpathy/ed8f284379605148297b7a8be01eb580)._

**Key idea:** You don't write wiki pages manually. You give the agent sources or ask questions, and it creates structured knowledge with proper metadata, cross-links, and citations — automatically.

---

## Prerequisites

You need:
- **Git** installed (for cloning)
- **An AI coding harness/agent** — any LLM-based coding assistant that can read files, execute commands, and edit code in your editor
  - Examples: [Pi](https://pi-coding-agent.github.io/) (designed for this project), Claude Code, Cursor, or similar

That's it. No databases, no servers, no complex setup — just markdown + scripts on disk.

---

## Step 1: Clone the Repository

```bash
git clone https://github.com/alexshlag/loom.git
cd loom
```

The repository contains everything you need to run Loomana — schemas, rules, scripts, and templates. The `wiki/` directory starts empty (you'll populate it yourself or with an agent), while `raw/` stores your raw sources privately (never committed).

---

## Step 2: Choose Your Harness

Any AI coding harness that supports file reading, command execution, and multi-file edits will work. Here are some options:

### Option A: Pi Coding Agent (Recommended)
If you're using [Pi](https://pi-coding-agent.github.io/), the project is designed for it. Simply open the repository in your editor with Pi active — the agent reads `AGENTS.md` automatically at session start and follows all schemas.

```bash
# If using Pi specifically:
pi --open .  # or whatever command launches your editor with Pi
```

### Option B: Claude Code / Cursor / Other
Any LLM-based coding assistant works. Open the repository in your preferred IDE/terminal, then tell it to "work as my wiki agent". The schemas are universal — they don't depend on any specific harness API.

---

## Step 3: First Session — Introduce the Wiki

Open a new session with your AI agent and say something like:

> "I'd like you to work as my personal knowledge base manager for this project. Read AGENTS.md first, then follow the processes defined in process-ingest.json / process-query.json / process-lint.json."

The agent will:
1. **Read AGENTS.md** — the complete schema defining wiki structure, conventions, and workflows
2. **Bootstrap session** — load `working_memory.json` (if exists) + `wiki/hot.md` for current context
3. **Explain what it found** — tell you how many wiki pages exist, what categories are populated

---

## Step 4: Add Your First Source

There are three ways to feed information into the wiki:

### Method A: Provide a URL
Tell your agent:

> "Ingest this article: https://example.com/article"

The agent will automatically:
1. Fetch and parse the content
2. Validate path (via `scripts/validate-path.sh`)
3. Check for duplicates (`scripts/rebuild-source-manifest.sh`)
4. Classify as entity / concept / synthesis (based on content)
5. Write a summary page to `wiki/entities/` or `wiki/concepts/`
6. Update cross-links and index.md

### Method B: Provide a Local File
Give the agent a file path:

> "Ingest this document: ~/Downloads/research-paper.pdf"

Or paste text directly:

> "Here's some content to add to my wiki..." (paste your text)

The agent handles everything — parsing, saving raw source, creating wiki page with proper frontmatter.

### Method C: Write Raw Source Manually
You can also place a file yourself in `raw/sources/`:

```bash
mkdir -p raw/sources
# Create your document here
nano raw/sources/my-topic.md
```

Then ask the agent to process it — it will detect new sources at session start (via `scripts/check-new-sources.sh`).

---

## Step 5: Ask Your First Question

Once you have some wiki pages, ask questions freely:

> "What do I know about [topic]?"
> "Compare X and Y in my knowledge base."
> "Summarize everything about [concept]."

The agent will:
1. Search `wiki/index.md` + semantic/grep fallback to find relevant pages
2. Read those pages and synthesize an answer with facts, citations, links
3. Resolve any contradictions using priority rules (authoritative > temporal > user_review)
4. If the answer contains **novel insight**, propose saving it as a new wiki page

---

## Step 6: Let Maintenance Run Automatically

The agent handles maintenance on its own schedule:

### Periodic Lint Checks
At session start or when you ask, the agent runs health checks via `scripts/lint.sh`:
- Detects contradictions between pages
- Finds orphaned pages with no links
- Validates structural requirements (frontmatter tags, etc.)
- Reports issues → proposes fixes → waits for your approval

### Git Commit Automation
After every significant action (ingest, query saving new insight, lint fix), the agent commits:
```bash
git add <specific-files> && git commit -m "<type> | <scope>: <description>"
```
Commit types: `feat`, `fix`, `refactor`, `schema`, `lint`, `ingest`, `query`

---

## Working With Private Data

### Raw Sources (`raw/`)
Your raw sources live in `raw/sources/`. They are:
- **Never committed** to git — only tracked locally
- **Immutable** — never edited directly, only through the agent's capture → integrate flow
- **Protected** by `scripts/validate-path.sh` guardrails

### Wiki Pages (`wiki/`)
Wiki pages are in `wiki/entities/`, `wiki/concepts/`, `wiki/syntheses/`, etc.:
- **Created and maintained by the agent** — you don't need to write markdown manually
- **Structured with frontmatter** — automatic metadata extraction from sources

### Meta Data (`meta/`)
Auto-generated files like `registry.json` or `backlinks.json`:
- **Rebuilt automatically** by `scripts/rebuild-meta.sh` — never committed
- Generated fresh on every rebuild

---

## Troubleshooting

### Agent Doesn't Read AGENTS.md at Start?
Explicitly tell it: "Please read AGENTS.md first, this is the schema for our wiki." The agent should load it before any other operations.

### No Wiki Pages Yet?
Start by adding a source (URL or file). Even one page will populate `wiki/index.md` and give you something to query against.

### Contradictions Detected?
The agent proposes fixes based on priority rules:
1. **Code Reality** — actual implementation / code (highest priority)
2. **Live State** — current system state
3. **Documentation** — historical or conceptual docs

You review and approve the fix. No automatic overwrites happen without your go-ahead.

### Scripts Failing?
Most scripts have `--help` flags for quick reference:
```bash
./scripts/lint.sh --help
./scripts/rebuild-meta.sh --help
./scripts/validate-path.sh --help
```

---

## Quick Reference Commands

| Action | Command |
|--------|---------|
| Validate a raw source path | `./scripts/validate-path.sh <path>` |
| Run all lint checks | `./scripts/lint.sh` |
| Rebuild metadata index | `./scripts/rebuild-meta.sh` |
| Check for new sources | `./scripts/check-new-sources.sh --scan` |
| Generate commit message | (Agent does this automatically) |

---

## Next Steps After Getting Started

Once you're comfortable with the basics:
1. Explore `docs/architecture.md` — understand how layers work together
2. Read `rules/` directory — see what technical specs exist and what they mean
3. Check `scripts/` for advanced tools (auto-crosslink, similarity index, etc.)

---

## Summary

Loomana works like this:
1. **Clone** → open in your harness
2. **Introduce agent** → tell it to follow AGENTS.md + process files
3. **Feed sources** → URLs/files/text — agent creates wiki pages automatically
4. **Ask questions** → agent searches, synthesizes answers with citations
5. **Auto-maintenance** → lint checks, git commits, contradiction resolution

Everything is governed by schemas that the agent reads on demand (`schema_ref` pattern). No manual configuration needed beyond cloning and opening your harness.

Happy wiki-building! 🎉
