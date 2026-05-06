"""No-training exploration policies for AI automated testing.

Provides ``RandomPolicy``, ``ScriptedPolicy``, and an abstract
``HeuristicPolicy`` base for domain-specific rule-based policies.

Adapted from stardrifter's agents.py with combat/overmap logic removed
and observation dimensions parameterized.
"""

from __future__ import annotations

import random
from abc import ABC, abstractmethod
from collections import deque
from typing import Any, Deque, Iterable, Mapping


class RandomPolicy:
    """Seeded random policy that emits actions from the observation's
    ``valid_actions`` list.
    """

    def __init__(self, seed: int = 0) -> None:
        self._rng = random.Random(seed)

    def act(self, observation: Mapping[str, Any]) -> str:
        actions = observation.get("valid_actions", [])
        if not actions:
            return "noop"
        return str(self._rng.choice(list(actions)))


class ScriptedPolicy:
    """Fixed action sequence with deterministic fallback after
    script exhaustion.
    """

    def __init__(
        self,
        actions: Iterable[str],
        fallback: str = "noop",
    ) -> None:
        self._actions: Deque[str] = deque(actions)
        self.fallback = fallback

    def act(self, observation: Mapping[str, Any]) -> str:
        del observation  # Scripted policies ignore observation
        if self._actions:
            return self._actions.popleft()
        return self.fallback


class HeuristicPolicy(ABC):
    """Abstract base for rule-based exploration policies.

    Subclasses implement :meth:`choose_action` to provide domain-specific
    logic.  The base ``act`` method validates that the chosen action is
    in the observation's ``valid_actions`` and falls back to the first
    valid action otherwise.
    """

    @abstractmethod
    def choose_action(self, observation: Mapping[str, Any]) -> str:
        """Select an action based on domain-specific rules."""
        ...

    def act(self, observation: Mapping[str, Any]) -> str:
        chosen = self.choose_action(observation)
        valid = observation.get("valid_actions", [])
        if valid and chosen not in [str(a) for a in valid]:
            return str(list(valid)[0])
        if not valid:
            return "noop"
        return chosen


class EpsilonGreedyPolicy:
    """Wraps another policy with epsilon-greedy exploration.

    With probability *epsilon*, a random action is chosen instead of
    delegating to the wrapped policy.
    """

    def __init__(
        self,
        base_policy: Any,
        epsilon: float = 0.1,
        seed: int = 0,
    ) -> None:
        self._base = base_policy
        self._epsilon = epsilon
        self._rng = random.Random(seed)

    def act(self, observation: Mapping[str, Any]) -> str:
        if self._rng.random() < self._epsilon:
            actions = observation.get("valid_actions", [])
            if actions:
                return str(self._rng.choice(list(actions)))
        return self._base.act(observation)


__all__ = [
    "EpsilonGreedyPolicy",
    "HeuristicPolicy",
    "RandomPolicy",
    "ScriptedPolicy",
]
