---
tags: [extension, customization, schema-evolution]
date: 2026-07-08
type: documentation
category: docs
aliases: [customization, adding-categories, adding-scripts, new-rules]
sources: [docs/extending-wiki.md, AGENTS.md, process-ingest.json]
related: [docs/architecture.md, docs/scripts-guide.md, rules/categories.json]
---

# Extending the Wiki System

Loomana is designed to grow with you. As your knowledge base expands, you'll naturally need new page types, custom scripts, or additional rules — and Loomana makes it easy to extend without breaking existing workflows. This guide covers how to add:

- New wiki categories
- Custom scripts
- New rules & conventions
- Schema changes via `[schema-patch]`

---

## Adding a New Wiki Category

Categories define where pages live and how they're routed during ingest. To add a new category:

### Step 1: Define the Category

Edit `rules/categories.json` and add your category definition:

```json
{
  "new_category": {
    "name": "new_category",
    "description": "What this category stores — e.g., 'Prototypes and experiments'",
    "path_pattern": "wiki/new_category/<name>.md",
    "routing_rule": "If a source matches <criteria>, route to wiki/new_category/"
  }
}
```

**Requirements:**
- `description` must explain the category's purpose in plain language (agent reads this on every page creation)
- `path_pattern` defines where pages will live — use `wiki/<category>/<name>.md` format
- `routing_rule` tells the agent when to create a new page here vs. adding to an existing category

### Step 2: Create a Template (Optional but Recommended)

Create `wiki/templates/new_category-template.json` with recommended sections for pages in this category. The template doesn't enforce structure — it guides the agent's content creation:

```json
{
  "template_id": "new_category",
  "recommended_sections": [
    {"section": "Definition", "description": "What is this thing?"},
    {"section": "Examples", "description": "Real-world usage scenarios"},
    {"section": "Related Pages", "description": "Crosslinks to other wiki pages"}
  ]
}
```

### Step 3: Update Ingest Routing

The ingest workflow reads `categories.json` via `schema_ref`. New categories automatically propagate through the auto-crosslink system — no hardcoded paths needed. The agent will:

1. Detect when a source matches your category's criteria (via content analysis)
2. Create a page in `wiki/<category>/<name>.md` following the path pattern
3. Auto-suggest crosslinks based on semantic similarity to existing pages

> **No process file changes needed** — categories.json is read dynamically by all scripts via schema_ref. New rules are discovered automatically at session start.

---

## Adding a Custom Script

Scripts handle automation tasks — metadata rebuilds, lint checks, source validation. To add your own:

### Conventions to Follow

Every script must follow these rules (enforced by the agent during creation):

| Convention | Example |
|------------|---------|
| **Strict mode** | `set -euo pipefail` at the top of every `.sh` file |
| **Help flag** | Must support `--help` or `-h` for usage info |
| **Exit codes** | 0 = success, >0 = error (never silently swallow failures) |
| **Path quoting** | All variables quoted: `"${var}"` — never unquoted |
| **JSON via Python/jq** | Never use `echo` or `printf` to construct JSON — always use Python's `json.dumps()` or jq |
| **Markdown via awk/sed/grep** | Standard text processing tools only |
| **Source lib.sh** | If your script writes files, source `scripts/lib.sh` and call `_set_cleanup_trap()` for temp file cleanup |

### Where to Put Your Script

```
scripts/
├── my-new-script.sh      ← New scripts go here (in the root scripts directory)
└── memory/               ← Memory-related scripts in subdirectories
    ├── recall.sh
    └── traj-capture.sh
```

### Registering a New Script as a Lint Check

If your script validates wiki pages and should run during `scripts/lint.sh`, add it to the process file:

```json
{
  "step_id": "mechanical_linting",
  "checks": [
    {
      "check_id": 16,           // Increment the ID number
      "script_name": "my-new-script.sh",
      "rule": "rules/my-validation-rule.json",
      "description": "Checks for X pattern in wiki pages"
    }
  ]
}
```

The agent reads this array during lint workflow — it will call your script and parse the JSON output. No additional wiring needed beyond adding to the checks array.

---

## Adding New Rules & Conventions

Rules are technical specifications stored in `rules/*.json`. They define policies, patterns, and algorithms that the agent follows via `schema_ref`:

### When to Create a Rule File

Create a new rule file when:
- You have a policy that applies across multiple scripts/processes (e.g., "all wikilinks must use wiki-relative paths")
- There's an algorithm with conditional logic that shouldn't be duplicated in process files
- You want to extract guidance from AGENTS.md into a reusable, lazy-loaded reference

### Rule File Format

Rules are JSON files with optional markdown comments:

```json
{
  "rule_id": "MY-RULE-V1",
  "description": "What this rule governs and why",
  "conditional_logic": {
    // If-then logic, priority cascades, validation patterns
    "if_condition": "...",
    "then_action": "..."
  }
}
```

**Naming convention:** Use descriptive snake_case filenames that match the concept being governed. Examples: `link_conventions.json`, `evidence_grade.json`, `error_handling.json`.

### Referencing Your Rule

Reference it from process files via `schema_ref` — never duplicate content inline:

```json
{
  "step_id": "create_page",
  "action": {
    "rule": "rules/my-new-rule.json"   // Agent reads this on demand
  }
}
```

### Updating AGENTS.md (Optional)

If your rule is important enough to be mentioned at session start, add a brief reference to AGENTS.md under the "Rules & Conventions" section. The agent will read it once at boot and then follow schema_ref for actual content:

> **Mandatory rules referenced in process files:** `my-new-rule.json` (governs X behavior). Agent reads via schema_ref — no duplication.

---

## Schema Evolution via `[schema-patch]`

If you want to change how the wiki behaves fundamentally (not just add a category or script), use the `[schema-patch]` command:

### When to Use It

- Adding a new field to universal frontmatter
- Changing how contradictions are resolved
- Restructuring process workflows significantly
- Modifying template structures across multiple categories

### How to Propose a Change

Tell your agent:

> "[schema-patch] I want to add a 'version' field to all wiki page frontmatter."

The agent will:

1. **Analyze impact** — which scripts need updates? Which process files reference this field?
2. **Propose implementation plan** — list of files to modify, order of operations
3. **Wait for approval** — schema changes require explicit user go-ahead (never auto-modify)
4. **Implement and verify** — apply changes, run validation scripts, confirm no regressions

### Example: Adding a Frontmatter Field

```
User: "[schema-patch] Add 'version' field to universal frontmatter"

Agent proposes:
1. Update AGENTS.md → add "version" to Universal Frontmatter table
2. Update wiki/templates/*.json → add version to all template sections
3. Update scripts/rebuild-meta.sh parse_frontmatter() → read and store version
4. Update scripts/lint.sh check_version → flag missing/invalid versions
5. Commit: schema | frontmatter: add version field + lint validation

User: "Approved"

Agent applies changes across all files, commits, runs validation.
```

---

## Adding Web Search Sources

If you want the agent to search additional domains during queries (beyond web_search defaults):

### Whitelist a Domain

Edit `tracking/domain_whitelist.json`:

```json
{
  "approved_domains": [
    // Existing domains...
    "new-research-domain.com",   // Add your domain here
    "*.subdomain.example.org"     // Wildcard subdomains supported
  ]
}
```

The agent will only fetch content from approved domains during query workflows — this prevents random crawling and keeps searches focused on trusted sources.

---

## Customizing Memory Behavior

### Adjusting Hot Cache Refresh Rate

If you want the hot cache refreshed more frequently (or less), modify `process-query.json` step_0.25:

```json
{
  "action": "refresh_hot_cache",
  "interval_seconds": 300   // Change from default to your preferred interval
}
```

### Adding Memory Triggers

Add new memory hooks in process files (defined in `session_context_rules.json#save_triggers`). Each trigger fires a specific action when the condition is met:

| Trigger | When It Fires | Action Taken |
|---------|--------------|--------------|
| `on_contradiction_detected` | Lint finds conflicting facts across pages | Auto-save contradiction pair to WM |
| `on_new_source_ingested` | After successful ingest step_8_complete | Update hot.md with new page details |
| `on_query_completed` | Agent returns a synthesized answer | Save query_summary in working_memory.json |

To add a custom trigger:

1. Add it to `session_context_rules.json` under `save_triggers` section
2. Reference it in the process file's memory_hooks array
3. Define what action fires when the condition is met

---

## Workflow Customization

### Modifying Ingest Behavior

The ingest workflow flows through `process-ingest.json`. To customize:

1. **Add a new step** — Insert into steps array with unique `step_id`
2. **Modify existing step** — Change the action_name or rule reference
3. **Add conditional branching** — Use if-then logic in action definitions (per R07 rules)

### Example: Custom Source Classification

```json
{
  "step_id": "classify_source",
  "action": {
    // Existing default classification...
    // Add custom branch for specific domains:
    "custom_branches": [
      {"domain_pattern": "*.research.org", "target_category": "concepts"},
      {"domain_pattern": "github.com/*-tools", "target_category": "docs"}
    ]
  }
}
```

---

## Summary of Extensibility Points

| What You Want | How to Add It | Files Affected |
|---------------|--------------|----------------|
| New wiki category | Update `rules/categories.json` + optional template | categories.json, templates/ |
| Custom validation script | Write .sh in scripts/, register in process file | scripts/, process-lint.json |
| New rule/convention | Create rules/*.json with conditional logic | rules/new-rule.json, process files |
| Frontmatter field change | `[schema-patch]` proposal + agent implementation | AGENTS.md, templates/*, scripts/ |
| Web search domain whitelist | Add to tracking/domain_whitelist.json | Domain whitelist file only |
| Custom memory trigger | Define in session_context_rules.json + reference in process | Rules JSON, process files |

---

## Next Steps

- [`docs/architecture.md`](architecture.md) — How layers interact when you add new components
- [`rules/session_context_rules.json`](../rules/session_context_rules.md) — Save triggers and memory architecture for custom hooks
- `scripts/lib.sh` — Shared utilities available to all scripts (atomic_write, cleanup_add, log_error, etc.)
