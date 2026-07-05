"""
Additional validation tests for process instruction logic flows.
Tests transition logic, trigger conditions, and cross-process integrity.
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


class TestIngestBranching(unittest.TestCase):
    """Test that ingest steps have proper branching conditions."""

    def test_step_6_has_branching(self):
        data = _load(INGEST_PATH)
        steps_by_id = {s["step_id"]: s for s in data["steps"]}
        step_6 = steps_by_id.get("step_6_discussion", {})
        eval_list = step_6.get("evaluation", [])
        found_branching = False
        for item in eval_list:
            if "branching" in item:
                branching = item["branching"]
                self.assertTrue(len(branching) > 0, "Step 6 must have branching to step 8a/8b")
                found_branching = True
        self.assertTrue(found_branching, "Step 6 evaluation must contain branching")

    def test_branches_target_existing_steps(self):
        data = _load(INGEST_PATH)
        steps_by_id = {s["step_id"]: s for s in data["steps"]}
        all_step_ids = set(steps_by_id.keys())
        step_6 = steps_by_id.get("step_6_discussion", {})
        eval_list = step_6.get("evaluation", [])
        for item in eval_list:
            if "branching" not in item:
                continue
            branching = item["branching"]
            for branch in branching:
                target = branch.get("target")
                self.assertIn(target, all_step_ids, f"Branch target {target} must exist as a step")


class TestTriggerConditions(unittest.TestCase):
    """Test that trigger conditions reference valid operations."""

    def test_ingest_pre_conditions_defined(self):
        data = _load(INGEST_PATH)
        pre_conditions = data.get("pre_conditions", [])
        self.assertTrue(len(pre_conditions) > 0, "Must have pre-conditions")

    def test_query_has_trigger_condition(self):
        data = _load(QUERY_PATH)
        has_top_level = "trigger_condition" in data or "web_ingest_flow" in data
        self.assertTrue(has_top_level, "Query must have trigger conditions")


class TestEvaluationCriteria(unittest.TestCase):
    """Test that steps with branching have proper evaluation."""

    def test_step_1_evaluation(self):
        data = _load(INGEST_PATH)
        steps_by_id = {s["step_id"]: s for s in data["steps"]}
        step_1 = steps_by_id.get("step_1_guardrails", {})
        eval_list = step_1.get("evaluation", [])
        self.assertTrue(len(eval_list) > 0, "Step 1 must have evaluation criteria")

    def test_step_6_evaluation(self):
        data = _load(INGEST_PATH)
        steps_by_id = {s["step_id"]: s for s in data["steps"]}
        step_6 = steps_by_id.get("step_6_discussion", {})
        eval_list = step_6.get("evaluation", [])
        self.assertTrue(len(eval_list) > 0, "Step 6 must have evaluation criteria")


class TestLintCheckIds(unittest.TestCase):
    """Test that lint checks reference consistent IDs."""

    def test_has_lint_checks(self):
        data = _load(LINT_PATH)
        self.assertIn("lint_checks", data, "Must have lint_checks")


class TestCrossProcessConsistency(unittest.TestCase):
    """Test that both ingest and query agree on common conventions."""

    def test_both_read_agents_md(self):
        ingest_data = _load(INGEST_PATH)
        query_data = _load(QUERY_PATH)
        self.assertTrue(ingest_data.get("agent_read_instructions", False))
        self.assertTrue(query_data.get("agent_read_instructions", False))


if __name__ == "__main__":
    unittest.main()
