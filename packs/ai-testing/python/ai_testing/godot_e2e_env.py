"""GodotE2E bridge environment for AI testing.

Adapts the ``godot_e2e`` TCP client to the ``TestEnvironment``
protocol, enabling AI testing policies to interact with a live
Godot runtime through the automation pack's infrastructure.

Layer 3: ai-testing pack  (this file)
         |  GodotE2EEnv implements TestEnvironment protocol
Layer 2: automation pack  (godot-e2e Python TCP client)
         |  JSON commands over length-prefixed binary framing
Layer 1: automation pack  (AutomationServer autoload in Godot)
"""

from __future__ import annotations

from typing import Any, Dict, List, Optional, Sequence

from .contracts import EpisodeResult, StepResult


class GodotE2EEnv:
    """TestEnvironment bridge to a live Godot runtime via godot-e2e.

    This environment wraps a ``godot_e2e.GodotE2E`` client instance
    and exposes it through the ``TestEnvironment`` protocol.

    Parameters
    ----------
    client:
        A connected ``godot_e2e.GodotE2E`` client instance.
    actions:
        Mapping of action names to execution callables.  Each callable
        receives the client and should return a dict of info.
    observe_nodes:
        List of node paths to read properties from for observations.
    done_condition:
        Optional callable that takes the observation dict and returns
        ``True`` when the episode should end.

    Usage::

        from godot_e2e import GodotE2E

        with GodotE2E.launch(project_path) as client:
            env = GodotE2EEnv(
                client=client,
                actions={"click": lambda c: c.click_node("/root/Main/Button")},
            )
            obs = env.reset()
    """

    def __init__(
        self,
        client: Any,
        actions: Optional[Dict[str, Any]] = None,
        observe_nodes: Optional[List[str]] = None,
        done_condition: Optional[Any] = None,
    ) -> None:
        self._client = client
        self._actions = actions or {}
        self._observe_nodes = observe_nodes or []
        self._done_condition = done_condition
        self._done = False
        self._result: Optional[EpisodeResult] = None
        self._step_count = 0

    @property
    def action_space(self) -> Sequence[str]:
        return tuple(self._actions.keys())

    def reset(self, seed: Optional[int] = None) -> Dict[str, Any]:
        """Reset the environment state."""
        self._done = False
        self._result = None
        self._step_count = 0
        return self._observe()

    def step(self, action: str) -> StepResult:
        """Execute an action via the godot-e2e client."""
        if self._done:
            return StepResult(self._observe(), 0.0, True, {"result": self._result})

        if action not in self._actions:
            return StepResult(
                self._observe(), -1.0, False,
                {"error": f"unknown action: {action}"},
            )

        self._step_count += 1
        action_fn = self._actions[action]
        info: Dict[str, Any] = {}

        try:
            result = action_fn(self._client)
            if isinstance(result, dict):
                info.update(result)
        except Exception as exc:
            info["error"] = str(exc)
            self._done = True
            self._result = EpisodeResult(
                "failed", f"action_error: {action}",
                self._step_count,
                metrics={"error": str(exc)},
            )
            return StepResult(
                self._observe(), -5.0, True,
                {"result": self._result},
            )

        reward = info.get("reward", -0.01)
        observation = self._observe()

        if self._done_condition and self._done_condition(observation):
            self._done = True
            self._result = EpisodeResult(
                "passed", "done_condition_met", self._step_count,
            )
            return StepResult(observation, reward, True, {"result": self._result})

        return StepResult(observation, reward, False, info)

    @property
    def result(self) -> Optional[EpisodeResult]:
        return self._result

    def _observe(self) -> Dict[str, Any]:
        """Collect observation from configured node paths."""
        obs: Dict[str, Any] = {
            "step": self._step_count,
            "valid_actions": list(self._actions.keys()),
            "env": "godot_e2e_v0",
        }
        for node_path in self._observe_nodes:
            try:
                if self._client.node_exists(node_path):
                    props: Dict[str, Any] = {}
                    for prop in ("name", "visible", "position", "text"):
                        try:
                            val = self._client.get_property(node_path, prop)
                            if val is not None:
                                props[prop] = val
                        except Exception:
                            pass
                    obs[node_path] = props
            except Exception:
                obs[node_path] = {"exists": False}
        return obs


__all__ = ["GodotE2EEnv"]
