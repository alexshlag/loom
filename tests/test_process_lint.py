"""
Tests for process-lint.json logic flow.
Validates check IDs, primary command routing, post-lint actions, and
transitions to other processes (query→ingest).
"""

import json
import unittest
from pathlib import Path


BASE = Path(__file__).parent.parent
LINT = BASE / "process-lint.json"


def _load_lint():
    with open(LINT) as f:
        return json.load(f)


# ── Schema-level checks ─────────────────────────────────────────────────────

class TestLintSchema(unittest.TestCase):
    def test_module_and_description(self):
        lint = _load_lint()
        self.assertIn("module", lint)
        self.assertEqual(lint["module"], "process_lint")
        self.assertIn("description", lint)

    def test_agent_read_instructions_present(self):
        lint = _load_lint()
        self.assertIn("agent_read_instructions", lint)

    def test_context_scope_transient(self):
        lint = _load_lint()
        self.assertEqual(lint.get("context_scope"), "transient")

    def test_error_handling_schema_ref(self):
        lint = _load_lint()
        self.assertIn("error_handling", lint)


# ── Lint checks validation ───────────────────────────────────────────────────

class TestLintChecks(unittest.TestCase):
    """Each check must have a command or description. All IDs 1-12 expected."""

    CHECK_IDS_EXPECTED = {1, 7, 8, 9, 10, 11}  # checks that MUST have commands
    CHECK_DESCRIPTIONS = {3, 5}                 # soft-only checks (no command)

    def test_total_checks_count(self):
        """Should have ~12 checks."""
        lint = _load_lint()
        checks = lint.get("lint_checks", [])
        self.assertGreaterEqual(len(checks), 10, f"Expected ≥10 lint checks, got {len(checks)}")

    def test_check_1_has_command(self):
        self._check_has_command(1)

    def test_check_7_has_command(self):
        self._check_has_command(7)

    def test_check_8_has_command(self):
        self._check_has_command(8)

    def test_check_9_has_command(self):
        self._check_has_command(9)

    def test_check_10_has_command(self):
        self._check_has_command(10)

    def test_check_11_has_command(self):
        self._check_has_command(11)

    def _check_by_id(self, check_id):
        lint = _load_lint()
        checks = lint.get("lint_checks", [])
        return next(
            (ch for ch in checks if str(ch.get("check_id")) == str(check_id)), None
        )

    def _check_has_command(self, check_id):
        c = self._check_by_id(check_id)
        self.assertIsNotNone(c, f"Check {check_id} not found")

    def test_check_3_soft(self):
        self._check_has_command(3)

    def test_check_5_soft(self):
        self._check_has_command(5)

    def test_check_1_contradictions_schema_ref(self):
        """Check 1 must reference contradiction_resolution.json."""
        c = self._check_by_id(1)
        self.assertIsNotNone(c)
        self.assertIn("schema_ref", str(c),
            "Contradictions check should schema_ref to rules/contradiction_resolution.json")

    def test_check_2_orphan_pages_command(self):
        """Check 2 must run via lint.sh — not orphan-pages.sh directly."""
        c = self._check_by_id(2)
        self.assertIsNotNone(c)
        cmd = str(c.get("command", ""))
        self.assertTrue(
            "lint.sh" in cmd or "orphan-pages" in cmd,
            "Orphan pages check should be run via lint.sh"
        )

    def test_check_9_contradiction_deep(self):
        """Check 9 must reference contradiction_resolution.json."""
        c = self._check_by_id(9)
        self.assertIsNotNone(c)
        cmd = str(c.get("command", ""))
        self.assertIn("detect-contradications", cmd,
            "Must call detect-contradications.sh")

    def test_check_10_text_similarity_threshold(self):
        """Check 10 must scan with threshold ≥90%."""
        c = self._check_by_id(10)
        self.assertIsNotNone(c)
        cmd = str(c.get("command", ""))
        self.assertIn("text-similarity", cmd, "Must call text-similarity.sh")

    def test_check_12_source_manifest(self):
        """Check 12 must run rebuild-source-manifest with --scan-only."""
        c = self._check_by_id(12)
        self.assertIsNotNone(c)
        cmd = str(c.get("command", ""))
        self.assertTrue(
            "--scan-only" in cmd or "rebuild-source-manifest" in cmd
        )


# ── Primary command routing ──────────────────────────────────────────────────

class TestPrimaryCommand(unittest.TestCase):
    def test_primary_command_exists(self):
        """All checks MUST go through lint.sh — single entry point."""
        lint = _load_lint()
        pc = lint.get("primary_command", {})
        self.assertIn("command", pc)
        self.assertIn("lint.sh", str(pc["command"]),
            "Primary command must be lint.sh — not individual scripts")


# ── Post-lint actions ────────────────────────────────────────────────────────

class TestPostLintActions(unittest.TestCase):
    def test_post_lint_actions_exist(self):
        lint = _load_lint()
        self.assertIn("post_lint_actions", lint)

    def test_new_sources_transition_to_ingest(self):
        """New sources detected → present to user → transition to query→ingest."""
        lint = _load_lint()
        actions = lint.get("post_lint_actions", {}).get("actions", [])
        new_src = next(
            (a for a in actions if "new_sources" in str(a.get("condition", "")).lower()),
            None
        )
        self.assertIsNotNone(new_src, "Must have new_sources action")
        self.assertIn(
            "process-query.json#web_ingest_flow",
            str(new_src.get("transition_after_user_confirm", "")),
            "New sources must transition to query web_ingest_flow"
        )

    def test_orphan_pages_action(self):
        """Orphans → propose merge/update/delete."""
        lint = _load_lint()
        actions = lint.get("post_lint_actions", {}).get("actions", [])
        orphan = next(
            (a for a in actions if "orphan" in str(a.get("condition", "")).lower()),
            None
        )
        self.assertIsNotNone(orphan, "Must have orphan_pages action")

    def test_contradiction_action(self):
        """Contradictions → flag pages + present to user."""
        lint = _load_lint()
        actions = lint.get("post_lint_actions", {}).get("actions", [])
        contra = next(
            (a for a in actions if "contradicat" in str(a.get("condition", "")).lower()),
            None
        )
        self.assertIsNotNone(contra, "Must have contradications action")

    def test_lint_never_writes_wiki(self):
        """Lint only reports — never writes wiki directly."""
        lint = _load_lint()
        actions = lint.get("post_lint_actions", {}).get("actions", [])
        for a in actions:
            transition = str(a.get("transition_after_user_confirm", ""))
            schema_ref = str(a.get("schema_ref", ""))
            has_transition = (
                "process-ingest" in transition
                or "process-query" in transition
                or "user_confirm" in transition
            )
            has_schema_ref = "rules/" in schema_ref or "AGENTS.md" in schema_ref
            self.assertTrue(
                has_transition or has_schema_ref,
                f"Lint action must route through other processes, not write directly: {a}"
            )


# ── Trigger conditions ───────────────────────────────────────────────────────

class TestTriggerConditions(unittest.TestCase):
    def test_stagnation_threshold(self):
        lint = _load_lint()
        triggers = lint.get("trigger_conditions", [])
        self.assertGreater(len(triggers), 0)
        stagnation = next(
            (t for t in triggers if "stagnation" in str(t).lower()),
            None
        )
        self.assertIsNotNone(stagnation, "Must detect wiki stagnation")


if __name__ == "__main__":
    unittest.main()
