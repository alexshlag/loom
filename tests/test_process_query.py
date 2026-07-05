"""Tests for process-query.json logic flow."""

import json
import unittest
from pathlib import Path

BASE = Path(__file__).parent.parent
QUERY = BASE / "process-query.json"


def _load_query():
    with open(QUERY) as f:
        return json.load(f)


def _step(steps, step_id):
    for s in steps:
        if str(s.get("step_id")) == str(step_id):
            return s
    raise KeyError(f"Step {step_id} not found in query")


class TestSchema(unittest.TestCase):
    def test_basic_fields(self):
        q = _load_query()
        self.assertEqual(q["module"], "process_query")
        self.assertIn("description", q)

    def test_read_instr(self):
        self.assertIn("agent_read_instructions", _load_query())

    def test_ctx_scope(self):
        self.assertEqual(_load_query().get("context_scope"), "transient")

    def test_err_handling_ref(self):
        eh = _load_query().get("error_handling", {})
        self.assertIn("schema_ref", eh)


class TestGrepContract(unittest.TestCase):
    def test_allowed(self):
        gc = _load_query().get("context", {}).get("grep_contract", {})
        cmds = [p.get("command", "") for p in gc.get("allowed_patterns", [])]
        self.assertTrue(any("-m" in c for c in cmds))

    def test_forbidden(self):
        gc = _load_query().get("context", {}).get("grep_contract", {})
        cmds = [p.get("command", "") for p in gc.get("forbidden_patterns", [])]
        self.assertTrue(any("cat file.md" in c for c in cmds))
        self.assertTrue(any("grep pattern" in c and "-m" not in c for c in cmds))


class TestCompoundLogic(unittest.TestCase):
    def test_criteria_count(self):
        cd = _load_query().get("context", {}).get("compounding_decision_logic", {})
        self.assertEqual(len(cd.get("evaluation_criteria", [])), 3)

    def test_sum_ge2(self):
        cd = _load_query().get("context", {}).get("compounding_decision_logic", {})
        logic = cd.get("decision_logic", [])
        self.assertTrue(any("ge" in str(l).lower() for l in logic))

    def test_sum_eq0(self):
        cd = _load_query().get("context", {}).get("compounding_decision_logic", {})
        logic = cd.get("decision_logic", [])
        self.assertTrue(any("eq" in str(l).lower() and "0" in str(l) for l in logic))


class TestStepFlow(unittest.TestCase):
    def test_s0_25_hot_cache(self):
        s = _step(_load_query()["steps"], "0.25")
        self.assertTrue(s.get("command", "").startswith("./scripts/load-hot-cache.sh"))

    def test_s1_search(self):
        s = _step(_load_query()["steps"], "1")
        chain = s.get("structure", [])
        self.assertGreaterEqual(len(chain), 3)
        self.assertIn("--dynamic", str(chain[0].get("step_1", "")))

    def test_s2_summary_trigger(self):
        s = _step(_load_query()["steps"], "2")
        sp = s.get("summary_page_creation_trigger", {})
        self.assertEqual(sp.get("trigger_condition"), "answer_sources_count >= 3 and all from wiki")

    def test_s2_assess(self):
        s = _step(_load_query()["steps"], "2")
        self.assertIn("assess_compounding_value", s)

    def test_s2_5_backlinks(self):
        s = _step(_load_query()["steps"], "2.5")
        actions = s.get("actions", [])
        self.assertTrue(
            any("backlinks" in str(a).lower() or a.get("action") == "read_backlinks_json" for a in actions)
        )

    def test_s2_5_update_path(self):
        s = _step(_load_query()["steps"], "2.5")
        self.assertTrue(
            any("update" in str(a).lower() and "similar_page" in str(a).lower()
                for a in s.get("actions", []))
        )

    def test_s2_5_guardrails(self):
        s = _step(_load_query()["steps"], "2.5")
        prohibited = s.get("guardrail", {}).get("prohibited", [])
        self.assertTrue(any("direct" in p.lower() for p in prohibited))

    def test_s2_6_compound(self):
        s = _step(_load_query()["steps"], "2.6")
        self.assertIsNotNone(s)

    def test_s2_7_transition(self):
        s = _step(_load_query()["steps"], "2.7")
        self.assertIsNotNone(s)

    def test_s3_guardrails(self):
        s = _step(_load_query()["steps"], "3")
        prohibited = s.get("guardrail", {}).get("prohibited", [])
        self.assertTrue(
            any("create_page directly" in p or "directly" in p for p in prohibited)
        )

    def test_s3_precheck(self):
        s = _step(_load_query()["steps"], "3")
        cmds = [p.get("command", "") for p in s.get("pre_check", [])]
        self.assertTrue(any("validate-path" in str(c) for c in cmds))

    def test_s3_finalize_hot(self):
        s = _step(_load_query()["steps"], "3")
        final = s.get("finalization", [])
        self.assertTrue(
            any("hot" in str(a.get("action_name", "")).lower()
                or "session_context" in str(a.get("rule", "")).lower()
                for a in final)
        )


class TestWebIngest(unittest.TestCase):
    def test_trigger(self):
        w = _load_query().get("web_ingest_flow", {})
        self.assertIn("trigger", w)
        self.assertTrue(
            "user confirm" in str(w["trigger"]).lower()
            or "confirm_save" in str(w["trigger"]).lower()
        )

    def test_req_steps(self):
        w = _load_query().get("web_ingest_flow", {})
        step_ids = [s.get("step_id") for s in w.get("required_steps", [])]
        self.assertIn("step_4_corrected_copy", step_ids)
        self.assertIn("step_6_discussion", step_ids)

    def test_guardrails(self):
        w = _load_query().get("web_ingest_flow", {})
        prohibited = w.get("guardrails", {}).get("prohibited", [])
        self.assertTrue(
            any("direct_edit" in g or "skip_step_4" in g for g in prohibited)
        )


if __name__ == "__main__":
    unittest.main()
