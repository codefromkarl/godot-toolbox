"""Episode runner for AI testing framework.

Orchestrates episodes: runs a policy in an environment, collects
telemetry, and delegates artifact writing.

Adapted from stardrifter's runner.py with game-specific environments
removed.  The ``environment`` parameter is now required.
"""

from __future__ import annotations

from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional

from .artifacts import ArtifactManager
from .bug_discovery import BugDiscovery
from .contracts import EpisodeResult, StepResult, TestEnvironment
from .coverage_tracker import CoverageTracker
from .summary_report import write_episode_artifacts, write_suite_artifacts


@dataclass(frozen=True)
class EpisodeConfig:
    """Configuration for a single episode."""

    episode_id: str
    env_name: str
    policy_name: str
    seed: int = 0
    max_steps: int = 32


class EpisodeRunner:
    """Runs a policy in an environment and collects artifacts.

    Parameters
    ----------
    output_dir:
        Root directory for episode artifacts.
    """

    def __init__(self, output_dir: Path | str) -> None:
        self._artifacts = ArtifactManager(output_dir)
        self._artifacts.ensure_structure()
        self._results: List[Dict[str, Any]] = []
        self._coverage = CoverageTracker()
        self._bug_discovery = BugDiscovery()

    @property
    def coverage(self) -> CoverageTracker:
        return self._coverage

    @property
    def bug_discovery(self) -> BugDiscovery:
        return self._bug_discovery

    def run_episode(
        self,
        config: EpisodeConfig,
        environment: TestEnvironment,
        policy: Any,
    ) -> Dict[str, Any]:
        """Run a single episode.

        Parameters
        ----------
        config:
            Episode configuration.
        environment:
            A ``TestEnvironment`` implementation.
        policy:
            An object with an ``act(observation) -> str`` method.

        Returns
        -------
        dict
            The episode result payload.
        """
        episode_dir = self._artifacts.create_episode_dirs(config.episode_id)

        observation = environment.reset(seed=config.seed)
        self._coverage.record_observation(observation)

        result: Optional[EpisodeResult] = None
        total_reward = 0.0
        steps = 0
        input_log: List[Dict[str, Any]] = []
        telemetry: List[Dict[str, Any]] = []
        state_samples: List[Dict[str, Any]] = [{"step": 0, "observation": observation}]
        actions_taken: List[str] = []

        for step_index in range(config.max_steps):
            action = policy.act(observation)
            actions_taken.append(action)
            input_log.append({"step": step_index + 1, "action": action})

            step: StepResult = environment.step(action)
            total_reward += step.reward
            steps = step_index + 1
            observation = step.observation

            self._coverage.record_observation(observation)
            self._coverage.record_step(action, step.info)

            telemetry.append({
                "step": steps,
                "action": action,
                "reward": step.reward,
                "done": step.done,
                "info": step.info,
            })
            state_samples.append({"step": steps, "observation": observation})

            if step.done:
                result = step.info.get("result") or environment.result
                break

        if result is None:
            result = EpisodeResult(
                "failed",
                "runner_step_limit",
                steps,
                metrics={"max_steps": config.max_steps},
            )

        payload = {
            "episode_id": config.episode_id,
            "env_name": config.env_name,
            "policy_name": config.policy_name,
            "seed": config.seed,
            "status": result.status,
            "reason": result.reason,
            "steps": result.steps,
            "total_reward": round(total_reward, 4),
            "metrics": result.metrics,
            "runtime_advisory_only": True,
        }

        write_episode_artifacts(
            episode_dir,
            asdict(config),
            payload,
            input_log,
            telemetry,
            state_samples,
        )

        if result.status != "passed":
            self._artifacts.append_failure(payload)

        self._bug_discovery.analyze_episode(
            config.episode_id,
            telemetry,
            actions_taken,
            list(environment.action_space),
        )

        self._results.append(payload)
        return payload

    def finalize(self) -> Dict[str, Any]:
        """Write suite-level artifacts and return the summary."""
        summary = write_suite_artifacts(
            self._artifacts.output_dir,
            self._results,
        )
        summary["coverage"] = self._coverage.summary()
        summary["bug_candidates"] = self._bug_discovery.summary()
        return summary


def default_output_dir(root: Path | str = "build/ai-testing") -> Path:
    """Create a timestamped output directory."""
    stamp = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    return Path(root) / stamp


__all__ = ["EpisodeConfig", "EpisodeRunner", "default_output_dir"]
