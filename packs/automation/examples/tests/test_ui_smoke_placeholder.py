"""Candidate PoC placeholder for future GodotE2E smoke coverage."""

from __future__ import annotations

import os
from pathlib import Path
import unittest


class AutomationPackPlaceholderTest(unittest.TestCase):
    def test_candidate_pack_not_yet_wired(self) -> None:
        project_root = os.environ.get("GODOT_PROJECT_ROOT")
        if not project_root:
            self.skipTest(
                "Candidate PoC only: set GODOT_PROJECT_ROOT after locking the real "
                "GodotE2E package name and runtime contract."
            )

        self.assertTrue(Path(project_root).exists())
        self.skipTest(
            "Candidate PoC only: replace this placeholder once the real GodotE2E "
            "integration path is validated."
        )
