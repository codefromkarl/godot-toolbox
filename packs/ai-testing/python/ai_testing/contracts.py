"""Core data contracts for the AI testing framework.

These protocols and data classes define the stable interface between
environments, policies, and the episode runner.  They carry zero
domain-specific coupling and can be directly consumed by any test
environment implementation.

Adapted from stardrifter's envs.py base types.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Dict, Optional, Protocol, Sequence, runtime_checkable


@dataclass(frozen=True)
class StepResult:
    """Result of a single environment step."""

    observation: Dict[str, Any]
    reward: float
    done: bool
    info: Dict[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class EpisodeResult:
    """Final outcome of an episode."""

    status: str  # "passed" | "failed"
    reason: str  # Human-readable failure taxonomy
    steps: int
    metrics: Dict[str, Any] = field(default_factory=dict)


@runtime_checkable
class TestEnvironment(Protocol):
    """Protocol that all test environments must implement.

    This replaces any game-specific environment base class.  Consumers
    implement this protocol to provide observation/action interaction
    with the system under test.
    """

    @property
    def action_space(self) -> Sequence[str]:
        """Available action labels for this environment."""
        ...

    def reset(self, seed: Optional[int] = None) -> Dict[str, Any]:
        """Reset the environment and return the initial observation."""
        ...

    def step(self, action: str) -> StepResult:
        """Execute *action* and return the step result."""
        ...

    @property
    def result(self) -> Optional[EpisodeResult]:
        """Episode result, or ``None`` if the episode has not ended."""
        ...


@runtime_checkable
class Policy(Protocol):
    """Protocol for no-training exploration policies."""

    def act(self, observation: Dict[str, object]) -> str:
        """Choose an action given the current observation."""
        ...


__all__ = [
    "EpisodeResult",
    "Policy",
    "StepResult",
    "TestEnvironment",
]
