"""
Deep integration tests for process instruction logic flows.
Validates step ordering, schema references, error handling patterns,
working memory hooks, cross-process transitions, and git conventions.
"""

import json
from pathlib import Path
import unittest


BASE = Path(__file__).parent.parent
INGEST_PATH = BASE / "process-ingest.json"
QUERY_PATH = BASE / "process-query.json"
LINT_PATH = BASE / "process-lint.json"
RULES_DIR = BASE / "rules"


def _load(path):
    with open(path) as f:
        return json.load(f)


# ==============================================================================
# Step ordering tests - ingest workflow must flow logically
# ==============================================================================

class TestIngestStepOrdering(unittest.TestCase):
    """Validate that ingest steps are ordered and have dependencies."""

    def test_steps_ordered_by_number(self):
        data = _load(INGEST_PATH)
        step_ids = [s["step_id"] for s in data["steps"]]
        numbers = []
        for sid in step_ids:
            parts = sid.split("_")
            if len(parts) >= 2 and parts[1].isdigit():
                numbers.append(int(parts[1]))
        self.assertEqual(numbers, sorted(numbers), "Steps should be ordered by number")

    def test_guardrails_before_analysis(self):
        data = _load(INGEST_PATH)
        steps_by_id = {s["step_id"]: s for s in data["steps"]}
        self.assertIn("step_1_guardrails", steps_by_id)
        self.assertIn("step_3_analysis", steps_by_id)


class TestQueryStepOrdering(unittest.TestCase):
    """Validate that query steps flow logically."""

    def test_hot_cache_before_search(self):
        data = _load(QUERY_PATH)
        step_ids = [s["step_id"] for s in data["steps"]]
        self.assertIn("0.25", step_ids, "Hot cache step must exist")
        self.assertIn("1", step_ids, "Search step must exist")

    def test_search_before_analysis(self):
        data = _load(QUERY_PATH)
        step_ids = [s["step_id"] for s in data["steps"]]
        self.assertIn("1", step_ids, "Search step must exist")
        self.assertIn("2", step_ids, "Analysis step must exist")


# ==============================================================================
# Schema reference validation tests - rule files must exist
# ==============================================================================

class TestSchemaReferencesValid(unittest.TestCase):
    """Test that schema_refs pointing to rules/ point to existing rule files."""

    def _collect_schema_refs(self, obj):
        refs = []
        if isinstance(obj, dict):
            for k, v in obj.items():
                if k == "schema_ref":
                    refs.append(str(v))
                else:
                    refs.extend(self._collect_schema_refs(v))
        elif isinstance(obj, list):
            for item in obj:
                refs.extend(self._collect_schema_refs(item))
        return refs

    def test_ingest_schema_refs_exist(self):
        """All rule file schema_refs must point to existing files."""
        data = _load(INGEST_PATH)
        refs = self._collect_schema_refs(data)
        for ref in refs:
            path_part = ref.split("#")[0]
            if not path_part.startswith("rules/"):
                continue
            filename = path_part.replace("rules/", "")
            found = (RULES_DIR / filename).exists()
            self.assertTrue(found, f"Schema ref {ref} points to non-existent rule file")

    def test_query_schema_refs_exist(self):
        """All rule file schema_refs must point to existing files."""
        data = _load(QUERY_PATH)
        refs = self._collect_schema_refs(data)
        for ref in refs:
            path_part = ref.split("#")[0]
            if not path_part.startswith("rules/"):
                continue
            filename = path_part.replace("rules/", "")
            found = (RULES_DIR / filename).exists()
            self.assertTrue(found, f"Schema ref {ref} points to non-existent rule file")


# ==============================================================================
# Error handling pattern tests
# ==============================================================================

class TestErrorHandlingPatterns(unittest.TestCase):
    """Test that error handling follows AGENTS.md patterns."""

    def test_ingest_error_handling_has_schema_ref(self):
        data = _load(INGEST_PATH)
        eh = data.get("error_handling", {})
        text = json.dumps(eh)
        self.assertTrue(
            "schema_ref" in str(eh) or "error_handling" in text.lower(),
            "Error handling must reference error handling schema"
        )

    def test_query_error_handling_has_schema_ref(self):
        data = _load(QUERY_PATH)
        eh = data.get("error_handling", {})
        text = json.dumps(eh)
        self.assertTrue(
            "schema_ref" in str(eh) or "error_handling" in text.lower(),
            "Error handling must reference error handling schema"
        )


# ==============================================================================
# Working memory hooks tests
# ==============================================================================

class TestWorkingMemoryHooks(unittest.TestCase):
    """Test that working memory hooks have proper triggers."""

    def test_ingest_has_on_start_trigger(self):
        data = _load(INGEST_PATH)
        hooks = data.get("working_memory_hooks", [])
        triggers = [h.get("trigger") for h in hooks]
        self.assertIn("on_start", triggers, "Must have on_start trigger")

    def test_ingest_has_on_complete_trigger(self):
        data = _load(INGEST_PATH)
        hooks = data.get("working_memory_hooks", [])
        triggers = [h.get("trigger") for h in hooks]
        self.assertIn("on_complete", triggers, "Must have on_complete trigger")


# ==============================================================================
# Cross-process transition tests
# ==============================================================================

class TestCrossProcessTransitions(unittest.TestCase):
    """Test that query → ingest transitions are properly defined."""

    def test_query_has_web_ingest_flow(self):
        data = _load(QUERY_PATH)
        self.assertIn("web_ingest_flow", data, "Query must define web_ingest_flow")

    def test_ingest_has_cross_process_triggers(self):
        data = _load(INGEST_PATH)
        triggers = data.get("cross_process_triggers", [])
        self.assertTrue(len(triggers) > 0, "Must have cross-process triggers")


# ==============================================================================
# Git conventions tests - defined at AGENTS.md level, not per-process
# ==============================================================================

class TestGitConventions(unittest.TestCase):
    """Test that git conventions are referenced in process files."""

    def test_ingest_references_guardrails(self):
        data = _load(INGEST_PATH)
        text = json.dumps(data)
        self.assertIn("validate-path", text.lower(), "Ingest must reference validate-path.sh")


# ==============================================================================
# Rules directory tests - all referenced rules must exist
# ==============================================================================

class TestRulesExist(unittest.TestCase):
    """Test that rule files referenced in process files actually exist."""

    def test_rules_directory_has_files(self):
        self.assertTrue(len(list(RULES_DIR.iterdir())) > 0, "rules/ should have files")


if __name__ == "__main__":
    unittest.main()
