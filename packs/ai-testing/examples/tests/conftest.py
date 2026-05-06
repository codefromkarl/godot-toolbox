"""AI testing pytest fixtures for framework smoke tests."""

from __future__ import annotations

import tempfile
from pathlib import Path

import pytest


@pytest.fixture
def tmp_output_dir():
    """Provide a temporary directory for episode artifacts."""
    with tempfile.TemporaryDirectory(prefix="ai_testing_") as tmpdir:
        yield Path(tmpdir)
