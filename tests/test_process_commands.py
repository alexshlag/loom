"""
Tests for command and file existence referenced in process files.
Validates that scripts, paths, and templates mentioned in steps actually exist.
"""

import json
from pathlib import Path
import re
import unittest


BASE = Path(__file__).parent.parent
INGEST_PATH = BASE / "process-ingest.json"
QUERY_PATH = BASE / "process-query.json"
LINT_PATH = BASE / "process-lint.json"
SCRIPTS_DIR = BASE / "scripts"


def _load(path):
    with open(path) as f:
        return json.load(f)


class TestScriptsExist(unittest.TestCase):
    """Test that scripts referenced in process files actually exist."""

    def collect_script_refs(self, obj):
        refs = []
        if isinstance(obj, dict):
            for k, v in obj.items():
                if "command" in str(k).lower() and isinstance(v, str) and "./scripts/" in v:
                    match = re.search(r'./scripts/[\w/.-]+(?:\.sh)?', v)
                    if match:
                        refs.append(match.group(0))
                else:
                    refs.extend(self.collect_script_refs(v))
        elif isinstance(obj, list):
            for item in obj:
                refs.extend(self.collect_script_refs(item))
        return refs

    def test_ingest_scripts_exist(self):
        data = _load(INGEST_PATH)
        script_refs = self.collect_script_refs(data)
        for ref in script_refs:
            # ref is like "./scripts/validate-path.sh" - already includes ./scripts/
            full_path = Path(ref.replace("./", ""))
            found = (SCRIPTS_DIR / str(full_path).replace("scripts/", "")).exists()
            self.assertTrue(found, f"Script {ref} referenced in ingest must exist")

    def test_query_scripts_exist(self):
        data = _load(QUERY_PATH)
        script_refs = self.collect_script_refs(data)
        for ref in script_refs:
            full_path = Path(ref.replace("./", ""))
            found = (SCRIPTS_DIR / str(full_path).replace("scripts/", "")).exists()
            self.assertTrue(found, f"Script {ref} referenced in query must exist")


class TestProcessFileStructure(unittest.TestCase):
    """Test that process files have correct structure."""

    def test_ingest_has_steps_list(self):
        data = _load(INGEST_PATH)
        steps = data.get("steps", [])
        self.assertIsInstance(steps, list, "Ingest steps must be a list")
        self.assertTrue(len(steps) > 5, "Must have many steps")

    def test_query_has_steps_list(self):
        data = _load(QUERY_PATH)
        steps = data.get("steps", {})
        if isinstance(steps, dict):
            self.assertTrue(len(steps) > 0, "Query steps must not be empty")


if __name__ == "__main__":
    unittest.main()
