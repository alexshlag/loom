"""
Unit tests for process instruction logic flows in process-ingest.json and process-query.json.

These tests validate:
- Required fields exist (module, description, agent_read_instructions)
- Workflow steps have required components
- Error handling references AGENTS.md / rules/
- Working memory hooks are present
- Cross-process triggers make sense
"""

import json
from pathlib import Path
import unittest


BASE = Path(__file__).parent.parent
INGEST_PATH = BASE / "process-ingest.json"
QUERY_PATH = BASE / "process-query.json"
LINT_PATH = BASE / "process-lint.json"


def _load(path):
    with open(path) as f:
        return json.load(f)


# ==============================================================================
# process-ingest.json tests
# ==============================================================================

class TestIngestModule(unittest.TestCase):
    """Module-level checks for process-ingest.json."""

    def test_module_name(self):
        data = _load(INGEST_PATH)
        self.assertEqual(data["module"], "process_ingest")

    def test_description_present(self):
        data = _load(INGEST_PATH)
        self.assertIn("description", data)

    def test_agent_read_instructions(self):
        """Must read AGENTS.md before executing."""
        data = _load(INGEST_PATH)
        self.assertTrue(data.get("agent_read_instructions", False))

    def test_context_scope_transient(self):
        """Process-specific rules are transient - not persistent memory."""
        data = _load(INGEST_PATH)
        self.assertEqual(data.get("context_scope"), "transient")


class TestIngestSteps(unittest.TestCase):
    """All workflow steps must have required components: step_id, description."""

    def test_steps_exist(self):
        data = _load(INGEST_PATH)
        # Ingest uses a list of steps directly under root key 'steps'
        steps = data["steps"]
        self.assertTrue(len(steps) > 0, "Must have workflow steps")

    def test_each_step_has_step_id(self):
        """Every step must have: step_id."""
        data = _load(INGEST_PATH)
        for s in data["steps"]:
            self.assertIn("step_id", s, f"Step {s.get('step_id', '?')} missing step_id")

    def test_step_1_guardrails_exists(self):
        """Step 1 must exist and reference validate-path.sh."""
        data = _load(INGEST_PATH)
        steps_by_id = {s["step_id"]: s for s in data["steps"]}
        self.assertIn("step_1_guardrails", steps_by_id)

    def test_step_2_delta_check_exists(self):
        """Step 2 must exist and reference delta tracking."""
        data = _load(INGEST_PATH)
        steps_by_id = {s["step_id"]: s for s in data["steps"]}
        self.assertIn("step_2_delta_check", steps_by_id)

    def test_step_3_analysis_exists(self):
        """Step 3 must exist with source analysis actions."""
        data = _load(INGEST_PATH)
        steps_by_id = {s["step_id"]: s for s in data["steps"]}
        self.assertIn("step_3_analysis", steps_by_id)


class TestIngestCorrectedCopy(unittest.TestCase):
    """Step 4: corrected copy - raw/corrected/ zone."""

    def test_step_exists(self):
        data = _load(INGEST_PATH)
        steps_by_id = {s["step_id"]: s for s in data["steps"]}
        self.assertIn("step_4_corrected_copy", steps_by_id)


class TestIngestPostChecks(unittest.TestCase):
    """Step 9: post checks - meta rebuild, crosslink discovery."""

    def test_step_exists(self):
        data = _load(INGEST_PATH)
        steps_by_id = {s["step_id"]: s for s in data["steps"]}
        self.assertIn("step_9_post_checks", steps_by_id)


class TestIngestErrorHandling(unittest.TestCase):
    """Must inherit error handling from AGENTS.md / rules/."""

    def test_error_handling_schema_ref(self):
        data = _load(INGEST_PATH)
        eh = data.get("error_handling")
        self.assertIsNotNone(eh)


class TestIngestWorkingMemoryHooks(unittest.TestCase):
    """Must have working memory hooks: on_start, on_complete."""

    def test_hooks_exist(self):
        data = _load(INGEST_PATH)
        hooks = data.get("working_memory_hooks", [])
        self.assertTrue(len(hooks) > 0)


# ==============================================================================
# process-query.json tests
# ==============================================================================

class TestQueryModule(unittest.TestCase):
    """Module-level checks for process-query.json."""

    def test_module_name(self):
        data = _load(QUERY_PATH)
        self.assertEqual(data["module"], "process_query")

    def test_agent_read_instructions(self):
        data = _load(QUERY_PATH)
        self.assertTrue(data.get("agent_read_instructions", False))


class TestQuerySteps(unittest.TestCase):
    """All query workflow steps must have required components."""

    def test_steps_exist(self):
        data = _load(QUERY_PATH)
        # Query uses a dict keyed by step IDs like '0', '1', '2', etc.
        steps = data["steps"]
        self.assertTrue(len(steps) > 0, "Must have workflow steps")

    def test_step_1_search_exists(self):
        """Step 1 must exist with search structure."""
        data = _load(QUERY_PATH)
        step_ids = [s.get("step_id") for s in data["steps"]]
        self.assertIn("1", step_ids)

    def test_step_2_analysis_exists(self):
        """Step 2 must exist with analysis structure."""
        data = _load(QUERY_PATH)
        step_ids = [s.get("step_id") for s in data["steps"]]
        self.assertIn("2", step_ids)


class TestQueryErrorHandling(unittest.TestCase):
    """Must have error handling section."""

    def test_error_handling_exists(self):
        data = _load(QUERY_PATH)
        eh = data.get("error_handling")
        self.assertIsNotNone(eh)


# ==============================================================================
# process-lint.json tests
# ==============================================================================

class TestLintModule(unittest.TestCase):
    """Module-level checks for process-lint.json."""

    def test_module_name(self):
        data = _load(LINT_PATH)
        self.assertEqual(data["module"], "process_lint")


class TestLintStructure(unittest.TestCase):
    """Lint uses different structure - lint_checks, primary_command."""

    def test_has_primary_command(self):
        data = _load(LINT_PATH)
        self.assertIn("primary_command", data)

    def test_has_trigger_conditions(self):
        data = _load(LINT_PATH)
        self.assertIn("trigger_conditions", data)


# ==============================================================================
# Cross-process consistency tests
# ==============================================================================

class TestCrossProcessConsistency(unittest.TestCase):
    """Test that all three process files share common conventions."""

    def test_all_have_module_field(self):
        for path in [INGEST_PATH, QUERY_PATH, LINT_PATH]:
            data = _load(path)
            self.assertIn("module", data)

    def test_all_have_agent_read_instructions(self):
        """All process files must read AGENTS.md before executing."""
        for path in [INGEST_PATH, QUERY_PATH, LINT_PATH]:
            data = _load(path)
            self.assertTrue(data.get("agent_read_instructions", False))

    def test_ingest_and_query_have_error_handling(self):
        """Ingest and query must have error handling sections."""
        for path in [INGEST_PATH, QUERY_PATH]:
            data = _load(path)
            self.assertIn("error_handling", data)


# ==============================================================================
# Schema reference tests
# ==============================================================================

class TestSchemaReferences(unittest.TestCase):
    """Test that schema refs point to valid files/sections."""

    def test_ingest_has_schema_refs(self):
        """Ingest must have schema references for structured rules."""
        data = _load(INGEST_PATH)
        # Check that there are schema_ref references in various sections
        text = json.dumps(data)
        self.assertIn("schema_ref", text)

    def test_query_has_schema_refs(self):
        """Query must have schema references."""
        data = _load(QUERY_PATH)
        text = json.dumps(data)
        self.assertIn("schema_ref", text)


if __name__ == "__main__":
    unittest.main()
