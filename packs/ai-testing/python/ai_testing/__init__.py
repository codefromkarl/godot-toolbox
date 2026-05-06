"""AI testing framework for godot-toolbox.

Provides strategy-driven exploration, coverage tracking, and bug
discovery for automated testing of Godot projects.  Built on top of
the automation pack's ``godot-e2e`` TCP bridge.

This package is domain-agnostic: consumers implement the
``TestEnvironment`` protocol for their specific game systems.
"""

from .artifacts import ArtifactManager
from .bug_discovery import BugCandidate, BugDiscovery
from .contracts import EpisodeResult, Policy, StepResult, TestEnvironment
from .coverage_tracker import CoverageTracker
from .godot_e2e_env import GodotE2EEnv
from .policies import (
    EpsilonGreedyPolicy,
    HeuristicPolicy,
    RandomPolicy,
    ScriptedPolicy,
)
from .runner import EpisodeConfig, EpisodeRunner, default_output_dir
from .scenario_variant import ScenarioGenerator, ScenarioVariant
from .summary_report import write_episode_artifacts, write_suite_artifacts

__all__ = [
    "ArtifactManager",
    "BugCandidate",
    "BugDiscovery",
    "CoverageTracker",
    "EpisodeConfig",
    "EpisodeResult",
    "EpisodeRunner",
    "EpsilonGreedyPolicy",
    "GodotE2EEnv",
    "HeuristicPolicy",
    "Policy",
    "RandomPolicy",
    "ScenarioGenerator",
    "ScenarioVariant",
    "ScriptedPolicy",
    "StepResult",
    "TestEnvironment",
    "default_output_dir",
    "write_episode_artifacts",
    "write_suite_artifacts",
]
