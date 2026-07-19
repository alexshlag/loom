# Loomana Project Plan

---

## 🔄 Active / Pending Phases

### Phase 19 (Continued): Filename Collision Resolution

**T6: Filename collision resolution strategy** — lint detects collisions (filename-audit.sh + process-ingest check_filename_collision), but no policy exists for *choosing* between colliding names. Need to define: (a) tie-breaking rules (e.g., project prefix wins over bare name, most specific wins), (b) when to escalate to user vs auto-resolve, (c) how to document the decision. Agent currently has no guidance beyond "use rename-page.sh".

| # | Task | Description | Priority | Status |
|---|------|-------------|----------|--------|
| **T6** | **Filename collision resolution strategy** | Define policy for choosing between colliding names | 🟡 P2 MEDIUM | ⬜ Pending |

---

> Last update: 2026-07-19 | **Pending:** T6 (filename collision). | **Closed:** N6, D1, T5.

