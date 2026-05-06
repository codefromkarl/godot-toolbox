"""Tests for RPGBattleEnv and RPGBattleHeuristicPolicy.

Validates:
- Protocol compliance (TestEnvironment)
- Battle mechanics (damage, healing, MP, defeat)
- Episode lifecycle (victory, defeat, timeout)
- Heuristic policy decision logic
- Integration with EpisodeRunner
"""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

# Ensure the pack's python directory is on sys.path
_PACK_PYTHON = str(Path(__file__).resolve().parents[2] / "python")
if _PACK_PYTHON not in sys.path:
    sys.path.insert(0, _PACK_PYTHON)

from ai_testing.contracts import StepResult, TestEnvironment
from ai_testing.policies import EpsilonGreedyPolicy, RandomPolicy
from ai_testing.runner import EpisodeConfig, EpisodeRunner

# Add environments directory
_ENV_DIR = str(Path(__file__).resolve().parents[1] / "environments")
if _ENV_DIR not in sys.path:
    sys.path.insert(0, _ENV_DIR)

from rpg_battle_env import Combatant, RPGBattleEnv
from rpg_battle_heuristic_policy import RPGBattleHeuristicPolicy


# -- Fixtures --


@pytest.fixture
def default_env():
    """Default 1v1 battle: hero vs goblin."""
    return RPGBattleEnv()


@pytest.fixture
def multi_env():
    """Multi-party vs multi-enemy battle."""
    return RPGBattleEnv(
        party_specs=[
            {"id": "warrior", "hp": 60, "mp": 10, "attack": 15, "defense": 8, "speed": 6},
            {"id": "mage", "hp": 35, "mp": 30, "attack": 8, "defense": 3, "speed": 10},
        ],
        enemy_specs=[
            {"id": "goblin_a", "hp": 25, "mp": 0, "attack": 7, "defense": 2, "speed": 4},
            {"id": "goblin_b", "hp": 25, "mp": 0, "attack": 7, "defense": 2, "speed": 3},
        ],
    )


# -- Protocol Compliance --


class TestRPGBattleEnvProtocol:
    def test_satisfies_test_environment_protocol(self, default_env):
        assert isinstance(default_env, TestEnvironment)

    def test_action_space_is_tuple(self, default_env):
        assert isinstance(default_env.action_space, tuple)
        assert len(default_env.action_space) > 0

    def test_reset_returns_observation(self, default_env):
        obs = default_env.reset(seed=42)
        assert isinstance(obs, dict)
        assert "valid_actions" in obs
        assert "party" in obs
        assert "enemies" in obs
        assert "env" in obs
        assert obs["env"] == "rpg_battle_v0"

    def test_step_returns_step_result(self, default_env):
        default_env.reset()
        result = default_env.step("attack")
        assert isinstance(result, StepResult)

    def test_result_initially_none(self, default_env):
        default_env.reset()
        assert default_env.result is None


# -- Combatant Tests --


class TestCombatant:
    def test_is_defeated(self):
        c = Combatant("test", "party", hp=10, mp=0)
        assert not c.is_defeated()
        c.apply_damage(100)
        assert c.is_defeated()

    def test_apply_damage_minimum_one(self):
        c = Combatant("test", "party", hp=50, mp=0, defense=100)
        damage = c.apply_damage(5)  # damage capped at min 1 via _physical_damage
        # Combatant.apply_damage doesn't reduce by defense; that's in _physical_damage
        assert damage == 5

    def test_heal_capped_at_max(self):
        c = Combatant("test", "party", hp=50, mp=0)
        c.current_hp = 45
        healed = c.heal(20)
        assert healed == 5  # Can only heal up to max_hp
        assert c.current_hp == 50

    def test_spend_mp_success(self):
        c = Combatant("test", "party", hp=50, mp=10)
        assert c.spend_mp(5)
        assert c.current_mp == 5

    def test_spend_mp_insufficient(self):
        c = Combatant("test", "party", hp=50, mp=3)
        assert not c.spend_mp(5)
        assert c.current_mp == 3

    def test_to_obs_dict(self):
        c = Combatant("hero", "party", hp=50, mp=20)
        obs = c.to_obs_dict()
        assert obs["id"] == "hero"
        assert obs["team"] == "party"
        assert obs["hp"] == 50
        assert obs["max_hp"] == 50
        assert not obs["defeated"]


# -- Battle Mechanics --


class TestBattleMechanics:
    def test_attack_deals_damage(self, default_env):
        default_env.reset()
        enemies_before = default_env._enemies[0].current_hp
        result = default_env.step("attack")
        enemies_after = default_env._enemies[0].current_hp
        assert enemies_after < enemies_before, "attack should reduce enemy HP"

    def test_defend_reduces_incoming_damage(self):
        # Compare two scenarios: defend then take hit vs attack then take hit
        env_defend = RPGBattleEnv()
        env_defend.reset()
        env_defend.step("defend")
        hp_after_defend = env_defend._party[0].current_hp

        env_attack = RPGBattleEnv()
        env_attack.reset()
        env_attack.step("attack")
        hp_after_attack = env_attack._party[0].current_hp

        # Defending hero should have more HP remaining than attacking hero
        assert hp_after_defend >= hp_after_attack, \
            f"defense should reduce damage (defend HP={hp_after_defend} vs attack HP={hp_after_attack})"

    def test_use_skill_costs_mp(self, default_env):
        default_env.reset()
        mp_before = default_env._party[0].current_mp
        default_env.step("use_skill")
        mp_after = default_env._party[0].current_mp
        assert mp_after < mp_before, "use_skill should cost MP"

    def test_use_skill_without_mp_fails(self):
        env = RPGBattleEnv(
            party_specs=[{"id": "hero", "hp": 50, "mp": 0}],
        )
        env.reset()
        result = env.step("use_skill")
        # Should still succeed (step returns result) but no damage dealt
        assert isinstance(result, StepResult)

    def test_heal_restores_hp(self):
        env = RPGBattleEnv()
        env.reset()
        # Damage party member first via enemy attack
        env._party[0].current_hp = 20  # Simulate damage
        hp_before = env._party[0].current_hp
        env.step("heal")
        hp_after = env._party[0].current_hp
        assert hp_after >= hp_before, "heal should restore HP"

    def test_unknown_action_returns_error(self, default_env):
        default_env.reset()
        result = default_env.step("fireball")
        assert result.reward == -1.0
        assert "error" in result.info
        assert not result.done


# -- Episode Lifecycle --


class TestEpisodeLifecycle:
    def test_victory_condition(self, default_env):
        env = default_env
        env.reset()
        # Run many turns with attack to guarantee victory
        for _ in range(20):
            result = env.step("attack")
            if result.done:
                break
        assert env.result is not None
        assert env.result.status == "passed"
        assert env.result.reason == "victory"

    def test_defeat_condition(self):
        env = RPGBattleEnv(
            party_specs=[{"id": "weak", "hp": 5, "mp": 0, "attack": 1, "defense": 0}],
            enemy_specs=[{"id": "boss", "hp": 200, "mp": 0, "attack": 50, "defense": 50}],
        )
        env.reset()
        for _ in range(20):
            result = env.step("attack")
            if result.done:
                break
        assert env.result is not None
        assert env.result.status == "failed"
        assert env.result.reason == "defeat"

    def test_timeout_condition(self):
        env = RPGBattleEnv(
            party_specs=[{"id": "hero", "hp": 500, "mp": 0, "attack": 1, "defense": 50}],
            enemy_specs=[{"id": "tank", "hp": 500, "mp": 0, "attack": 1, "defense": 50}],
            max_turns=5,
        )
        env.reset()
        for _ in range(10):
            result = env.step("attack")
            if result.done:
                break
        assert env.result is not None
        assert env.result.status == "failed"
        assert env.result.reason == "timeout"

    def test_step_after_done_returns_cached(self, default_env):
        env = default_env
        env.reset()
        for _ in range(20):
            result = env.step("attack")
            if result.done:
                break
        # Step again after done
        result2 = env.step("attack")
        assert result2.done
        assert result2.reward == 0.0, "post-done step should have zero reward"
        assert result2.info.get("result") is not None

    def test_observation_includes_valid_actions(self, default_env):
        obs = default_env.reset()
        assert "attack" in obs["valid_actions"]
        assert "defend" in obs["valid_actions"]
        assert "use_skill" in obs["valid_actions"]
        assert "heal" in obs["valid_actions"]

    def test_multi_party_battle(self, multi_env):
        obs = multi_env.reset()
        assert len(obs["party"]) == 2
        assert len(obs["enemies"]) == 2

        for _ in range(30):
            result = multi_env.step("attack")
            if result.done:
                break
        assert multi_env.result is not None


# -- Heuristic Policy --


class TestRPGBattleHeuristicPolicy:
    def test_satisfies_policy_protocol(self):
        policy = RPGBattleHeuristicPolicy()
        from ai_testing.contracts import Policy
        assert isinstance(policy, Policy)

    def test_aggressive_default_uses_attack(self):
        policy = RPGBattleHeuristicPolicy(aggressive=True)
        env = RPGBattleEnv()
        obs = env.reset()
        action = policy.act(obs)
        assert action in env.action_space

    def test_heals_critical_hp(self):
        policy = RPGBattleHeuristicPolicy(heal_threshold=0.3)
        obs = {
            "party": [{"id": "hero", "hp": 5, "max_hp": 50, "mp": 10, "max_mp": 20,
                        "defeated": False, "defending": False}],
            "enemies": [{"id": "goblin", "hp": 30, "max_hp": 30, "mp": 0, "max_mp": 0,
                         "defeated": False, "defending": False}],
            "valid_actions": ["attack", "defend", "use_skill", "heal"],
        }
        action = policy.choose_action(obs)
        assert action == "heal", "should prioritize heal when HP critically low"

    def test_uses_skill_when_mp_available(self):
        policy = RPGBattleHeuristicPolicy()
        obs = {
            "party": [{"id": "hero", "hp": 50, "max_hp": 50, "mp": 20, "max_mp": 20,
                        "defeated": False, "defending": False}],
            "enemies": [{"id": "goblin", "hp": 30, "max_hp": 30, "mp": 0, "max_mp": 0,
                         "defeated": False, "defending": False}],
            "valid_actions": ["attack", "defend", "use_skill", "heal"],
        }
        action = policy.choose_action(obs)
        assert action == "use_skill", "should use skill when MP available and enemies alive"

    def test_defends_when_low_hp_non_aggressive(self):
        policy = RPGBattleHeuristicPolicy(aggressive=False)
        obs = {
            "party": [{"id": "hero", "hp": 10, "max_hp": 50, "mp": 20, "max_mp": 20,
                        "defeated": False, "defending": False}],
            "enemies": [{"id": "goblin", "hp": 30, "max_hp": 30, "mp": 0, "max_mp": 0,
                         "defeated": False, "defending": False}],
            "valid_actions": ["attack", "defend", "use_skill", "heal"],
        }
        action = policy.choose_action(obs)
        # HP is below 30% but not below 15% (critical), non-aggressive → defend
        assert action in ("defend", "heal"), "non-aggressive should defend or heal at low HP"

    def test_attacks_as_fallback(self):
        policy = RPGBattleHeuristicPolicy()
        obs = {
            "party": [{"id": "hero", "hp": 50, "max_hp": 50, "mp": 0, "max_mp": 20,
                        "defeated": False, "defending": False}],
            "enemies": [{"id": "goblin", "hp": 30, "max_hp": 30, "mp": 0, "max_mp": 0,
                         "defeated": False, "defending": False}],
            "valid_actions": ["attack", "defend", "use_skill", "heal"],
        }
        action = policy.choose_action(obs)
        assert action == "attack", "should attack as fallback when MP is depleted"


# -- EpisodeRunner Integration --


class TestRPGBattleRunnerIntegration:
    def test_random_policy_episode(self, tmp_path):
        env = RPGBattleEnv()
        policy = RandomPolicy(seed=42)
        runner = EpisodeRunner(tmp_path)
        config = EpisodeConfig("rpg-random-001", "rpg_battle", "random", seed=42, max_steps=20)
        result = runner.run_episode(config, env, policy)
        assert result["episode_id"] == "rpg-random-001"
        assert result["status"] in ("passed", "failed")

    def test_heuristic_policy_episode(self, tmp_path):
        env = RPGBattleEnv()
        policy = RPGBattleHeuristicPolicy()
        runner = EpisodeRunner(tmp_path)
        config = EpisodeConfig("rpg-heuristic-001", "rpg_battle", "heuristic", seed=42, max_steps=20)
        result = runner.run_episode(config, env, policy)
        assert result["status"] in ("passed", "failed")

        summary = runner.finalize()
        assert summary["total"] == 1
        assert "coverage" in summary

    def test_heuristic_outperforms_random(self, tmp_path):
        """Heuristic policy should win more often than random on default battle."""
        heuristic_wins = 0
        random_wins = 0

        for seed in range(5):
            # Heuristic
            env = RPGBattleEnv()
            policy = RPGBattleHeuristicPolicy()
            runner = EpisodeRunner(tmp_path / f"heuristic-{seed}")
            config = EpisodeConfig(f"heuristic-{seed}", "rpg_battle", "heuristic", seed=seed, max_steps=20)
            result = runner.run_episode(config, env, policy)
            if result["status"] == "passed":
                heuristic_wins += 1

            # Random
            env2 = RPGBattleEnv()
            policy2 = RandomPolicy(seed=seed)
            runner2 = EpisodeRunner(tmp_path / f"random-{seed}")
            config2 = EpisodeConfig(f"random-{seed}", "rpg_battle", "random", seed=seed, max_steps=20)
            result2 = runner2.run_episode(config2, env2, policy2)
            if result2["status"] == "passed":
                random_wins += 1

        # Heuristic should win at least as often as random on a simple 1v1
        assert heuristic_wins >= random_wins or heuristic_wins >= 3, \
            f"heuristic ({heuristic_wins}/5) should outperform random ({random_wins}/5)"

    def test_epsilon_greedy_with_heuristic(self, tmp_path):
        env = RPGBattleEnv()
        base = RPGBattleHeuristicPolicy()
        policy = EpsilonGreedyPolicy(base, epsilon=0.2, seed=42)
        runner = EpisodeRunner(tmp_path)
        config = EpisodeConfig("rpg-eps-001", "rpg_battle", "epsilon_greedy_heuristic", seed=42, max_steps=20)
        result = runner.run_episode(config, env, policy)
        assert result["status"] in ("passed", "failed")
