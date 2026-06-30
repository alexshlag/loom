# Wiki Log

## [2026-06-30] lint | Audit: 5 issues found (2 contradictions, 3 orphan pages)
  - Contradictions: 2 pairs detected — agent review required to resolve stale vs fresh facts
  - Orphan pages: 3 pages with zero backlinks — need cross-references or cleanup
  - Broken links: ✅ 0 (all links valid after ../ path resolution fix)
  - Text similarity overlaps: ✅ 0 (no ≥90% copy chains)
  - Date consistency: ✅ OK

## [2026-06-30] process | Query Intent Decoder (QID) mechanism added
  - Добавлен step 0.5 в process-query.json: query_intent_decoder для расшифровки метафор и ассоциаций пользователя
  - Pattern recognition: "окунёмся", "дай мне из" → query_wiki intent
  - Decision logic: if wiki empty → warn_with_humor; if has data → proceed_to_search_flow

## [2026-06-30] schema | Auto-cleanup rule for working_memory.json next_steps_todo
  - Добавлено правило: перед каждым write() agent обязан отфильтровать completed задачи из next_steps_todo
  - broken_links_resolved — audit trail, не удалять. next_steps_todo и open_pages — чистить.

## [2026-06-30] schema | Execution Contract added (proposal → action)
  - Agent never stops after proposing a plan or asking permission to execute
  - User says *what* they want. Agent decides *how* and acts immediately.

## [2026-06-30] schema | Harness-Independent Session & Git Operations complete
