#!/usr/bin/env python3
"""
Test runner for process instruction logic validation.
Runs all process-* test modules and reports results.
"""

import sys
import unittest
from pathlib import Path


def run_all_tests():
    """Run all process instruction tests."""
    loader = unittest.TestLoader()
    suite = unittest.TestSuite()

    # Discover all test modules in tests/ directory
    tests_dir = Path(__file__).parent / "tests"
    for module_path in sorted(tests_dir.glob("test_*.py")):
        if module_path.name == "__init__.py":
            continue
        module_name = f"tests.{module_path.stem}"
        print(f"\n📦 Loading {module_name}...")
        try:
            suite.addTests(loader.loadTestsFromName(module_name))
        except Exception as e:
            print(f"  ⚠️  Failed to load {module_name}: {e}")

    # Run with verbose output
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    
    return result


if __name__ == "__main__":
    result = run_all_tests()
    print(f"\n{'='*60}")
    print(f"📊 Process Instruction Tests Summary")
    print(f"{'='*60}")
    print(f"Tests run: {result.testsRun}")
    print(f"Failures:  {len(result.failures)}")
    print(f"Errors:    {len(result.errors)}")
    if result.wasSuccessful():
        print("✅ All tests passed!")
    else:
        print("❌ Some tests failed!")
        sys.exit(1)
