# Migration Protocol: Context Optimization

## 🎯 Goal
Minimize noise in the agent's primary context (`AGENTS.md`) by moving niche technical rules into separate files in `rules/`. This lets the agent consume instructions only when needed for the current role or task.

## 🔄 Algorithm (Cyclic Process)

1.  **Identify**: Find a niche instruction block in `AGENTS.md` (specific rules not part of the core project philosophy).
2.  **Create**: Create a `<rule>.json` (or `.md`) file in `rules/`.
3.  **Migrate**: Rewrite the block content into the new file. Use JSON for structured data, Markdown for narrative rules.
4.  **Verify**: Ensure the new file contains all necessary detail from the original.
5.  **Relink**: Update all references in `AGENTS.md` and `process-*.json` to point to the new `rules/` path.
6.  **Verify Links**: Confirm the agent can successfully read the new file via the reference.
7.  **Remove**: Delete the old block from `AGENTS.md`.
8.  **Commit**: Commit the changes.
9.  **Next**: Repeat for the next block.

## 🛠 Process Rules
- **Do not** delete rules until all references are updated.
- **Keep** a brief rule description in `AGENTS.md` (as a link) so the agent knows the rule exists.
- **Atomic**: One block per cycle. Do not migrate everything at once.
- **Integrity**: After each block removal from `AGENTS.md`, run lint check (`scripts/lint.sh`).
