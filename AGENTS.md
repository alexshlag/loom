# AGENTS.md — Wiki Schema & Conventions

## 📋 Overview

This document defines the structure, conventions, and workflows for maintaining this wiki. It serves as the single source of truth for how the LLM agent should operate when:
- Ingesting new sources
- Answering queries against the knowledge base
- Maintaining and health-checking the wiki

The schema **co-evolves** with you over time — update it as we discover what works best for your domain.

---

## 🏗 Architecture Layers

### 1. Raw Sources (`raw/`)
* Immutable collection of original documents, articles, images, data files
* LLM reads from these but never modifies them directly
* Write access restricted via `scripts/validate-path.sh` guardrails
* All changes must go through: capture → integrate flow (never direct edits)

### 2. The Wiki (`wiki/`)
* Directory of LLM-generated markdown files organized by type
* LLM owns this layer entirely — creates pages, updates them, maintains cross-references
* You read it; the LLM writes and maintains it
* Structure:
  * `entities/` — concrete identifiable objects (people, companies, technologies)
  * `concepts/` — abstract ideas, principles, methodologies
  * `comparisons/` — comparative analysis of entities/concepts
  * `syntheses/` — deep analysis combining multiple sources/pages
  * `notes/` — personal notes, meeting transcripts, observations
  * `bibliography/` — books, articles, research papers
  * `resources/` — tools, plugins, libraries references

### 3. Schema (this document)
* Defines how the wiki is structured and what workflows to follow
* What makes the LLM a disciplined wiki maintainer rather than generic chatbot
* Co-evolved between human and agent based on experience

---

## 📄 Page Formats & Templates

Every page must include YAML frontmatter:

```yaml
---
tags: [entity, coding-agent, terminal]
date: YYYY-MM-DD
sources: [raw/sources/...]
related: [wiki/entities/example.md]
---
```

### Entity Pages
```markdown
# [Name of concrete object]
Brief definition (1-2 sentences)

## Key Characteristics
* **Characteristic 1** — description
* **Characteristic 2** — description

## Sources
* `raw/sources/...` — URL/context

## Updated YYYY-MM-DD — new clarification
[what changed, what's new]
```

### Concept Pages
```markdown
# [Concept Name]
Definition section

## Principles
1. Principle one with explanation
2. How it works in practice

## Context & Application
When and why this concept is relevant

## Examples
Concrete examples of usage

## Updated YYYY-MM-DD — new clarification
[what changed, what's new]
```

### Comparison Pages
```markdown
# Comparison: [Entity A] vs [Entity B]

| Parameter | Entity A | Entity B |
|-----------|----------|----------|
| ... | ... | ... |

## Analysis
Detailed comparison and synthesis

## Conclusion
When to use which, trade-offs
```

### Synthesis Pages
```markdown
# [Synthesis Title]
Context section

## Analysis
Deep dive combining multiple sources/pages

## Insights & Conclusions
Novel findings that weren't obvious from individual sources

## Connections
How this synthesis connects to other wiki pages
```

---

## 🔄 Workflows

### Ingest Flow (capture → integrate)
1. User provides source (URL, file, pasted text)
2. Agent classifies: entity / concept / notes / project / bibliography
3. Agent reads source, identifies key theses and entities mentioned
4. Agent checks for contradictions with existing wiki pages
5. Agent discusses findings with user (proposes which pages to create/update)
6. User confirms → agent creates/updates wiki pages
7. Agent updates index.md, log.md
8. Agent runs `scripts/rebuild-meta.sh` after any write

### Query Flow
1. User asks question against the wiki
2. Agent reads index.md first (content-oriented catalog)
3. Agent performs semantic search via `wiki_recall(query)` to find relevant pages by meaning
4. If no results, falls back to grep-recursive over wiki/
5. Agent reads all relevant pages, notes key facts
6. Agent synthesizes answer with citations from multiple sources
7. **Compounding:** If answer contains novel insight or contradiction resolution → save as new page (see Compounding section below)

### Lint Flow (periodic health check)
1. Check for contradictions between pages
2. Flag stale claims superseded by newer sources
3. Identify orphan pages with no inbound links
4. Find important concepts mentioned but lacking their own page
5. Suggest new questions to investigate, new sources to look for

---

## ⚙️ Execution Modes

```json
{
  "default_mode": "silent",
  "verbose_phrases": [
    "давай проверим", "нет ли ошибок", "покажи как работает",
    "verbose mode", "покажи шаги выполнения"
  ],
  "return_to_silent_after": 3,
  "process_overrides": {}
}
```

### Правила применения
1. `default_mode` = базовый режим (по умолчанию silent)
2. Если процесс.json содержит поле `"execution_mode"`, оно **переопределяет** default для этого процесса
3. Фраза из `verbose_phrases` → принудительный verbose до команды `"silent"`

### Verbose-логирование (шаблоны)
```json
{
  "query_verbose": [
    "[✓] Index lookup: index.md прочитан",
    "[✓] Semantic search: найдено X релевантных страниц",
    "[!] Grep fallback использован для Y фактов",
    "[✓] Synthesis из Z источников"
  ],
  "ingest_verbose": [
    "[✓] Source classified: entity/concept/notes",
    "[!] Contradiction detected in X.md",
    "[✓] Pages created/updated: N"
  ],
  "lint_verbose": [
    "[✓] Check 1/N: contradictions — M конфликтов",
    "[✗] Check 2/N: orphan_pages — найдено K сирот",
    "[!] Check 3/N: knowledge_gaps — X нехватки"
  ]
}
```

---

## 🛡 Rules & Guardrails

### Protected Zones
* `raw/**` — immutable, read-only via links on source packets only
* `meta/**` — auto-generated files (registry.json, backlinks.json) never edit manually
  * Rebuild automatically after any wiki write via `scripts/rebuild-meta.sh`

### Never Do
* Directly edit files in protected zones
* Skip the capture flow for raw sources
* Manually modify meta/ files

---

## 🔍 Search Strategy

Priority order:
1. **Index lookup** — read index.md by categories matching topic
2. **Semantic search** — call `wiki_recall(query)` to find pages by meaning, not keywords
3. **Grep recursive** — fallback if semantic search returns nothing

This works surprisingly well at moderate scale (~100 sources, hundreds of pages). As wiki grows beyond this, consider adding proper search engine (qmd or similar hybrid BM25/vector tool).

---

## 📊 Compounding Knowledge Base

### Why This Matters
The key insight from Andrej Karpathy's LLM Wiki Pattern: **the wiki keeps getting richer with every source you add and every question you ask**. Unlike standard RAG where knowledge is rediscovered fresh on every query, our wiki compounds — cross-references already exist, contradictions already flagged, synthesis already reflects everything read.

### How Compounding Works
When answering a query:
1. If answer synthesizes information from 2+ existing pages → consider saving as new synthesis/comparison page
2. If you discover novel insight or contradiction resolution not previously recorded → save as new page
3. Always add backlinks to related pages when creating new content
4. Update index.md with new entry

### When to Create New Pages
* User explicitly requests saving answer as wiki page
* Answer contains synthesis from multiple sources (valuable exploration)
* Comparison/analysis that could be useful for future queries
* Contradiction resolution that should become permanent record

This way explorations compound in the knowledge base just like ingested sources do.

---

## 📈 Schema Evolution Guidelines

Over time, we'll discover what works best for your domain:
* Add new page types if needed (e.g., `projects/`, `meetings/`)
* Refine categorization criteria as wiki grows
* Update workflows based on usage patterns and pain points
* Document discoveries in log.md with consistent prefix format

**Tip:** If each log entry starts with consistent prefix like `## [YYYY-MM-DD] ...`, the log becomes parseable: `grep "^## \[" log.md | tail -5` gives last 5 entries.

---

## 📚 Additional Tools (Optional)

At some point you may want CLI tools to help agent operate efficiently:
* **Obsidian Web Clipper** — convert web articles to markdown quickly
* **qmd** — local search engine with hybrid BM25/vector + LLM re-ranking
* **Marp** — markdown-based slide decks from wiki content
* **Dataview** — Obsidian plugin for queries over page frontmatter

The wiki is just a git repo of markdown files — version history, branching, collaboration come free.

---

*Schema Version: 1 | Last Updated: 2026-06-24 | Author Pattern: Andrej Karpathy (LLM Wiki)*