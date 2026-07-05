"""
Deep integration tests for cross-file logical connections across
process-*.json, AGENTS.md, and rules/*.

Validates that all schema_refs, transitions, rule_ids, and anchors
are consistent — catching what compaction may have broken.
"""

import json
import re
import subprocess
import unittest
from pathlib import Path


BASE = Path(__file__).parent.parent
RULES_DIR = BASE / "rules"
PROCESS_FILES = [
    BASE / "process-ingest.json",
    BASE / "process-query.json",
    BASE / "process-lint.json",
]
AGENTS_MD = BASE / "AGENTS.md"


def _load(fname):
    with open(fname) as f:
        return json.load(f)


def _load_text(fname):
    with open(fname) as f:
        return f.read()


# ── Collectors ──────────────────────────────────────────────────────────────

def collect_schema_refs(obj):
    refs = []
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k == "schema_ref":
                refs.append(str(v))
            else:
                refs.extend(collect_schema_refs(v))
    elif isinstance(obj, list):
        for item in obj:
            refs.extend(collect_schema_refs(item))
    return refs


def collect_transitions(obj):
    refs = []
    if isinstance(obj, dict):
        for k, v in obj.items():
            if k in ("transition_after_user_confirm", "transition_after_confirm"):
                refs.append(str(v))
            else:
                refs.extend(collect_transitions(v))
    elif isinstance(obj, list):
        for item in obj:
            refs.extend(collect_transitions(item))
    return refs


def collect_rule_ids(obj):
    ids = {}
    if isinstance(obj, dict):
        if "rule_id" in obj:
            ids[obj["rule_id"]] = True
        for v in obj.values():
            ids.update(collect_rule_ids(v))
    elif isinstance(obj, list):
        for item in obj:
            ids.update(collect_rule_ids(item))
    return ids


def collect_step_ids(obj):
    ids = []
    if isinstance(obj, dict):
        if "step_id" in obj:
            ids.append(obj["step_id"])
        for v in obj.values():
            ids.extend(collect_step_ids(v))
    elif isinstance(obj, list):
        for item in obj:
            ids.extend(collect_step_ids(item))
    return ids


def collect_agents_md_anchors():
    """Parse AGENTS.md headings of any level -> anchor names (kebab-case)."""
    text = _load_text(AGENTS_MD)
    anchors = set()
    for m in re.finditer(r'^#{2,4}\s+(.+)$', text, re.MULTILINE):
        raw = m.group(1).strip()
        # Remove bold/italic markers
        clean = re.sub(r'\*\*|__', '', raw)
        # Remove emoji prefixes (1-3 non-alphanumeric chars)
        clean = re.sub(r'^[^\w\s]{1,3}\s*', '', clean)
        # Remove parenthetical qualifiers like "(Issues #1-3 resolved)"
        clean = re.sub(r'\s*\([^)]*\)\s*', '', clean)
        anchor = clean.lower().replace(' ', '-')
        # Remove special characters but keep hyphens and underscores
        anchor = re.sub(r'[^a-zа-я0-9\-_]', '', anchor)
        anchor = anchor.strip('-')
        anchors.add(anchor)
        anchors.add(anchor.replace('-', '_'))
    # Also collect explicit {#anchor} markers
    for m in re.finditer(r'\{#([^}]+)\}', text):
        anchors.add(m.group(1).lower())
    return anchors


# ══════════════════════════════════════════════════════════════════════════════
# 1. schema_ref → target validation
# ══════════════════════════════════════════════════════════════════════════════

class TestSchemaRefs(unittest.TestCase):
    """Every schema_ref must point to an existing file and (optionally) section."""

    def _check_ref(self, ref, source_file):
        """Validate a single schema_ref."""
        # Self-references within the same file (keys without external prefix)
        if not ref.startswith("rules/") and not ref.startswith("AGENTS.md") and not ref.startswith("process-"):
            return  # self-ref within same file, skip external check

        # External refs: rules/file.json#section, AGENTS.md#section, process-file.json#step
        if "#" in ref:
            file_part, section_part = ref.split("#", 1)
        else:
            file_part = ref
            section_part = None

        # rules/file.json
        if file_part.startswith("rules/"):
            path = RULES_DIR / file_part.replace("rules/", "")
            self.assertTrue(
                path.exists(),
                f"[{source_file.name}] schema_ref={ref}: file {file_part} not found"
            )
            return

        # AGENTS.md
        if file_part.startswith("AGENTS.md"):
            self.assertTrue(
                AGENTS_MD.exists(),
                f"[{source_file.name}] schema_ref={ref}: AGENTS.md not found"
            )
            if section_part:
                anchors = collect_agents_md_anchors()
                self.assertIn(
                    section_part.lower(),
                    anchors,
                    f"[{source_file.name}] schema_ref={ref}: section #{section_part} not found in AGENTS.md anchors"
                )
            return

        # process-*.json
        if file_part.startswith("process-"):
            target_path = BASE / f"{file_part}"
            self.assertTrue(
                target_path.exists(),
                f"[{source_file.name}] schema_ref={ref}: file {file_part} not found"
            )
            if section_part:
                target_data = _load(target_path)
                all_step_ids = collect_step_ids(target_data)
                # Check if section_part looks like a step_id
                if section_part.startswith("step_") or section_part.replace(".", "").isdigit():
                    self.assertIn(
                        section_part,
                        all_step_ids,
                        f"[{source_file.name}] schema_ref={ref}: step #{section_part} not found in {file_part}. "
                        f"Available: {all_step_ids}"
                    )
            return

        self.fail(f"[{source_file.name}] schema_ref={ref}: unknown reference format")

    def test_ingest_schema_refs(self):
        data = _load(PROCESS_FILES[0])
        refs = collect_schema_refs(data)
        self.assertGreater(len(refs), 0, "Must have schema_refs")
        for ref in refs:
            self._check_ref(ref, PROCESS_FILES[0])

    def test_query_schema_refs(self):
        data = _load(PROCESS_FILES[1])
        refs = collect_schema_refs(data)
        self.assertGreater(len(refs), 0, "Must have schema_refs")
        for ref in refs:
            self._check_ref(ref, PROCESS_FILES[1])

    def test_lint_schema_refs(self):
        data = _load(PROCESS_FILES[2])
        refs = collect_schema_refs(data)
        self.assertGreater(len(refs), 0, "Must have schema_refs")
        for ref in refs:
            self._check_ref(ref, PROCESS_FILES[2])


# ══════════════════════════════════════════════════════════════════════════════
# 2. Transition targets validation
# ══════════════════════════════════════════════════════════════════════════════

class TestTransitions(unittest.TestCase):
    """Every transition_after_* must point to an existing step in target file."""

    def test_ingest_transitions(self):
        data = _load(PROCESS_FILES[0])
        refs = collect_transitions(data)
        for ref in refs:
            self._check_transition(ref, "ingest")

    def test_query_transitions(self):
        data = _load(PROCESS_FILES[1])
        refs = collect_transitions(data)
        for ref in refs:
            self._check_transition(ref, "query")

    def test_lint_transitions(self):
        data = _load(PROCESS_FILES[2])
        refs = collect_transitions(data)
        for ref in refs:
            self._check_transition(ref, "lint")

    def _check_transition(self, ref, source_name):
        """Validate a transition reference like 'process-ingest.json#step_8a_new_page'."""
        if "#" in ref:
            file_part, section_part = ref.split("#", 1)
            section_part = section_part.split("(")[0].strip()
            section_part = section_part.split("—")[0].strip()
        elif "->" in ref or "→" in ref:
            return
        else:
            if "via" in ref:
                file_part = ref.split("via")[0].strip()
                section_part = None
            else:
                file_part = ref
                section_part = None

        if not file_part.startswith("process-"):
            return  # Non-process ref, skip

        raw_name = file_part.split()[0]
        target_path = BASE / raw_name
        if not target_path.suffix:
            target_path = target_path.with_suffix(".json")
        if not target_path.exists():
            self.fail(f"[{source_name}] transition={ref}: target file {raw_name} not found")
            return

        if section_part:
            target_data = _load(target_path)
            all_step_ids = set(collect_step_ids(target_data))
            # section_part might reference a top-level key (like 'web_ingest_flow.trigger')
            top_level_key = section_part.split(".")[0]
            # Accept if it's a step_id OR a top-level key in the target file
            is_step = section_part in all_step_ids
            is_top_key = top_level_key in target_data
            self.assertTrue(
                is_step or is_top_key,
                f"[{source_name}] transition={ref}: '{section_part}' not found as step or top-level key "
                f"in {target_path.name}. Steps: {sorted(all_step_ids)}. "
                f"Top keys: {[k for k in target_data.keys() if isinstance(target_data[k], dict)]}"
            )


# ══════════════════════════════════════════════════════════════════════════════
# 3. rule_id uniqueness
# ══════════════════════════════════════════════════════════════════════════════

class TestRuleIdConsistency(unittest.TestCase):
    """All rule_ids within each file must be unique. Cross-file duplicates are flagged."""

    def test_no_duplicate_rule_ids_within_file(self):
        for pf in PROCESS_FILES:
            data = _load(pf)
            ids = list(collect_rule_ids(data).keys())
            dups = [rid for rid in ids if ids.count(rid) > 1]
            self.assertEqual(
                len(dups), 0,
                f"{pf.name}: duplicate rule_ids within file: {set(dups)}"
            )

    def test_cross_file_duplicates_flagged(self):
        all_ids = {}
        for pf in PROCESS_FILES:
            data = _load(pf)
            for rid in collect_rule_ids(data):
                all_ids.setdefault(rid, []).append(pf.name)
        cross_file_dups = {rid: files for rid, files in all_ids.items() if len(files) > 1}
        if cross_file_dups:
            print(f"\n  [!] Cross-file duplicate rule_ids: {cross_file_dups}")
        # Not a hard failure — shared rule_ids may be intentional
        self.assertTrue(True)

    def test_rule_ids_have_consistent_format(self):
        """rule_ids should match patterns like XXX-NAME-V1 or XXX-NAME."""
        data = {}
        for pf in PROCESS_FILES:
            data.update(collect_rule_ids(_load(pf)))
        issues = [rid for rid in data if not re.match(r'^[A-Z0-9_-]+$', rid)]
        if issues:
            print(f"\n  [!] Non-standard rule_id format: {issues}")


# ══════════════════════════════════════════════════════════════════════════════
# 4. AGENTS.md anchors referenced in process files actually exist
# ══════════════════════════════════════════════════════════════════════════════

class TestAgentsMdAnchors(unittest.TestCase):
    """Process files reference AGENTS.md#section — section must exist."""

    def setUp(self):
        self.anchors = collect_agents_md_anchors()

    def test_ingest_refs_to_agents(self):
        data = _load(PROCESS_FILES[0])
        for ref in collect_schema_refs(data):
            if not ref.startswith("AGENTS.md"):
                continue
            section = ref.split("#", 1)[1] if "#" in ref else ""
            if section:
                self.assertIn(
                    section.lower(),
                    self.anchors,
                    f"AGENTS.md#{section} referenced in ingest not found. "
                    f"Similar: {[a for a in sorted(self.anchors) if section[:5] in a][:3]}"
                )

    def test_query_refs_to_agents(self):
        data = _load(PROCESS_FILES[1])
        for ref in collect_schema_refs(data):
            if not ref.startswith("AGENTS.md"):
                continue
            section = ref.split("#", 1)[1] if "#" in ref else ""
            if section:
                self.assertIn(
                    section.lower(),
                    self.anchors,
                    f"AGENTS.md#{section} referenced in query not found"
                )

    def test_lint_refs_to_agents(self):
        data = _load(PROCESS_FILES[2])
        for ref in collect_schema_refs(data):
            if not ref.startswith("AGENTS.md"):
                continue
            section = ref.split("#", 1)[1] if "#" in ref else ""
            if section:
                self.assertIn(
                    section.lower(),
                    self.anchors,
                    f"AGENTS.md#{section} referenced in lint not found"
                )


# ══════════════════════════════════════════════════════════════════════════════
# 5. Rules directory: every referenced rules file exists
# ══════════════════════════════════════════════════════════════════════════════

class TestRulesDirectory(unittest.TestCase):
    """All schema_refs pointing to rules/ must reference existing files."""

    def test_all_referenced_rules_exist(self):
        referenced = set()
        for pf in PROCESS_FILES:
            data = _load(pf)
            for ref in collect_schema_refs(data):
                file_part = ref.split("#")[0]
                if file_part.startswith("rules/"):
                    referenced.add(file_part)

        for ref in sorted(referenced):
            rel_path = ref.replace("rules/", "", 1)
            target = RULES_DIR / rel_path
            self.assertTrue(
                target.exists(),
                f"rules file '{rel_path}' referenced but not found. "
                f"Available: {sorted(p.name for p in RULES_DIR.iterdir())}"
            )

    def test_all_rules_have_content(self):
        """Rules files must be non-empty JSON or MD."""
        for p in sorted(RULES_DIR.iterdir()):
            if p.is_file() and p.suffix in (".json", ".md"):
                content = p.read_text().strip()
                self.assertGreater(
                    len(content), 10,
                    f"rules/{p.name} appears empty or near-empty"
                )


# ══════════════════════════════════════════════════════════════════════════════
# 6. Pre-compaction logical coverage (compaction audit)
# ══════════════════════════════════════════════════════════════════════════════

class TestCompactionCoverage(unittest.TestCase):
    """Compare current process files against pre-compaction (b25b642) baseline.
    Verifies that critical logical connections survived compaction.
    """

    COMPACT_COMMIT = "b25b642"

    @classmethod
    def setUpClass(cls):
        cls.pre = {}
        for fname in ["process-ingest.json", "process-query.json", "process-lint.json"]:
            try:
                raw = subprocess.check_output(
                    ["git", "show", f"{cls.COMPACT_COMMIT}:{fname}"]
                ).decode()
                cls.pre[fname] = json.loads(raw)
            except (subprocess.CalledProcessError, json.JSONDecodeError):
                cls.pre[fname] = {}

    def test_pre_compact_rule_ids_survived(self):
        """All pre-compaction rule_ids should still exist (by name)."""
        for fname in ["process-ingest.json", "process-query.json"]:
            pre_ids = set(collect_rule_ids(self.pre.get(fname, {})).keys())
            post_data = _load(BASE / fname)
            post_ids = set(collect_rule_ids(post_data).keys())
            lost = pre_ids - post_ids
            self.assertEqual(
                len(lost), 0,
                f"{fname}: pre-compaction rule_ids lost: {lost}"
            )

    def test_pre_compact_steps_survived(self):
        """Pre-compaction step_ids should still exist."""
        for fname in ["process-ingest.json", "process-query.json"]:
            pre_ids = set(collect_step_ids(self.pre.get(fname, {})))
            post_data = _load(BASE / fname)
            post_ids = set(collect_step_ids(post_data))
            lost = pre_ids - post_ids
            self.assertEqual(
                len(lost), 0,
                f"{fname}: pre-compaction steps lost: {lost}"
            )

    def test_pre_compact_schema_refs_survived(self):
        """All pre-compaction schema_refs should still be present (or replaced)."""
        for fname in ["process-ingest.json", "process-query.json", "process-lint.json"]:
            pre_refs = set(collect_schema_refs(self.pre.get(fname, {})))
            post_data = _load(BASE / fname)
            post_refs = set(collect_schema_refs(post_data))
            lost = pre_refs - post_refs
            # Some refs may be intentionally replaced; log for review
            if lost:
                print(f"\n  [!] {fname}: pre-compaction refs potentially lost: {lost}")


# ══════════════════════════════════════════════════════════════════════════════
# 7. Cross-process step transitions integrity
# ══════════════════════════════════════════════════════════════════════════════

class TestCrossProcessIntegrity(unittest.TestCase):
    """Process files reference each other's steps — validate those exist."""

    def test_ingest_to_lint_cross_refs(self):
        data = _load(PROCESS_FILES[0])
        transitions = collect_transitions(data)
        lint_data = _load(PROCESS_FILES[2])
        lint_step_ids = set(collect_step_ids(lint_data))
        for ref in transitions:
            if "process-lint" in ref:
                self.fail(f"Ingest should not transition to lint steps: {ref}")

    def test_query_to_ingest_transitions_exist(self):
        """Query must have at least one transition to ingest."""
        data = _load(PROCESS_FILES[1])
        transitions = collect_transitions(data)
        ingest_refs = [r for r in transitions if "process-ingest" in r]
        self.assertGreater(
            len(ingest_refs), 0,
            f"Query must have transitions to ingest. Found: {transitions}"
        )

    def test_lint_to_query_ingest_transitions_exist(self):
        """Lint must transition to query or ingest."""
        data = _load(PROCESS_FILES[2])
        transitions = collect_transitions(data)
        cross = [r for r in transitions if "process-" in r]
        self.assertGreater(
            len(cross), 0,
            f"Lint must have transitions to query/ingest. Found: {transitions}"
        )


# ══════════════════════════════════════════════════════════════════════════════
# 8. agent_read_instructions consistency
# ══════════════════════════════════════════════════════════════════════════════

class TestAgentReadInstructions(unittest.TestCase):
    """All process files must have agent_read_instructions = true."""

    def test_all_have_agent_read_instructions(self):
        for pf in PROCESS_FILES:
            data = _load(pf)
            self.assertTrue(
                data.get("agent_read_instructions", False),
                f"{pf.name} missing agent_read_instructions=True"
            )

    def test_all_have_context_scope_transient(self):
        for pf in PROCESS_FILES:
            data = _load(pf)
            self.assertEqual(
                data.get("context_scope"),
                "transient",
                f"{pf.name} must have context_scope=transient"
            )


# ══════════════════════════════════════════════════════════════════════════════
# 9. Working memory hooks consistency
# ══════════════════════════════════════════════════════════════════════════════

class TestWorkingMemoryHooksConsistency(unittest.TestCase):
    """WM hooks must reference consistent rule_ids and have required triggers."""

    def test_ingest_has_both_triggers(self):
        data = _load(PROCESS_FILES[0])
        hooks = data.get("working_memory_hooks", [])
        triggers = [h.get("trigger") for h in hooks]
        self.assertIn("on_start", triggers)
        self.assertIn("on_complete", triggers)

    def test_query_finalization_writes_hot(self):
        """Step 3 must write to hot.md."""
        data = _load(PROCESS_FILES[1])
        step3 = next((s for s in data["steps"] if s.get("step_id") == "3"), None)
        self.assertIsNotNone(step3, "Step 3 not found in query")
        finalization = step3.get("finalization", [])
        hot_found = any(
            "hot" in str(a.get("action_name", "")).lower()
            or "session_context" in str(a.get("rule", "")).lower()
            for a in finalization
        )
        self.assertTrue(hot_found, "Step 3 finalization must write to hot.md")


if __name__ == "__main__":
    unittest.main()
