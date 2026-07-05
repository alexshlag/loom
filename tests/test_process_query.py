"""
Tests for process-query.json logic flow.
Validates search chain, compounding decision logic, web→ingest transitions,
result fixation guards, and working memory contracts.
"""

import json
import unittest
from pathlib import Path


BASE = Path(__file__).parent.parent
QUERY = BASE / "process-query.json"


def _load_query():
    with open(QUERY) as f:
        return json.load(f)


def _step(steps, step_id):
    """Get a step dict from steps array by step_id."""
    for s in steps:
        if str(s.get("step_id")) == str(step_id):
            return s
    raise KeyError(f"Step {step_id} not found in query")


# ── Schema-level checks ─────────────────────────────────────────────────────

class TestQuerySchema(unittest.TestCase):
    def test_module_and_description(self):
        query = _load_query()
        self.assertIn("module", query)
        self.assertEqual(query["module"], "process_query")
        self.assertIn("description", query)

    def test_agent_read_instructions_present(self):
        query = _load_query()
        self.assertIn("agent_read_instructions", query)

    def test_context_scope_transient(self):
        query = _load_query()
        self.assertEqual(query.get("context_scope"), "transient")

    def test_error_handling_schema_ref(self):
        query = _load_query()
        self.assertIn("error_handling", query)
        self.assertIn("schema_ref", query["error_handling"])


# ── Context contract checks ─────────────────────────────────────────────────

class TestQueryContext(unittest.TestCase):
    def test_grep_contract_allowed_patterns(self):
        query = _load_query()
        gc = query.get("context", {}).get("grep_contract", {})
        allowed = [p.get("command") for p in gc.get("allowed_patterns", [])]
        self.assertTrue(any("-m" in a for a in allowed), "Must require -m flag with grep")

    def test_grep_contract_forbidden(self):
        query = _load_query()
        gc = query.get("context", {}).get("grep_contract", {})
        forbidden = [p.get("command") for p in gc.get("forbidden_patterns", [])]
        self.assertTrue(
            any("cat file.md" in f or "grep pattern wiki/" == f.replace("-m", "").strip() for f in forbidden),
            "Must forbid cat >50 lines and grep without -m"
        )


# ── Step flow validation ─────────────────────────────────────────────────────

class TestQuerySteps(unittest.TestCase):
    def test_step_0_hot_cache(self):
        query = _load_query()
        steps = query["steps"]
        s = _step(steps, "0.25")
        self.assertIsNotNone(s)
        self.assertTrue(
            s.get("command", "").startswith("./scripts/load-hot-cache.sh"),
            "Must call load-hot-cache.sh"
        )

    def test_step_1_search_chain(self):
        """Search must start with wiki-search.sh --dynamic, then grep fallbacks."""
        query = _load_query()
        steps = query["steps"]
        s = _step(steps, "1")
        structure = s.get("structure", [])
        self.assertGreaterEqual(len(structure), 3, "Must have 3-step search chain")
        step1_cmd = structure[0].get("step_1", "")
        self.assertIn("--dynamic", str(step1_cmd), "First must be wiki-search.sh --dynamic")

    def test_step_2_compounding_logic(self):
        """Compounding: ≥3 wiki pages → propose save; web sources → require approval."""
        query = _load_query()
        steps = query["steps"]
        s = _step(steps, "2")
        sp = s.get("summary_page_creation_trigger", {})
        self.assertEqual(sp.get("trigger_condition"), "answer_sources_count >= 3 and all from wiki")

    def test_step_2_compounding_decision(self):
        """Must reference compounding_decision_logic."""
        query = _load_query()
        steps = query["steps"]
        s = _step(steps, "2")
        self.assertIn("assess_compounding_value", s)

    def test_step_2_duplicate_check(self):
        """Before fixation: check backlinks.json for similar pages."""
        query = _load_query()
        steps = query["steps"]
        s = _step(steps, "2.5")
        actions = s.get("actions", [])
        self.assertTrue(
            any("backlinks" in str(a).lower() or a.get("action") == "read_backlinks_json" for a in actions),
            "Must read backlinks.json"
        )

    def test_step_2_duplicate_update_vs_create(self):
        """If similar page → UPDATE_EXISTING; if not similar → CREATE_NEW."""
        query = _load_query()
        steps = query["steps"]
        s = _step(steps, "2.5")
        update_found = any(
            "update" in str(a).lower() and "similar_page" in str(a).lower()
            for a in s.get("actions", [])
        )
        self.assertTrue(update_found, "Must handle similar page → UPDATE path")

    def test_step_25_guardrails_prohibited(self):
        """Direct edit is prohibited — must go through process-ingest."""
        query = _load_query()
        steps = query["steps"]
        s = _step(steps, "2.5")
        guard = s.get("guardrail", {})
        prohibited = guard.get("prohibited", [])
        self.assertTrue(any("direct" in p.lower() for p in prohibited), "Must prohibit direct edits")

    def test_step_27_web_ingest_transition(self):
        """Web search + user confirm → TRANSITION to process-ingest."""
        query = _load_query()
        steps = query["steps"]
        s = _step(steps, "2.6")  # step_id is 2.6 but name references transition
        self.assertIsNotNone(s)

    def test_step_3_result_fixation_guardrails(self):
        """Result fixation must PROPOSE_SAVE to user — never auto-create."""
        query = _load_query()
        steps = query["steps"]
        s = _step(steps, "3")
        guard = s.get("guardrail", {})
        prohibited = guard.get("prohibited", [])
        self.assertTrue(
            any("create_page directly" in p or "directly" in p for p in prohibited),
            "Must prohibit direct create_page from query step"
        )

    def test_step_3_validate_path_precheck(self):
        query = _load_query()
        s = _step(query["steps"], "3")
        pre_check = [p.get("command", "") for p in s.get("pre_check", [])]
        self.assertTrue(
            any("validate-path" in str(p) for p in pre_check),
            "Must validate path before fixation"
        )


# ── Compounding decision logic ───────────────────────────────────────────────

class TestCompoundingLogic(unittest.TestCase):
    def test_score_criteria(self):
        """3 criteria: synthesis from 2+ pages (+1), compounding_flagged (+1), contradiction found (+1)."""
        query = _load_query()
        cd = query.get("context", {}).get("compounding_decision_logic", {})
        criteria = cd.get("evaluation_criteria", [])
        self.assertEqual(len(criteria), 3, "Must have exactly 3 evaluation criteria")

    def test_decision_sum_ge_2(self):
        """If sum_score ≥ 2 → PROPOSE_SAVE."""
        query = _load_query()
        cd = query.get("context", {}).get("compounding_decision_logic", {})
        logic = cd.get("decision_logic", [])
        ge = [l for l in logic if "ge" in str(l).lower()]
        self.assertGreater(len(ge), 0, "Must have sum_score ≥ 2 rule")

    def test_decision_sum_eq_0(self):
        """If sum_score == 0 → SKIP_SAVE."""
        query = _load_query()
        cd = query.get("context", {}).get("compounding_decision_logic", {})
        logic = cd.get("decision_logic", [])
        eq0 = [l for l in logic if "eq" in str(l).lower() and "0" in str(l)]
        self.assertGreater(len(eq0), 0, "Must have sum_score == 0 rule")


# ── Web ingest flow ──────────────────────────────────────────────────────────

class TestWebIngestFlow(unittest.TestCase):
    def test_trigger_condition(self):
        query = _load_query()
        w = query.get("web_ingest_flow", {})
        self.assertIn("trigger", w)
        self.assertTrue(
            "user confirm" in str(w["trigger"]).lower() or "confirm_save" in str(w["trigger"]).lower()
        )

    def test_mandatory_steps(self):
        """Web ingest MUST include: corrected_copy, discussion, update_page."""
        query = _load_query()
        w = query.get("web_ingest_flow", {})
        req = w.get("required_steps", [])
        step_names = [s.get("step_id") for s in req]
        self.assertIn("step_4_corrected_copy", step_names, "corrected_copy is mandatory")
        self.assertIn("step_6_discussion", step_names, "discussion is mandatory")

    def test_guardrails_prohibited(self):
        query = _load_query()
        w = query.get("web_ingest_flow", {})
        guard = w.get("guardrails", {}).get("prohibited", [])
        self.assertTrue(
            any("direct_edit" in g or "skip_step_4" in g for g in guard),
            "Must prohibit direct_edit() and skip corrected_copy"
        )


# ── Working memory hooks for query ───────────────────────────────────────────

class TestQueryWM(unittest.TestCase):
    def test_finalization_writes_hot(self):
        query = _load_query()
        steps = query["steps"]
        s = _step(steps, "3")
        final = s.get("finalization", [])
        hot_found = any(
            ("hot" in str(a.get("action_name", "")).lower() or "session_context" in str(a.get("rule", "")).lower())
            for a in final
        )
        self.assertTrue(hot_found, "Finalization must write to hot.md")


if __name__ == "__main__":
    unittest.main()
