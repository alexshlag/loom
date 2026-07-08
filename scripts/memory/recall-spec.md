# Recall Engine Spec — PRF-Enhanced Two-Stage Recall

**Target**: `scripts/memory/recall.sh`  
**Phase**: Phase 16.1, Task #3 (PRF-enhanced recall) + Task #4 (hot cache check-only)  
**Goal**: Replace `wiki-search.sh` calls in process-query.json with two-stage recall that keeps context window small while providing semantic-like expansion via PRF.

---

## Architecture Overview

```
┌─────────┐     ┌───────┐     ┌───────┐
│ Query   │──►│ Stage 1 │──►│ Stage 2 │──► Agent
│ Input   │    │ Links  │    │ Content│
└─────────┘     └───────┘     └───────┘

Stage 1: Rank links (no content loaded) → JSON [{path, score}]
Stage 2: Load only final top-K content → expanded markdown snippets
```

---

## Stage 1 — Links-First Ranking

### Input
| Param | Required | Default | Description |
|-------|----------|---------|-------------|
| `query` | ✅ | — | User search query string |
| `--top` | ❌ | 5 | Number of final results to return |
| `--prf` | ❌ | auto | Enable PRF boost (default on) |
| `--max-candidates` | ❌ | 10 | Max candidates from initial lexical search |
| `--dynamic` | ❌ | off | Use dynamic category priority (pass through to wiki-search) |

### Workflow

**Step 1a: Initial lexical scan**  
Run grep across wiki/index.md → get up to `max-candidates` results. Same logic as current `wiki-search.sh`.

**Step 1b: PRF extraction from top-3 candidates**  
From the first 3 results of Stage 1a, extract distinctive terms (TF-IDF-like scoring). Output: list of `(term, score)` pairs.

**Step 1c: Boost phase — re-score all candidates**  
For each candidate page:
- Base score = lexical match frequency + position weight (H1 = x3) + backlink weight
- PRF boost = for each distinctive term in PRF list that matches this page → add `score * boost_factor`
- Final rank = base_score + total_PRF_boost

**Step 1d: Output**  
JSON array of top-K results, sorted by final score (descending).

```json
[
  {"path": "wiki/concepts/prf-enhanced-recall.md", "score": 0.92, "rank": 1},
  {"path": "wiki/entities/agent-memory-management.md", "score": 0.78, "rank": 2}
]
```

### PRF Extraction Algorithm (Phase 1)

**Source**: top-3 candidates from Step 1a, read first 20 lines only (not full content).  
**Goal**: Extract distinctive terms that are unique to these results but not seen across the entire wiki.

```bash
# Hybrid TF-IDF-like approach:
# 1. Read top-3 pages (first 20 lines each) — NO FULL CONTENT LOAD
# 2. Word-level TF: count term frequency per page (ignore stopwords, case-insensitive)
# 3. Bigram extraction: extract g2 ngrams from distinctive phrases (reuse similarity_cache logic)
# 4. IDF across wiki index.md → document frequency for each term/bigram
#    → IDF = log(N / df), where N = total pages (~100-200), df = pages containing term
# 5. Score = TF * IDF — high score = distinctive for this result cluster
# 6. Return top-10 distinctive terms with scores > threshold (score >= 1.5)
```

**Reuse existing ngram logic**: `tracking/similarity_cache.json` already has working g2-g5 extraction. PRF uses the same tokenization but for term ranking instead of pair-wise comparison.

**Output format**: `term:score` pairs on separate lines (stdout).  
Example:
```
authentication:3.2
jwt:2.8
sessions:2.5
oauth:2.1
token:1.9
```

**Stopwords to exclude**: "the", "a", "an", "is", "are", "was", "were", "of", "in", "to", "for", "and", "or" — standard English list + domain-specific noise terms.

---

## Stage 2 — Content Expansion (Optional)

### When to trigger
User specifies `--stage=content` or agent decides after reading Stage 1 results.

### Workflow

**Step 2a: Load content from ranked pages only**  
Read top-K pages from Stage 1 output (K = --top parameter). Only these pages are loaded into context — everything else stays unloaded.

**Step 2b: Expand with surrounding context**  
For each page, extract:
- Full frontmatter + H1/H2 headers
- Paragraphs containing query terms (+ 2 sentences before/after for context)
- Backlinks from `backlinks.json` (metadata only, no content)

**Step 2c: Output**  
Markdown with structured sections per result.

```markdown
## [score=0.92] wiki/concepts/prf-enhanced-recall.md
### Definition
[relevant paragraph]

### Key Context
[surrounding context from +2/-2 sentences]

---

## [score=0.78] wiki/entities/agent-memory-management.md
...
```

---

## Integration Points

### process-query.json modifications

**Current**: `wiki-search.sh "query" --dynamic` → returns raw grep lines  
**Target**: `scripts/memory/recall.sh "query"` → returns JSON ranking, then optionally expanded content

**Where to replace:**
1. `process-query.json#step_0_search_phase`: Replace direct wiki-search.sh calls with recall.sh
2. `process-query.json#web_ingest_flow`: Same replacement for web-derived queries
3. All other grep-based search patterns in process files → point to recall.sh

**Fallback**: If recall.sh fails (e.g., missing dependencies), fall back to wiki-search.sh as-is. Process file must handle this gracefully:
```json
{
  "command": "./scripts/memory/recall.sh \"<query>\" --top 5 || ./wiki-search.sh \"<query>\"",
  "description": "PRF-enhanced recall with fallback to lexical-only"
}
```

---

## Hot Cache Optimization (Task #4)

**Target**: `scripts/memory/hot-cache-update.sh` — check-only mode  

### Logic
1. Compare wiki directory timestamps vs hot.md last-modified time  
2. If no wiki files changed since last run → return exit 0 ("no changes")  
3. If any file modified or new/removed → return exit 1 ("changes detected")

### Integration in process-query.json
```json
{
  "command": "./scripts/memory/hot-cache-update.sh  || true",
  "description": "Skip hot cache rebuild if wiki unchanged"
}
```

**Current behavior**: `load-hot-cache.sh` always runs, reads all wiki files.  
**New behavior**: Check-only first → only full rebuild if changes detected.

---

## Output Contracts

### recall.sh stdout (Stage 1)
JSON array when called with `--stage=links`:
```json
[{"path": "...", "score": float, "rank": int}]
```

### recall.sh stdout (Stage 2)
Markdown structured content:
```markdown
## [score=X] <relative_path>
<section content here>
---
```

### stderr
Progress messages to agent logs only — never shown to user in silent mode.

---

## Implementation Phases

### Phase 1a (First): recall.sh Stage 1 + PRF extraction
- ✅ Basic lexical scan (reuse wiki-search.sh logic)  
- ✅ PRF extraction from top-3 results (first 20 lines only)  
- ✅ Boost phase with re-scoring  
- ✅ JSON output for machine parsing

### Phase 1b (Second): recall.sh Stage 2 + process-query.json integration
- ✅ Content loading for ranked pages only  
- ✅ Structured markdown output format  
- ✅ Replace wiki-search.sh calls in process files  
- ✅ Fallback to original search if PRF fails

### Phase 2 (Future): Trajectory capture → distillation pipeline
- See `process-query.json` memory_hooks section for integration points

---

## Success Criteria

1. **Context window stays small**: Stage 1 loads only top-3 first 20 lines, not full wiki content  
2. **Semantic expansion works**: PRF terms boost semantically related pages without external models  
3. **Process files use recall.sh**: All query search calls point to new engine (with fallback)  
4. **Hot cache skips rebuild**: When wiki unchanged, no unnecessary I/O

---

## Open Questions for User Review

1. Should PRF extraction use word-level or n-gram-level term scoring? (word = simpler, n-gram = more semantic but slower)
2. What boost factor for PRF terms? (suggested: 1.5x multiplier on base score)
3. Is JSON output format acceptable for process-query.json integration?
