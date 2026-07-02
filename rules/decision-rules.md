# Decision Rules — System Inference Protocol

## 🧠 Overview

Система даёт сигналы (`scripts detect`), агент делает logical inference. **Ручные веса через скрипты = запрещены.** Agent evaluates rules from this table.

### Design Principles

| Principle | Rule |
|-----------|------|
| **Scripts detect, agent evaluates** | `text-similarity.sh` reports overlap → no automatic penalty/boost. Agent interprets context. |
| **No authority override without authorship** | Authority source wins only on attribution: «A said X» vs «B reported that A said Y». If B corrected A with evidence → B > A regardless of authority status. |
| **Co-evolution via discussion** | New rules added through dialog, not hardcoded. Each rule gets ID (`DR-N`) for traceability. |

### Decision Rules Table

| Rule ID | Scenario | Agent Logic | Outcome |
|---------|----------|-------------|---------|
| **DR-1** | Source overlap ≥90% detected by `text-similarity.sh` | Script reports raw overlap only. No automatic weight change. | Neutral — agent evaluates context |
| **DR-2** | Source B corrected A's error with evidence | B provided fix + proof (code, logs, authoritative source). | B > A on the corrected claim |
| **DR-3** | Authorship attribution conflict | «A said X» vs «B reported that A said Y». | A wins original claim; B gets credit only for reporting |
| **DR-4** | Syntheses / Summary creation | `syntheses/` = priority search layer. Auto-create summary page when answer aggregates ≥3 wiki pages. For external/web sources → propose to user, create only with approval. | Priority: syntheses > concepts > entities in search |
| **DR-5** | Time decay for FAQ pages | If summary `last_seen` > 30 days without queries → apply -50% popularity boost (via topics{} scoring). Agent can merge into fresher page or mark stale — but never auto-delete. | Decay signal, not delete trigger |

### Process

1. **Detect**: Script reports signal (overlap, contradiction, similarity)
2. **Evaluate**: Agent reads context → applies relevant DR from table above
3. **Log**: См. `process-query.json#contradiction_resolution_flow.logging_actions`. Записать решение в log.md. Всегда append (`>>`), never overwrite.
4. **Evolve**: New scenarios → discuss → add new rule to table → commit

---

**Schema ref**: `AGENTS.md#decision_rules` — canonical source for agent evaluation logic.  
**Location**: `decision-rules.md` — system-level rules, always loaded before inference decisions.
