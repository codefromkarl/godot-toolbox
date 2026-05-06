"""Coverage tracking for AI testing exploration.

Tracks which observation dimensions and event types have been seen
across episodes, providing a coverage score to guide exploration.
"""

from __future__ import annotations

from typing import Any, Dict, FrozenSet, Optional, Set


class CoverageTracker:
    """Tracks exploration coverage across episodes.

    Coverage is measured along two axes:

    1. **Observation dimensions** -- which keys appear in observations.
    2. **Event types** -- domain-specific event labels reported by the
       environment via ``info["events"]``.

    Parameters
    ----------
    target_events:
        Set of event names to track.  If ``None``, no events are
        tracked until explicitly set via :meth:`set_target_events`.
    target_obs_keys:
        Set of observation keys to track.  If ``None``, all keys
        observed in the first observation will be considered target
        keys.
    """

    def __init__(
        self,
        target_events: Optional[Set[str]] = None,
        target_obs_keys: Optional[Set[str]] = None,
    ) -> None:
        self._target_events: Set[str] = target_events or set()
        self._target_obs_keys: Set[str] = target_obs_keys or set()
        self._seen_events: Set[str] = set()
        self._seen_obs_keys: Set[str] = set()
        self._total_observations: int = 0
        self._unique_action_set: Set[str] = set()

    # -- Configuration --

    def set_target_events(self, events: Set[str]) -> None:
        """Set the target event set (replaces any previous target)."""
        self._target_events = set(events)

    def set_target_obs_keys(self, keys: Set[str]) -> None:
        """Set the target observation keys (replaces any previous target)."""
        self._target_obs_keys = set(keys)

    # -- Recording --

    def record_observation(self, observation: Dict[str, Any]) -> None:
        """Record a single observation for coverage tracking."""
        self._total_observations += 1
        self._seen_obs_keys.update(observation.keys())
        if not self._target_obs_keys:
            self._target_obs_keys = set(observation.keys())

    def record_step(self, action: str, info: Dict[str, Any]) -> None:
        """Record a step's action and info for coverage tracking."""
        self._unique_action_set.add(action)
        events = info.get("events", [])
        if isinstance(events, (list, tuple, set)):
            self._seen_events.update(str(e) for e in events)

    def merge(self, other: CoverageTracker) -> None:
        """Merge coverage data from another tracker into this one."""
        self._seen_events.update(other._seen_events)
        self._seen_obs_keys.update(other._seen_obs_keys)
        self._total_observations += other._total_observations
        self._unique_action_set.update(other._unique_action_set)

    # -- Queries --

    @property
    def event_coverage(self) -> float:
        """Fraction of target events that have been seen (0.0-1.0)."""
        if not self._target_events:
            return 0.0
        return len(self._seen_events & self._target_events) / len(self._target_events)

    @property
    def obs_key_coverage(self) -> float:
        """Fraction of target observation keys that have been seen (0.0-1.0)."""
        if not self._target_obs_keys:
            return 0.0
        return len(self._seen_obs_keys & self._target_obs_keys) / len(
            self._target_obs_keys
        )

    @property
    def total_observations(self) -> int:
        return self._total_observations

    @property
    def unique_actions(self) -> FrozenSet[str]:
        return frozenset(self._unique_action_set)

    @property
    def seen_events(self) -> FrozenSet[str]:
        return frozenset(self._seen_events)

    def summary(self) -> Dict[str, Any]:
        """Return a coverage summary dict."""
        return {
            "event_coverage": round(self.event_coverage, 4),
            "obs_key_coverage": round(self.obs_key_coverage, 4),
            "total_observations": self._total_observations,
            "unique_actions": sorted(self._unique_action_set),
            "seen_events": sorted(self._seen_events),
            "target_events": sorted(self._target_events),
            "target_obs_keys": sorted(self._target_obs_keys),
        }


__all__ = ["CoverageTracker"]
