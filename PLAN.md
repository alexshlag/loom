# Loomana Project Plan

---

## 🔄 Active / Pending Phases

### Phase 19 (Continued): Filename Collision Resolution

**T6: Filename collision resolution strategy** — ✅ Implemented. Tie-breaking rules (3 levels), collision detection in filename-audit.sh, collision_resolution step in process-ingest, --log flag in rename-page.sh.

| # | Task | Description | Priority | Status |
|---|------|-------------|----------|--------|
| ~~T6-1~~ | ~~Define rule file~~ `rules/filename_collision_strategy.json` | Tie-breaking rules (3 levels), decision matrix (auto vs escalate), rename policy | 🟡 P2 | ✅ Done |
| ~~T6-2~~ | ~~Extend~~ `scripts/filename-audit.sh` | Detect bare-name vs prefixed-name collisions across wiki subdirectories | 🟡 P2 | ✅ Done |
| ~~T6-3~~ | ~~Update~~ `process-ingest.json` | Add `collision_resolution` step: audit → apply tie-breaking → auto-rename or escalate | 🟡 P2 | ✅ Done |
| ~~T6-4~~ | ~~Update~~ `scripts/rename-page.sh` | Add `--log` flag to auto-append `# Renamed` section in frontmatter | 🟢 P3 LOW | ✅ Done |
| ~~T5~~ | ~~Run audit~~ on existing wiki | Verify strategy catches real collisions in current wiki state | 🟢 P3 | ✅ Done |

---

> Last update: 2026-07-19 | **Pending:** none. | **Closed:** N6, D1, T5, T6.

