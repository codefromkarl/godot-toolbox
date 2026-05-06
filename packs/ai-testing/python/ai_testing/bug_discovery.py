"""Bug discovery through anomaly detection in episode traces.

Analyzes episode telemetry to identify potential bugs: unexpected
state transitions, stuck conditions, reward anomalies, and
unexplored action sequences.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, List, Sequence


@dataclass
class BugCandidate:
    """A potential bug discovered during episode analysis."""

    severity: str  # "high" | "medium" | "low"
    category: str  # e.g. "stuck_state", "reward_anomaly", "unexplored_action"
    description: str
    episode_id: str
    step: int
    evidence: Dict[str, Any] = field(default_factory=dict)


class BugDiscovery:
    """Post-hoc bug candidate discovery from episode traces.

    Analyzes episode telemetry records to detect anomalous patterns
    that may indicate bugs in the system under test.

    Parameters
    ----------
    max_steps_without_progress:
        Number of consecutive steps with reward <= 0 before flagging.
    reward_anomaly_threshold:
        Absolute reward deviation from mean to flag as anomaly.
    """

    def __init__(
        self,
        max_steps_without_progress: int = 8,
        reward_anomaly_threshold: float = 10.0,
    ) -> None:
        self.max_steps_without_progress = max_steps_without_progress
        self.reward_anomaly_threshold = reward_anomaly_threshold
        self._candidates: List[BugCandidate] = []

    def analyze_episode(
        self,
        episode_id: str,
        telemetry: Sequence[Dict[str, Any]],
        actions_taken: Sequence[str],
        valid_actions: Sequence[str],
    ) -> List[BugCandidate]:
        """Analyze a single episode's telemetry for bug candidates.

        Parameters
        ----------
        episode_id:
            Identifier for the episode.
        telemetry:
            Per-step telemetry records (each has "step", "action",
            "reward", "done", "info").
        actions_taken:
            Ordered list of actions executed.
        valid_actions:
            The environment's full action space.

        Returns
        -------
        list of BugCandidate
        """
        episode_candidates: List[BugCandidate] = []

        # Detect stuck states
        episode_candidates.extend(
            self._detect_stuck_states(episode_id, telemetry)
        )

        # Detect reward anomalies
        episode_candidates.extend(
            self._detect_reward_anomalies(episode_id, telemetry)
        )

        # Detect unexplored actions
        episode_candidates.extend(
            self._detect_unexplored_actions(
                episode_id, actions_taken, valid_actions
            )
        )

        self._candidates.extend(episode_candidates)
        return episode_candidates

    def _detect_stuck_states(
        self,
        episode_id: str,
        telemetry: Sequence[Dict[str, Any]],
    ) -> List[BugCandidate]:
        """Detect sequences of steps with no positive reward."""
        candidates: List[BugCandidate] = []
        no_progress_count = 0
        for record in telemetry:
            reward = float(record.get("reward", 0.0))
            if reward <= 0.0:
                no_progress_count += 1
            else:
                no_progress_count = 0

            if no_progress_count >= self.max_steps_without_progress:
                candidates.append(
                    BugCandidate(
                        severity="medium",
                        category="stuck_state",
                        description=(
                            f"No positive reward for "
                            f"{no_progress_count} consecutive steps"
                        ),
                        episode_id=episode_id,
                        step=int(record.get("step", 0)),
                        evidence={"no_progress_count": no_progress_count},
                    )
                )
                break  # Report once per episode
        return candidates

    def _detect_reward_anomalies(
        self,
        episode_id: str,
        telemetry: Sequence[Dict[str, Any]],
    ) -> List[BugCandidate]:
        """Detect extreme reward values that may indicate bugs."""
        candidates: List[BugCandidate] = []
        if not telemetry:
            return candidates
        rewards = [float(r.get("reward", 0.0)) for r in telemetry]
        mean_reward = sum(rewards) / len(rewards)
        for record in telemetry:
            reward = float(record.get("reward", 0.0))
            if abs(reward - mean_reward) > self.reward_anomaly_threshold:
                candidates.append(
                    BugCandidate(
                        severity="high",
                        category="reward_anomaly",
                        description=(
                            f"Reward {reward:.2f} deviates significantly "
                            f"from mean {mean_reward:.2f}"
                        ),
                        episode_id=episode_id,
                        step=int(record.get("step", 0)),
                        evidence={
                            "reward": reward,
                            "mean_reward": mean_reward,
                        },
                    )
                )
        return candidates

    def _detect_unexplored_actions(
        self,
        episode_id: str,
        actions_taken: Sequence[str],
        valid_actions: Sequence[str],
    ) -> List[BugCandidate]:
        """Flag actions that were never executed."""
        candidates: List[BugCandidate] = []
        taken = set(actions_taken)
        unexplored = set(valid_actions) - taken
        if unexplored:
            candidates.append(
                BugCandidate(
                    severity="low",
                    category="unexplored_action",
                    description=(
                        f"Actions never executed: {sorted(unexplored)}"
                    ),
                    episode_id=episode_id,
                    step=0,
                    evidence={"unexplored": sorted(unexplored)},
                )
            )
        return candidates

    @property
    def candidates(self) -> List[BugCandidate]:
        """All bug candidates discovered so far."""
        return list(self._candidates)

    def summary(self) -> Dict[str, Any]:
        """Return a summary of discovered bug candidates."""
        by_severity: Dict[str, int] = {}
        by_category: Dict[str, int] = {}
        for c in self._candidates:
            by_severity[c.severity] = by_severity.get(c.severity, 0) + 1
            by_category[c.category] = by_category.get(c.category, 0) + 1
        return {
            "total_candidates": len(self._candidates),
            "by_severity": by_severity,
            "by_category": by_category,
        }


__all__ = ["BugCandidate", "BugDiscovery"]
