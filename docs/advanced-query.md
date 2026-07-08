# Advanced Query Techniques in Loomana

This document covers advanced query strategies that go beyond basic fact-finding — topic continuity, compounding decisions, search hierarchy optimization, and novel insight detection. Use this when you want the wiki to build deeper knowledge connections or proactively expand itself.

---

## Topic Continuity Bias

When the agent receives a new query, it doesn't start from zero. It checks `working_memory.json.focus_node` to determine if we're continuing an existing topic or starting fresh.

### How It Works

```
Step 1: Check WM.focus_node → does this relate to recent operations?
    ↓ (topic continuity detected)
Step 2: Bias search toward pages related to current focus_node
    - Read wiki/index.md filtered by categories relevant to focus
    - Prioritize pages with high crosslink count from backlinks.json
    ↓ (no topic continuity — new topic)
Step 3: Full index scan → broad keyword matching → expand context bubble
```

### When Continuity Bias Applies

| Condition | Effect on Search | Example |
|-----------|-----------------|---------|
| WM.focus_node = "Symfony components" + query mentions "messenger" | Search biased toward Symfony-concept pages first | Symfony messenger → auto-links to event-dispatcher, cache-system |
| No focus_node or completely unrelated topic | Full wiki index scan with category filtering | User asks about "NixOS" when previous work was on Symfony → broad search |

### Why It Matters

Topic continuity bias prevents **context fragmentation** — the agent doesn't jump between unrelated topics randomly. By prioritizing pages related to current focus, answers become more coherent and crosslink opportunities are discovered organically.

---

## Compounding Decision Logic

After a query returns results, the agent evaluates whether the answer is worth saving as a new wiki page or updating an existing one. This decision is governed by `rules/compounding_workflow.json`.

### Evaluation Criteria (Compounding Score)

| Criterion | Weight | Description |
|-----------|--------|-------------|
| Synthesis from 2+ pages | High | Answer combines facts from multiple sources → compounding value detected |
| Novel inference | High | Agent generates insight not present in any single source → novel insight flag set |
| Contradiction resolution | Medium | Multiple authoritative answers exist, cascade resolved → worth documenting decision |
| Multi-source agreement | Low-Medium | 3+ sources confirm same fact → strengthens existing page or creates comparison |

### Decision Tree

```
compounding_flagged = (synthesis_from_2plus_pages OR novel_inference)?
    ↓ (YES)
Duplicate check: Does similar page already exist in backlinks.json?
    ├─ YES → PROPOSE_UPDATE_TO_USER → route to process-ingest.json#step_8b_update_page
    └──NO → PROPOSE_CREATE_TO_USER → route to process-ingest.json#step_8a_new_page

compounding_flagged = NO (answer is straightforward, single-source)?
    ↓
Deliver answer only — no wiki change required. No auto-save.
```

### Guardrails

- **Never create wiki pages directly from query.** All proposals → user_confirm → TRANSITION to `process-ingest.json` for actual write.
- **UPDATE_EXISTING_PAGE is prohibited** without going through process-ingest flow (step_8b_update_page).
- **PROCEED_TO_CREATE_NEW_PAGE is prohibited** — must always route through ingest's step_8a_new_page.

---

## Search Hierarchy in Detail

Loomana uses a three-tier search hierarchy during queries (`rules/search_strategy.json`). Understanding each tier helps you formulate better questions and know why the agent finds (or doesn't find) certain pages.

### Tier 1: Index Scan (Fastest, Most Relevant)

**Command:** `grep -m 30 '<keyword>' wiki/index.md`

- Reads structured index (`wiki/index.md`) with per-category summaries
- Fast because it's a single file (~2-5KB typically)
- Uses category filtering to narrow scope before keyword matching
- **Best for:** Focused questions on known topics

### Tier 2: Semantic Search (Embedding-Aware)

**Command:** `grep -m 20 '<keyword>' meta/search-index.json`

- Reads pre-computed semantic similarity index (`tracking/similarity_index.json`)
- Finds pages with semantically related content, not just keyword matches
- Slower than index scan but catches conceptual relevance
- **Best for:** Abstract questions ("What is the pattern behind X?")

### Tier 3: Grep Fallback (Broadest Coverage)

**Command:** `./scripts/memory/recall.sh '<query>'` followed by targeted grep on wiki pages.

- Direct keyword search across all wiki content (`grep -m N 'pattern' wiki/**/*.md`)
- Uses regex-injection cleanup to avoid false positives
- Most expensive tier — reads more files, higher token cost
- **Best for:** When index + semantic return nothing → exhaustive search required

### Fallback Chain Behavior

```
Tier 1 (index) returns results?
    ├── YES → Read matched pages from index → Proceed to synthesis
    └── NO → Tier 2 (semantic): grep search-index.json
              ↓
              Results found?
                  ├── YES → Read semantically related pages → Synthesis
                  └── NO → Tier 3 (grep fallback): recall.sh + targeted grep
                        ↓
                        Found anything?
                            ├── YES → Proceed with grep results
                            └── NO → Trigger knowledge_gap_handling (step_1.5)
```

---

## Novel Insight Save Criteria

After synthesis, the agent asks: "Is this answer valuable enough to become a permanent wiki page?" Here are the concrete criteria:

### When to Propose Saving (Compounding Value Detected)

| Scenario | Action | Example |
|----------|--------|---------|
| Answer synthesizes facts from 3+ wiki pages | Save as synthesis page in `wiki/syntheses/` | "RAG vs LLM Wiki Pattern" synthesized from 5 existing pages |
| External data (web_search) reveals new relationship between existing topics | Auto-ingest topic expansion if topic exists, else propose to user | Web search shows Symfony messenger uses event-dispatcher → create page linking them |
| Contradictions resolved with clear rationale worth documenting | Save as comparison or update existing page with resolution notes | "Symfony messenger-component vs event-dispatcher: which to use when" |

### When NOT to Save (Straightforward Answer)

| Scenario | Reason Not to Save |
|----------|-------------------|
| Single-source fact retrieval | No synthesis, no novel insight — just a lookup |
| User asked for quick reference ("What year was X founded?") | Too small for wiki page; keep in conversation context only |
| Already answered and saved previously | Duplicate save is wasteful; check backlinks.json first |

### Novel Insight Detection Algorithm

```
1. Count distinct sources used → ≥3 = potential synthesis
2. Compare answer content vs source content → novel_inference if:
   - Agent generates connection not explicitly stated in any single source
   - Cross-references between topics reveal pattern or principle
3. If novel_inference = true → set compounding_flagged = true
4. Run duplicate check against backlinks.json before proposing save
```

---

## Knowledge Gap Handling (step_1.5)

When all wiki search methods return zero results, the agent doesn't just say "I don't know." It follows a structured fallback:

### External Search Flow

```
Step 1: web_search with queries array (2-4 varied angles)
    - Use provider=auto for optimal routing
    - Vary phrasing and scope for broader coverage
    ↓ (results received)
Step 2: Synthesize answer from external sources using wiki page templates
    ↓
Step 3: Determine save path → topic_expansion OR new_independent_topic

Scenario A — Topic Expansion:
    "New data relates to existing topic in wiki"
    → Auto-ingest: create_new_expansion_of_existing via web_ingest_flow
    → No user_confirm required (topic already approved)
    → Example: Symfony exists → web search reveals migrations detail → auto-create page

Scenario B — New Independent Topic:
    "Standalone topic not found in wiki"
    → PROPOSE_SAVE_TO_USER_FIRST_PAGE_OF_NEW_TOPIC
    → User confirm required ONLY FOR THE FIRST PAGE of this independent topic
    → Once approved, all subsequent expansion = Scenario A (auto-ingest)
```

### Web Search Fail Path

If web_search also returns no useful data:
- Inform user: "No external data found for this query"
- No page created — nothing saved to wiki
- Session continues normally with whatever context exists

---

## Advanced Query Patterns

### Pattern 1: Cross-Domain Comparison

```
Query: "How does [concept A from Symfony] compare to [concept B from NixOS]?"
Expected flow:
1. Index scan → find relevant pages in both domains
2. Semantic search → catch conceptual similarities
3. Read both pages, extract facts
4. Synthesize comparison with cross-links
5. If ≥3 sources or novel insight → propose save as comparison page
```

### Pattern 2: Deep-Dive on Existing Topic

```
Query: "Tell me everything about [existing topic], including edge cases and common mistakes."
Expected flow:
1. Index scan → all pages with this topic
2. Read each page, extract facts + edge cases mentioned
3. Check if existing pages cover edge cases or are superficial
4. If gaps found → propose web_search to fill them → auto-ingest if topic exists
5. Result: comprehensive deep-dive page created automatically
```

### Pattern 3: Timeline / Evolution Tracking

```
Query: "How has [framework] evolved over the years? Show me version differences."
Expected flow:
1. Index scan → entity pages for framework + any timeline/synthesis pages
2. Grep fallback → search for version numbers, dates across all wiki content
3. Synthesize chronological narrative with source citations per era
4. If substantial new info found → propose save as live_state type page
```

### Pattern 4: "Teach Me" / Learning Path Generation

```
Query: "I'm new to [topic]. What should I learn first? Give me a structured path."
Expected flow:
1. Index scan → find foundational pages for topic
2. Read pages, identify prerequisite relationships (X links to Y)
3. Generate ordered learning sequence based on dependency graph in backlinks.json
4. If comprehensive guide doesn't exist → propose creating wiki/docs/[topic]-guide.md
5. Use docs-template.json structure: Getting Started → Core Concepts → Advanced Patterns
```

---

## Search Strategy Rules (From rules/search_strategy.json)

### Tool Priority Order

1. **recall.sh** — PRF-enhanced recall engine with TF-IDF extraction + stopwords filtering
2. **wiki/index.md grep** — fast, category-filtered keyword matching
3. **search-index.json grep** — semantic similarity fallback
4. **web_search** — external only when wiki is empty or knowledge gap detected

### Search Safety Rules

- Never use `find`/`ls` for searching wiki content (prohibited)
- Always limit grep with `-m N` flag (never unlimited output)
- Use `awk '/regex/'` or `sed -n 'X,Yp'` for structured line extraction
- JSON files → prefer `jq '.field'` over grep

---

## Summary

Advanced query techniques in Loomana:

1. **Topic continuity bias** — search prioritizes pages related to current focus_node, preventing context fragmentation
2. **Compounding decision logic** — evaluates synthesis value before proposing new wiki pages; uses backlinks.json for duplicate detection
3. **Three-tier search hierarchy** — index → semantic → grep fallback → external web_search
4. **Novel insight save criteria** — saves only when ≥3 sources synthesized OR novel inference detected; straightforward answers delivered without wiki changes
5. **Knowledge gap handling** — structured fallback chain from topic_expansion (auto) to new_independent_topic (user_confirm required for first page only)

All query operations route through `process-query.json`. Actual wiki writes happen via `web_ingest_flow` → TRANSITION to `process-ingest.json`. Direct edits from queries are prohibited.

For search strategy details: read `rules/search_strategy.json` and `rules/compounding_workflow.json` via schema_ref pattern.