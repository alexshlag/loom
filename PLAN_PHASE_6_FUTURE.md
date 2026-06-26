# Phase 6 Future Architecture — Context Management Strategies

## Текущее состояние (MVP)
✅ `meta/search_history.json` — история запросов с intent detection + topic tags  
✅ `wiki-search.sh` — context bias → priority queue adjustment  
✅ Auto-save after each query (compact window: last 5 entries)  

## Будущие расширения

### Context Bubbles (приоритет: High)
- **Идея**: Держать в контексте только 3-4 релевантные wiki-страницы одновременно
- **Механизм**: 
  - Agent read → page A, page B → push context bubble
  - Если query меняется → detect topic shift → clear old bubble → load new pages
  - Wiki pages remain accessible via links (no need to keep full text)

### Wiki as Swap Space (приоритет: Medium)
- **Идея**: Использовать wiki как "swap" для расширения контекстного окна LLM
- **Механизм**:
  - При overflow context → agent выгружает полные тексты в `meta/swap/*.md`
  - Хранит только ссылки + summaries (H1 + first sentence)
  - При необходимости загрузки → agent читает swap → восстанавливает контекст

### Relevance Markers (приоритет: High)
- **Идея**: Каждая query помечается relevance score для последующей compaction
- **Механизм**:
  ```json
  {
    "query": "...",
    "relevance": 0.9,  // high importance for current project/topic
    "expires_at": "2026-07-01T00:00:00"  // auto-compaction after expiry
  }
  ```

### Auto-Compaction Triggers (приоритет: Medium)
- **Идея**: Автоматическая очистка context window при:
  - Topic switch detected (no keyword overlap with previous queries)
  - Context window approaching limit (e.g., >80% of token budget)
  - Time-based expiry (queries older than X hours → mark as superseded)

## Дискуссия с пользователем (pending approval)
- [ ] Context bubbles — как agent управляет 3 active pages одновременно?
- [ ] Wiki-swap — выгрузка полных текстов при overflow context window
- [ ] Relevance markers — auto-compaction expired queries
- [ ] Topic reset triggers — когда clear context vs когда continue same topic

## Next Actions
1. **Context bubbles prototype**: 3 active pages → switch when topic changes  
2. **Wiki-swap structure**: `meta/swap/*.md` format (H1 + first 3 sentences)  
3. **Auto-compaction rules**: expiry thresholds + relevance scoring  

*Last update: 2026-06-27 | Phase 6 MVP done, future extensions pending discussion*
