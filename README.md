# Loomana — LLM-Powered Personal Knowledge Base

A wiki that grows with every source and question. Full name: `Loomana`; short name: `loom`.

> _Idea: [Andrej Karpathy](https://karpathy.ai/). Reference: [LLM Wiki gist](https://gist.github.com/karpathy/ed8f284379605148297b7a8be01eb580)._

---

## What Is This?

**Loomana is an LLM-powered personal knowledge base.** You feed it sources (URLs, files, text) and ask questions. The wiki grows automatically — pages are created, cross-linked, and maintained by the agent.

### Key Principles

- **Sources are immutable** — raw materials never get edited directly
- **Wiki is owned by the LLM** — it creates pages, updates them, maintains links
- **Everything is governed by schemas** — `AGENTS.md` defines conventions that co-evolve with you
- **Minimal user effort** — give a source or ask a question; agent handles the rest

---

## Quick Start

### 1. Clone & Open

```bash
git clone https://github.com/alexshlag/loom.git
cd loom
```

Open in your preferred editor, then launch an AI coding agent (Pi, Claude Code, or similar). The project is designed to work **inside a harness** — just tell the agent "set up this wiki".

### 2. Work With the Agent

The agent reads `AGENTS.md` at session start and follows structured workflows:
- Give it URLs/files/text → agent ingests them into wiki
- Ask questions → agent searches, synthesizes answers with citations
- Periodic health checks → agent finds contradictions, orphans, broken links

No manual configuration needed. Everything runs from the repo's schemas and scripts.

---

## Architecture

```
raw/**          ← Immutable sources (never edited directly)
  └── sources/  ← Articles, documents, URLs captured via capture flow
  └── assets/   ← Images with OCR descriptions

wiki/**         ← LLM-generated wiki pages
  ├── entities/     ← People, companies, technologies (~13 pages)
  ├── concepts/     ← Abstract ideas, principles, methodologies (~25 pages)
  ├── syntheses/    ✓ Deep analysis combining multiple sources (2 pages)
  ├── comparisons/  ✓ Comparative analyses (4 pages)
  └── overview.md   → Current state of knowledge

rules/**        ← Technical specs for agent (read on demand via schema_ref)
scripts/**      ← Guardrails, validation, metadata rebuild tools
process-*.json  ← Workflow definitions: ingest | query | lint
AGENTS.md       ← Living schema co-evolved between human and LLM
```

### Three Workflows

| Process | Purpose | Trigger |
|---------|---------|---------|
| **Ingest** | Add sources → classify → write wiki pages | User provides URL/file/text |
| **Query** | Search wiki → synthesize answer with citations | User asks a question |
| **Lint** | Find contradictions, orphans, broken links → propose fixes | Periodic / on-demand |

---

## Getting Started With Your Data

### Adding Sources

Three ways to feed information:

1. **Web URLs** — `https://example.com/article`
2. **Local files** — `.pdf`, `.md`, `.txt` in any format
3. **Direct text** — copy-paste, meeting transcripts, notes

The agent automatically:
- Captures source → validates path → checks for duplicates
- Classifies as entity / concept / synthesis
- Writes summary → wiki pages with proper frontmatter
- Cross-links existing pages and updates index

### Asking Questions

Ask anything. The agent will:
- Search `index.md` + semantic/grep fallback
- Read relevant pages
- Synthesize answer with facts, citations, links
- Resolve contradictions using priority rules (authoritative > temporal > user_review)
- Propose saving novel insights as new wiki pages

---

## Current State

| Category | Pages | Examples |
|----------|-------|----------|
| Entities | 13 | Loomana, Pi Coding Agent, Symfony, Nvidia, Andrej Karpathy |
| Concepts | 25 | LLM Wiki Pattern, Service Container, Routing, Hexagonal Arch, Testing Strategy |
| Syntheses | 2 | RAG vs LLM Wiki Pattern, Python Dev Environments |
| Comparisons | 4 | Agent Memory Techniques, Symfony UX Packages, Loom vs Claude/Obsidian |

**Total: ~55 wiki pages across three domains:**
1. **LLM Wiki Pattern / Pi Coding Agent** — architecture patterns for AI agents
2. **Python on NixOS** — development environments and tooling
3. **Symfony ecosystem** — framework components, bundles, deployment

All three workflows (ingest/query/lint) are operational. Guardrails validate paths. Error handling protocol is active.

---

## Repository Structure

| Path | Purpose | In Git? |
|------|---------|---------|
| `wiki/**` | Wiki pages (entity/concept/synthesis/comparison/note templates) | ✅ Yes |
| `rules/*.json` | Technical specs for agent workflows | ✅ Yes |
| `scripts/*` | Guardrails, validation, metadata rebuild tools | ✅ Yes |
| `process-*.json` | Workflow definitions | ✅ Yes |
| `AGENTS.md`, `PLAN.md`, `RULES.md` | Schema & documentation | ✅ Yes |
| `raw/**` | Raw sources (immutable) | ❌ No — never tracked, only via capture flow |
| `meta/**` | Auto-generated metadata | ❌ No — rebuilt by `scripts/rebuild-meta.sh` |
| `.fastembed_cache/` | ML model cache (~87MB) | ❌ No — regenerated automatically |

---

## Development & Maintenance

### Agent Rules (for AI agents working on this project)

- **Read before every operation**: process files + rules via `schema_ref`
- **Never edit raw/** directly** — use capture → integrate flow
- **Never duplicate AGENTS.md rules in scripts** — use schema_ref to canonical source
- **All commits follow convention**: `<type> | <scope>: <description>`
- **Memory sync required** after dev commits (WM + hot.md update)

See `AGENTS.md` and `RULES.md#9-instruction-compactification` for full conventions.

### Human Maintenance

Nothing special needed. The agent handles:
- Git commits with proper messages
- Wiki page creation, updates, cross-linking
- Contradiction resolution, orphan cleanup
- Metadata rebuilds from raw sources

---

## Status

🚧 **In development.** Not yet released.

The project is a working prototype demonstrating LLM-powered wiki automation. All core workflows (ingest/query/lint) are operational with guardrails and error handling protocols in place.

**Roadmap highlights:**
- ✅ Context management with transient rules (schema_ref pattern)
- ✅ Working memory bridge (`working_memory.json`)
- ✅ Delta-tracking for source deduplication
- ✅ Evidence grading from sources
- ✅ Git workflow automation + pre-commit guardrails
- 🔄 FTS search instead of full index reads (>100 pages scaling)
- 🔄 Cron-based lint automation

---

## Links

- [AGENTS.md](AGENTS.md) — Complete schema, conventions, agent instructions
- [PLAN.md](PLAN.md) — Project roadmap & phase statuses
- [wiki/overview.md](wiki/overview.md) — Current knowledge state
- [wiki/log.md](wiki/log.md) — Chronological action log

---

## Credits

Based on Andrej Karpathy's LLM Wiki concept. Built with Pi coding harness and designed for personal knowledge management at scale.
