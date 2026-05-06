"""Framework smoke tests for ai_testing package.

These tests verify the framework's contracts, policies, runner,
coverage tracker, and bug discovery -- all in pure Python without
requiring a Godot runtime.
"""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

# Ensure the pack's python directory is on sys.path
_PACK_PYTHON = str(Path(__file__).resolve().parents[2] / "python")
if _PACK_PYTHON not in sys.path:
    sys.path.insert(0, _PACK_PYTHON)

from ai_testing.contracts import EpisodeResult, StepResult, TestEnvironment
from ai_testing.policies import (
    EpsilonGreedyPolicy,
    HeuristicPolicy,
    RandomPolicy,
    ScriptedPolicy,
)
from ai_testing.coverage_tracker import CoverageTracker
from ai_testing.bug_discovery import BugDiscovery
from ai_testing.scenario_variant import ScenarioGenerator
from ai_testing.artifacts import ArtifactManager
from ai_testing.runner import EpisodeConfig, EpisodeRunner, default_output_dir


# -- Minimal test environment fixture --


class _MinimalEnv:
    """Smallest possible TestEnvironment for smoke testing."""

    action_space = ("a", "b", "c")

    def __init__(self):
        self._done = False
        self._step = 0
        self._result = None

    def reset(self, seed=None):  # noqa: ARG002
        self._done = False
        self._step = 0
        self._result = None
        return {"step": 0, "valid_actions": list(self.action_space), "env": "test"}

    def step(self, action):
        self._step += 1
        if self._step >= 3:
            self._done = True
            self._result = EpisodeResult("passed", "done", self._step)
            return StepResult(
                {"step": self._step, "valid_actions": list(self.action_space), "env": "test"},
                1.0, True, {"result": self._result},
            )
        return StepResult(
            {"step": self._step, "valid_actions": list(self.action_space), "env": "test"},
            -0.01, False, {},
        )

    @property
    def result(self):
        return self._result


@pytest.fixture
def env():
    return _MinimalEnv()


# -- Contract tests --


class TestContracts:
    def test_step_result_immutable(self):
        sr = StepResult({"x": 1}, 0.5, False, {})
        assert sr.observation == {"x": 1}
        assert sr.reward == 0.5
        assert not sr.done

    def test_episode_result_immutable(self):
        er = EpisodeResult("passed", "victory", 10, metrics={"score": 100})
        assert er.status == "passed"
        assert er.steps == 10

    def test_minimal_env_satisfies_protocol(self):
        env = _MinimalEnv()
        assert isinstance(env, TestEnvironment)


# -- Policy tests --


class TestPolicies:
    def test_random_policy_produces_valid_actions(self, env):
        policy = RandomPolicy(seed=42)
        obs = env.reset()
        for _ in range(20):
            action = policy.act(obs)
            assert action in env.action_space

    def test_scripted_policy_follows_script(self, env):
        policy = ScriptedPolicy(["a", "b", "c"], fallback="noop")
        obs = env.reset()
        assert policy.act(obs) == "a"
        assert policy.act(obs) == "b"
        assert policy.act(obs) == "c"
        assert policy.act(obs) == "noop"  # fallback

    def test_heuristic_policy_is_abstract(self):
        with pytest.raises(TypeError):
            HeuristicPolicy()  # type: ignore

    def test_epsilon_greedy_wraps_base(self, env):
        base = ScriptedPolicy(["a", "a", "a"])
        policy = EpsilonGreedyPolicy(base, epsilon=0.0, seed=42)
        obs = env.reset()
        assert policy.act(obs) == "a"


# -- Coverage tracker tests --


class TestCoverageTracker:
    def test_records_observations(self):
        tracker = CoverageTracker()
        tracker.record_observation({"a": 1, "b": 2})
        tracker.record_observation({"a": 1, "c": 3})
        assert tracker.obs_key_coverage == 1.0
        assert tracker.total_observations == 2

    def test_event_coverage(self):
        tracker = CoverageTracker(target_events={"click", "hover", "scroll"})
        tracker.record_step("click", {"events": ["click"]})
        assert tracker.event_coverage == pytest.approx(1 / 3)

    def test_summary_dict(self):
        tracker = CoverageTracker()
        tracker.record_observation({"x": 0})
        s = tracker.summary()
        assert "event_coverage" in s
        assert "obs_key_coverage" in s


# -- Bug discovery tests --


class TestBugDiscovery:
    def test_detects_unexplored_actions(self):
        bd = BugDiscovery()
        candidates = bd.analyze_episode(
            "test-ep-1",
            [{"step": 1, "reward": 0.0, "action": "a"}],
            ["a"],
            ["a", "b", "c"],
        )
        unexplored = [c for c in candidates if c.category == "unexplored_action"]
        assert len(unexplored) == 1
        assert "b" in unexplored[0].evidence["unexplored"]

    def test_summary(self):
        bd = BugDiscovery()
        bd.analyze_episode("ep1", [], [], ["a"])
        s = bd.summary()
        assert "total_candidates" in s


# -- Scenario variant tests --


class TestScenarioVariant:
    def test_generates_variants(self):
        gen = ScenarioGenerator(seeds=[7], max_steps_options=[16])
        variants = gen.generate("test_env", "random")
        assert len(variants) == 1
        assert variants[0].seed == 7
        assert variants[0].max_steps == 16

    def test_generate_for_policies(self):
        gen = ScenarioGenerator(seeds=[7], max_steps_options=[16])
        variants = gen.generate_for_policies("env", ["p1", "p2"])
        assert len(variants) == 2


# -- Artifact manager tests --


class TestArtifactManager:
    def test_creates_structure(self, tmp_output_dir):
        am = ArtifactManager(tmp_output_dir / "test")
        am.ensure_structure()
        errors = am.validate_structure()
        assert errors == []

    def test_episode_dir_creation(self, tmp_output_dir):
        am = ArtifactManager(tmp_output_dir / "test")
        am.ensure_structure()
        ep_dir = am.create_episode_dirs("ep-001")
        assert ep_dir.is_dir()
        assert (ep_dir / "logs").is_dir()
        assert (ep_dir / "screenshots").is_dir()


# -- Episode runner integration test --


class TestEpisodeRunner:
    def test_run_episode_and_finalize(self, tmp_output_dir):
        runner = EpisodeRunner(tmp_output_dir)
        env = _MinimalEnv()
        policy = ScriptedPolicy(["a", "b", "c"], fallback="a")
        config = EpisodeConfig(
            episode_id="smoke-001",
            env_name="test_env",
            policy_name="scripted",
            seed=42,
            max_steps=10,
        )
        result = runner.run_episode(config, env, policy)
        assert result["episode_id"] == "smoke-001"
        assert result["status"] in ("passed", "failed")

        summary = runner.finalize()
        assert summary["total"] == 1
        assert "coverage" in summary
        assert "bug_candidates" in summary

    def test_default_output_dir(self):
        d = default_output_dir("/tmp/test-ai")
        assert d.parent == Path("/tmp/test-ai")
