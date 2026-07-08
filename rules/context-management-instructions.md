# Context Management Instructions for Ingest Process

## Core Principle

**Context window is a finite budget — not infinite memory.** Every token in context competes for attention. Holding stale content (raw source docs, generated wiki pages after they're written) degrades performance on the current task even before hitting hard limits ("context rot").

## What to Forget During Ingest

### 1. Source Document Content → FORGET After Step 3

**When**: Immediately after `step_3_analysis` completes (read source, extract entities/facts/concepts).

**What to discard**: Full raw content of the source document from working context.

**Keep only**:
- `source_file_path` (for `sources: []` frontmatter)
- `document_title_or_short_name`
- `evidence_grade` of source

**Explicit instruction template**: 
> "Source document [{TITLE}] processed and forgotten. Knowledge captured in wiki page [{WIKI_PAGE_PATH}]. Discard full source text — it is now re-fetchable from disk via read_file."

**Why**: Once knowledge is extracted and written to wiki, the raw source becomes noise competing with wiki page writing for limited context window.

### 2. Generated Wiki Page Content → FORGET After Step 9

**When**: Immediately after `step_9_post_checks` passes all validations (structure OK, crosslinks verified).

**What to discard**: Full content of the newly created/updated wiki page from working context.

**Keep only**:
- `page_path`
- `page_title`
- `page_category`

**Explicit instruction template**:
> "Wiki page [{WIKI_PAGE_PATH}] created/validated. Content written to disk with proper structure and crosslinks. Discard full page content from context — it is retrievable via read_file."

**Why**: Wiki pages are disk-persisted. Once validated and linked, they're fully retrievable. Holding them in context during registration/logging steps wastes tokens.

### 3. Batch Ingest → Process ONE At A Time

**When**: When `batch-ingest.sh --scan` detects ≥3 related sources.

**Correct sequence**:
1. Read source A → extract entities/facts → write wiki page for A
2. FORGET: Discard source A content; keep only path + title
3. Read source B → extract → write wiki page (or append to existing)  
4. FORGET: Discard source B content

**Prohibited**: Reading all N sources into context simultaneously, then processing them together — causes O(N×doc_size) token bloat.

## Context Bubble Policy

**Rule**: Max 3 wiki pages in active context simultaneously.
- When opening a wiki page to read → close (forget) one of the current 3.
- This prevents accumulating stale page content from previous reads.

Reference: `rules/session_context_rules.json#operational_rules.context_bubble_max_pages`

## Why Forget Matters — Research Backing

Based on context engineering principles from Anthropic, LangChain, and Claude Code best practices:

1. **Context is a finite resource with diminishing returns** (Anthropic): Every new token depletes the attention budget by some amount.
2. **Context rot**: As tokens accumulate, recall degrades even before hitting hard limits — content "technically present" but buried under everything read since.
3. **Tool-result clearing**: Once a tool result (file content) is processed and its value extracted, drop it from context while keeping metadata that points to where it's stored. This is the most surgical form of context management.
4. **Sub-agent delegation principle** (Anthropic): If intermediate output generates large volumes but only conclusion matters — process in isolation and discard details.

## Implementation Pattern for Agent

When processing ingest steps, follow this pattern:

```
[READ source] → [EXTRACT entities/facts/concepts] → [WRITE to wiki page]
→ [FORGET source content] → [Proceed to next step with only metadata]

[CREATE wiki page] → [VALIDATE structure + crosslinks] → [WRITE to disk]
→ [FORGET page content] → [Proceed to registration/logging with only path]
```

## Related Rules

- `rules/source_transient_ingest.json` (STI-V2) — Transient memory contract
- `rules/context_budget.json` (CBUDGET-V1) — Context budget management principles  
- `rules/session_context_rules.json` — Session context layers, max open pages
- `process-ingest.json#forget_instructions` — Explicit forget triggers per step
