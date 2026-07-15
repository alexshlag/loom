---
tags: [query-routing, intent-patterns, user-glossary, agent-experience]
date: 2026-07-08
type: live_state
category: glossary
aliases: [user-query-patterns, query glossary, routing patterns, intent dictionary]
sources: [agent experience, process-query.json outcomes, AGENTS.md#glossary_integration]
related: [concepts/llm-wiki.md, docs/loom-session-lifecycle.md, rules/query_glossary.json]
---
# User Query Patterns Glossary

Living document of real user query patterns and their routing outcomes. Agent uses this to enhance intent detection beyond hardcoded heuristics.

## High-Confidence Patterns (usage_count ≥ 5)

### Pattern: Entity/Concept Lookup
- **user_signal**: `what`, `how`, `about`, `used`, `for`, `which`
- **matched_process**: process-query.json
- **confidence**: high
- **last_used**: 2026-07-08
- **usage_count**: 5+
- **examples**: ["Какая библиотека в Symfony?", "What is Loomana?", "How does RAG work?"]
- **routing_notes**: Always starts with wiki search → grep index.md → synthesize answer

### Pattern: Source Addition / Ingest
- **user_signal**: `add`, `import`, `ingest`, `source`, `article`, `link` + URL/file path
- **matched_process**: process-ingest.json
- **confidence**: high
- **last_used**: 2026-07-08
- **usage_count**: 3+
- **examples**: ["Add this article about X", "Import GitHub repo Y"]
- **routing_notes**: Always validates path → delta check → analysis → discussion

### Pattern: Wiki Health Check
- **user_signal**: `check`, `lint`, `health`, `scan`, `find contradictions`, `orphan`
- **matched_process**: process-lint.json
- **confidence**: high
- **last_used**: 2026-07-08
- **usage_count**: 2+
- **examples**: ["Check wiki health", "Find broken links"]
- **routing_notes**: Runs lint.sh → auto-fix phase → presents non-auto-fixable to user

## Medium-Confidence Patterns (usage_count 2-4)

### Pattern: Comparison Request
- **user_signal**: `compare`, `difference between`, `vs`, `compared to`
- **matched_process**: process-query.json → synthesis trigger → process-ingest.json (if save confirmed)
- **confidence**: medium
- **last_used**: 2026-07-08
- **usage_count**: 2+
- **examples**: ["Compare Loomana vs RAG", "What's the difference between X and Y?"]
- **routing_notes**: Search both entities → compare across sources → if ≥3 pages used → propose synthesis page

### Pattern: Deep Dive / Study
- **user_signal**: `explain`, `deep dive`, `study`, `tell me more about`
- **matched_process**: process-query.json (deep_dive mode)
- **confidence**: medium
- **last_used**: 2026-07-08
- **usage_count**: 1+
- **examples**: ["Explain hexagonal architecture in detail", "Tell me more about Symfony DI"]
- **routing_notes**: Retain all pages across turns, max context bubble = 3

### Pattern: Update Existing Page
- **user_signal**: `update`, `add info to`, `refresh` + existing page/topic name
- **matched_process**: process-ingest.json (step_8b_update_page)
- **confidence**: medium
- **last_used**: 2026-07-08
- **usage_count**: 1+
- **examples**: ["Update Symfony page with new info", "Add migration details to existing page"]
- **routing_notes**: Validate path → read existing page → identify additions → write update

## Low-Confidence / Emerging Patterns (usage_count < 2)

### Pattern: Mixed Intent (Query + Ingest)
- **user_signal**: `add X and tell me what wiki knows about Y`
- **matched_process**: process-ingest.json → process-query.json (chain)
- **confidence**: low
- **last_used**: 2026-07-08
- **usage_count**: 1+
- **examples**: ["Add this article and tell me what the wiki knows about Symfony"]
- **routing_notes**: Ingest first → then query on same topic from result

### Pattern: Ambiguous (No clear signal)
- **user_signal**: short vague message, no keywords match
- **matched_process**: clarify with user → then route
- **confidence**: low
- **last_used**: 2026-07-08
- **usage_count**: 1+
- **examples**: ["X", "Y thing"]
- **routing_notes**: Ask user: "Do you want to query wiki or add a source?"

## Stale Patterns (marked for prune)

_No stale patterns currently._

---

*Created: 2026-07-08. Last updated by agent after successful routing.*
*Decay rule: entries without usage >30 days AND usage_count < 2 → marked stale during lint check_id=16.*
