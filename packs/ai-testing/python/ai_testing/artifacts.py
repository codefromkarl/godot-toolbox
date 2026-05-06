"""Episode artifact management for AI testing.

Handles creation and validation of the episode artifact directory
structure and file naming conventions.
"""

from __future__ import annotations

from pathlib import Path
from typing import Any, Dict, List


class ArtifactManager:
    """Manages episode artifact directory structure and naming.

    Creates a standardized directory layout for each episode:

    ::

        output_dir/
          manifest.json
          summary.json
          report.md
          failures.jsonl
          episodes/
            <episode_id>/
              config.json
              result.json
              input_log.jsonl
              telemetry.jsonl
              state_samples.jsonl
              logs/
              screenshots/
    """

    def __init__(self, output_dir: Path | str) -> None:
        self.output_dir = Path(output_dir)
        self.episodes_dir = self.output_dir / "episodes"
        self.failures_path = self.output_dir / "failures.jsonl"

    def ensure_structure(self) -> None:
        """Create the root artifact directories."""
        self.episodes_dir.mkdir(parents=True, exist_ok=True)
        self.failures_path.touch(exist_ok=True)

    def episode_dir(self, episode_id: str) -> Path:
        """Return the artifact directory for *episode_id*."""
        return self.episodes_dir / episode_id

    def create_episode_dirs(self, episode_id: str) -> Path:
        """Create and return the episode artifact directory."""
        d = self.episode_dir(episode_id)
        (d / "logs").mkdir(parents=True, exist_ok=True)
        (d / "screenshots").mkdir(parents=True, exist_ok=True)
        return d

    def append_failure(self, payload: Dict[str, Any]) -> None:
        """Append a failure record to the global failures log."""
        import json

        with self.failures_path.open("a", encoding="utf-8") as fh:
            fh.write(json.dumps(payload, sort_keys=True) + "\n")

    def validate_structure(self) -> List[str]:
        """Validate that the artifact directory has expected structure.

        Returns a list of validation errors (empty if valid).
        """
        errors: List[str] = []
        if not self.output_dir.is_dir():
            errors.append(f"output_dir does not exist: {self.output_dir}")
            return errors
        if not self.episodes_dir.is_dir():
            errors.append(f"episodes/ dir missing: {self.episodes_dir}")
        if not self.failures_path.exists():
            errors.append(f"failures.jsonl missing: {self.failures_path}")
        return errors


__all__ = ["ArtifactManager"]
