"""Scenario variant generation for AI testing.

Generates episode configurations with parameterized variations for
systematic exploration of the test space.
"""

from __future__ import annotations

import itertools
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Sequence


@dataclass(frozen=True)
class ScenarioVariant:
    """A single scenario configuration variant."""

    variant_id: str
    seed: int
    max_steps: int
    noise_actions: Sequence[str]
    params: Dict[str, Any] = field(default_factory=dict)


class ScenarioGenerator:
    """Generates scenario variants from parameter matrices.

    Creates a Cartesian product of configuration dimensions to
    systematically explore the test space.

    Parameters
    ----------
    seeds:
        List of random seeds to use.
    max_steps_options:
        List of max_steps values to try.
    noise_actions:
        Actions to inject randomly between policy decisions.
        If ``None``, no noise actions are injected.
    extra_params:
        Additional parameter dicts to include in the Cartesian product.
    """

    def __init__(
        self,
        seeds: Sequence[int] = (7, 42, 0),
        max_steps_options: Sequence[int] = (16, 32, 64),
        noise_actions: Optional[Sequence[str]] = None,
        extra_params: Optional[Sequence[Dict[str, Any]]] = None,
    ) -> None:
        self._seeds = list(seeds)
        self._max_steps_options = list(max_steps_options)
        self._noise_actions = list(noise_actions) if noise_actions else []
        self._extra_params = list(extra_params) if extra_params else [{}]

    def generate(self, env_name: str, policy_name: str) -> List[ScenarioVariant]:
        """Generate all scenario variants for the given env/policy pair.

        Parameters
        ----------
        env_name:
            Environment identifier.
        policy_name:
            Policy identifier.

        Returns
        -------
        list of ScenarioVariant
        """
        variants: List[ScenarioVariant] = []
        idx = 0
        for seed, max_steps, params in itertools.product(
            self._seeds, self._max_steps_options, self._extra_params
        ):
            variant_id = f"{env_name}-{policy_name}-s{seed}-m{max_steps}"
            if params:
                # Add a short hash-like suffix for disambiguation
                param_suffix = "-".join(
                    f"{k}={v}" for k, v in sorted(params.items())
                )
                variant_id += f"-{param_suffix}"
            variants.append(
                ScenarioVariant(
                    variant_id=variant_id,
                    seed=seed,
                    max_steps=max_steps,
                    noise_actions=tuple(self._noise_actions),
                    params=params,
                )
            )
            idx += 1
        return variants

    def generate_for_policies(
        self,
        env_name: str,
        policy_names: Sequence[str],
    ) -> List[ScenarioVariant]:
        """Generate variants for multiple policies on one environment."""
        result: List[ScenarioVariant] = []
        for policy_name in policy_names:
            result.extend(self.generate(env_name, policy_name))
        return result


__all__ = ["ScenarioGenerator", "ScenarioVariant"]
