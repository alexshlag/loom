# Test wiki change for harness-independent operations
# Wiki Hot Cache — Last Updated: 2026-06-30

## Active Threads
- Harness-independent session & git automation (NEW) — implementing hot cache, auto-commit, PostCompact recovery to replace claude-obsidian hooks with harness-independent scripts
- External sources update policy refinement (Issues #1-3 from AGENTS.md)

## Recent Changes
- **2026-06-29**: Created `wiki/comparisons/loom-vs-claude-obsidian.md` — comparative analysis of two LLM Wiki Companion projects, highlighting LOOM's depth in knowledge processing vs claude-obsidian's breadth in automation
- **2026-06-29**: Updated `comparisons/symfony-ux-packages` and `comparisons/llm-wiki-implementations` with backlinks
- **2026-06-26**: Fixed post_search_flow algorithm — added raw/sources check → web_availability_check → auto-web_search branching in process-query.json
- **2026-06-26**: Added web_ingest_flow transition from web_search results to wiki page creation (6-step flow)

## Key Recent Facts
- LOOM uses working_memory.json for session metadata; claude-obsidian uses wiki/hot.md for fact context — two complementary approaches
- claude-obsidian's hooks.json provides automatic PostToolUse/SessionStart/PostCompact/Stop automation but is Claude Code-specific
- Our solution: harness-independent scripts (git-auto-commit.sh, load-hot-cache.sh, restore-hot-cache.sh, check-wiki-changes.sh) that work identically in Pi, Claude Code, Codex, etc.
