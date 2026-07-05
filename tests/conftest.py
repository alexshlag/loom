"""
pytest configuration for process instruction tests.
"""
import pytest


def pytest_configure(config):
    """Register custom markers."""
    config.addoption(
        "--process",
        help="Run tests for a specific process: ingest, query, lint",
    )
