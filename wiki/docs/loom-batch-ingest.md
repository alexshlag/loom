---
tags: [batch-ingest, cluster-detection, multi-source-processing, greedy-clustering]
date: 2026-07-08
type: documentation
category: concept
aliases: []
sources: ["docs/batch-ingest.md"]
related: ["wiki/docs/loom-memory-hooks", "wiki/docs/loom-architecture", "rules/batch_ingest_trigger.json", "scripts/_batch_ingest.py"]
---
# Batch Ingest Workflow in Loomana

# Batch Ingest Workflow in Loomana

Page covering Batch Ingest Workflow in Loomana — overview, usage patterns, and related resources.
## When to Use Batch Ingest

Batch ingest is designed for **related sources** — documents that share entities, concepts, or keywords. It's most effective when:

- You download 3+ articles on the same framework (e.g., Symfony documentation pages)
- You're ingesting a collection of research papers from the same domain
- Multiple URLs or files are provided in a single prompt and cover overlapping topics

### Thresholds & Triggers

| Trigger Type | Condition | Example |
|-------------|-----------|---------|
| **Automatic** | Agent detects ≥3 related sources in a single ingest batch | User pastes 4 Symfony articles at once → auto-cluster detected |
| **Manual** | User explicitly requests batch processing via `batch-ingest.sh --scan` | You run the script yourself on a directory of files |

> **Rule:** Batch clustering is optional. Single-source ingestion works normally even if ≥3 related sources exist — batching just improves efficiency and crosslink quality.

---

## The Cluster Detection Algorithm

Batch ingest uses a two-phase approach implemented in `scripts/_batch_ingest.py`:

### Phase 1: Metadata Extraction

For each source file, the script extracts:
- **H1 heading** — page title / document name
- **First sentence** — introductory context (first 200 chars after frontmatter)
- **Keywords** — meaningful words from tags + body text (excluding stop words like "and", "the", "for")

Keyword extraction rules:
```python
# From tags line: extract all non-empty, >2 char tokens
# From H1/body first 500 chars: extract 3+ letter words, filter stopwords
stop_words = {'and', 'the', 'for', 'with', 'this', 'that', 'have', 'are', 'was', 'been', 'not'}
```

### Phase 2: Greedy Clustering

Keywords are indexed across all sources. Sources sharing ≥1 keyword are grouped into clusters.

**Algorithm:** Build a keyword index `{keyword → [source_files]}`, then greedily merge overlapping clusters. Only create new cluster if no merge is possible AND ≥2 sources share the keyword.

### Output Format

The script outputs JSON to stdout:

```json
{
  "total_sources": 5,
  "clusters": [
    {
      "cluster_id": "cluster-1",
      "name": "Shared entities: Event Dispatcher, Messenger Component",
      "sources": ["raw/sources/SRC-2026-07-01-001/event-dispatcher.md", 
                  "raw/sources/SRC-2026-07-01-002/messenger.md"],
      "shared_keywords_count": 2
    }
  ],
  "individual_sources": [
    "raw/sources/SRC-2026-07-01-003/standalone-article.md"
  ]
}
```

---

## User Interaction Flow

### Scenario A: Automatic Detection During Ingest

When you feed the agent multiple sources, it detects clustering automatically:

```
You: "Here are 4 Symfony articles to ingest..."
Agent: 
  1. Validates paths via validate-path.sh (each source)
  2. Checks delta tracking hashes → skip duplicates
  3. Runs batch-ingest.sh --scan internally
  4. Receives cluster manifest → presents clusters to you

Agent says: "I detected these related groups:
  - Cluster 1: Event Dispatcher + Messenger Component (shared keywords: dispatcher, message)
  - Cluster 2: Twig Templating + AssetMapper (shared keywords: template, asset)

Should I process them as batches or individually?"

You: "Process as batches."
    ↓ (agent proceeds with batch flow)
```

### Scenario B: Manual Batch Initiation via CLI

Run the script directly when you have a directory of files ready to ingest:

```bash
# Scan specific files
./scripts/batch-ingest.sh --scan raw/sources/SRC-2026-07-01-001.md \
                              raw/sources/SRC-2026-07-01-002.md \
                              raw/sources/SRC-2026-07-01-003.md

# With custom threshold (fewer shared keywords needed to form cluster)
./scripts/batch-ingest.sh --scan directory/*.md --threshold 2

# Help text
./scripts/batch-ingest.sh --help
```

**Output:** JSON clusters printed to stdout. Review the output, then proceed with ingest for each cluster or individual source.

---

## Processing Clusters vs Individuals

### Cluster Processing Flow

When you confirm batch processing:

```
Step 1: For each cluster, run standard ingest flow on ALL sources in parallel
    - Capture all sources to raw/sources/SRC-* (immutable originals)
    ↓ (content analysis phase)
Step 2: Analyze shared entities across cluster → determine unified page structure
    - If cluster members cover different aspects of same topic → single comprehensive page
    - If cluster members are distinct subtopics → related pages with crosslinks
    ↓ (discussion with user for complex clusters)
Step 3: Create wiki page(s) via process-ingest.json flow
    - Single page or multiple pages depending on shared entity analysis
    ↓ (post-processing)
Step 4: rebuild-meta.sh + link-validator.sh → verify structure integrity
```

### Individual Processing Flow

When cluster detection finds zero clusters OR you choose individual processing:

```
Step 1-3: Standard single-source ingest (same as normal flow)
    - Each source processed independently through validate-path → delta-tracking → capture → classify → frontmatter → crosslink → write
    ↓
Step 4: After all sources ingested, run batch-ingest.sh --scan to discover latent clusters
    - This catches connections the initial analysis might have missed
```

---

## Cluster Decision Logic

After receiving cluster manifest from `batch-ingest.sh`, agent evaluates:

| Condition | Action | Reasoning |
|-----------|--------|-----------|
| clusters_count == 0 OR not applicable | Proceed to step_6_discussion with individual sources | No batch needed — process normally |
| clusters_count > 0 AND user_confirms_batch | PROCEED_TO_BATCH_PROCESSING | User approved clustering → unified processing |
| clusters_count > 0 BUT unclear shared entities | Present cluster details to user for manual grouping | Agent unsure which approach is best; user decides |

---

## When NOT to Use Batch Ingest

Batch ingest adds complexity. Skip it when:

| Situation | Why Skip Batching | Alternative |
|-----------|-------------------|-------------|
| Sources are completely unrelated topics | Clustering would be meaningless noise | Process individually |
| Only 1-2 sources provided | Below clustering threshold (≥3 required) | Standard single-source ingest |
| User wants to control each page's structure individually | Batching abstracts away per-page customization | Individual processing with crosslink step after each write |

---

## Error Handling in Batch Ingest

The batch workflow follows standard error handling protocol (`rules/error_handling.json`):

```
STEP 1: DETECT → Script fails, exit code >0
    ↓ (log to wiki/log.md)
STEP 2: ANALYZE → Root cause classification:
    - local-fix: path/link problem → fix independently
    - schema-patch: contradiction in rules/AGENTS.md → propose patch
    - source-conflict: sources say opposite things → mark CONFLICT on page
    - dead-end: approach doesn't work (e.g., grep noise) → document reason, change strategy
STEP 3: RESOLVE → Apply appropriate fix
STEP 4: CONTINUE → Move forward; don't stall on broken instruction

Common batch ingest errors and fixes:
- "Source file not found" → local-fix: verify path exists in raw/sources/
- "Python script failed" → local-fix: check Python3 availability, re-run with --threshold adjusted
- "Cluster too small (<2 sources)" → dead-end: skip cluster, process remaining individually
```

---

## Integration With Other Processes

### Query Mode Integration

Batch ingest can be triggered from query mode when `web_search` results reveal ≥3 related external sources. The flow is:

```
Query step_1.5 (knowledge_gap_handling) → web_search returns multiple articles
    ↓
Detect cluster among web search results → run batch-ingest.sh internally
    ↓
Present clusters to user for approval
    ↓
If approved → TRANSITION_TO process-ingest.json via web_ingest_flow
```

### Lint Mode Integration

The lint workflow checks `post_lint_actions.new_sources_detected` and can trigger batch ingest if multiple new sources appear simultaneously:

```
Lint scan detects N ≥3 new raw sources with overlapping keywords
    ↓
Auto-run batch-ingest.sh --scan on detected sources
    ↓
Report clusters to user → propose batch processing or individual ingest
```

---

## Performance Notes

- **Speed:** Batch clustering is fast (~1s for 10 files) — metadata extraction + greedy clustering is O(n*k) where k = keywords per file
- **Scalability:** Tested with up to 50 files simultaneously; beyond that, consider splitting into smaller batches
- **Disk I/O:** Each source read once during Phase 1 (metadata); clusters written once in final output. Minimal overhead over individual processing

---

## Quick Reference Commands

| Action | Command |
|--------|---------|
| Scan files for clustering | `./scripts/batch-ingest.sh --scan <file1> [file2] ...` |
| Lower cluster threshold | `./scripts/batch-ingest.sh --scan <files> --threshold 2` |
| View help / usage | `./scripts/batch-ingest.sh --help` |
| Trigger from agent | "Cluster these sources: <URLs/files>" (agent runs internally) |

---

## Summary

Batch ingest workflow in Loomana:

1. **Detection** — ≥3 related sources detected automatically during ingest OR triggered manually via CLI
2. **Clustering algorithm** — Phase 1 extracts metadata (H1, first sentence, keywords); Phase 2 greedily groups by shared keywords using `scripts/_batch_ingest.py`
3. **User approval** — clusters presented to user; batch processing proceeds only if confirmed
4. **Processing** — cluster members processed together with unified page structure or related pages + crosslinks
5. **Fallback** — zero clusters → standard individual processing; post-ingest batch scan catches latent connections

Error handling follows EHP-V2 protocol (detect → analyze → resolve → continue). Integration with query and lint modes ensures batching can be triggered from any process type, not just manual ingest.

For cluster detection logic: read `rules/batch_ingest_trigger.json`. For the clustering engine: see `scripts/_batch_ingest.py` source code.
