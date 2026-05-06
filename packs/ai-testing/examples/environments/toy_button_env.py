"""Minimal example TestEnvironment: a toy button-clicking environment.

Demonstrates how to implement the ``TestEnvironment`` protocol
for use with the AI testing framework.
"""

from __future__ import annotations

from copy import deepcopy
from typing import Any, Dict, Optional, Sequence

from ai_testing.contracts import EpisodeResult, StepResult


class ToyButtonEnv:
    """Tiny deterministic environment simulating button clicks.

    The agent must "click" a sequence of buttons to pass.  This
    environment is purely in-memory and does not require a Godot
    runtime.  It serves as a reference implementation and smoke test.
    """

    action_space = ("click_a", "click_b", "click_c", "noop")

    def __init__(self, target_sequence: Sequence[str] = ("click_a", "click_b", "click_c"), max_steps: int = 12) -> None:
        self._target = list(target_sequence)
        self._max_steps = max_steps
        self._seed = 0
        self.reset()

    def reset(self, seed: Optional[int] = None) -> Dict[str, Any]:
        self._seed = 0 if seed is None else seed
        self.state: Dict[str, Any] = {
            "step": 0,
            "clicks_remaining": len(self._target),
            "progress": 0,
        }
        self._done = False
        self._result: Optional[EpisodeResult] = None
        return self.observe()

    def observe(self) -> Dict[str, Any]:
        return deepcopy(self.state) | {
            "valid_actions": list(self.action_space),
            "env": "toy_button_v0",
        }

    @property
    def result(self) -> Optional[EpisodeResult]:
        return self._result

    def step(self, action: str) -> StepResult:
        if self._done:
            return StepResult(self.observe(), 0.0, True, {"result": self._result})
        if action not in self.action_space:
            return StepResult(
                self.observe(), -1.0, False,
                {"error": f"unknown action: {action}"},
            )

        s = self.state
        s["step"] += 1
        reward = -0.01

        # Check if action matches the next target
        target_idx = s["progress"]
        if target_idx < len(self._target) and action == self._target[target_idx]:
            s["progress"] += 1
            s["clicks_remaining"] = len(self._target) - s["progress"]
            reward += 1.0
        elif action != "noop":
            reward -= 0.1

        # Check completion
        if s["progress"] >= len(self._target):
            self._done = True
            self._result = EpisodeResult("passed", "all_clicked", s["step"])
            return StepResult(self.observe(), reward + 5.0, True, {"result": self._result})

        if s["step"] >= self._max_steps:
            self._done = True
            self._result = EpisodeResult("failed", "timeout", s["step"])
            return StepResult(self.observe(), reward - 2.0, True, {"result": self._result})

        return StepResult(self.observe(), reward, False, {})
