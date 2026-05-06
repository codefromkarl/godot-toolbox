"""RPG Battle TestEnvironment for AI testing framework.

Implements the ``TestEnvironment`` protocol with a simplified turn-based
RPG battle system that mirrors the logic in ``rpg-battle-core``'s
``BattleSession`` and ``DamageFormula``.

This environment is purely in-memory and does not require a Godot runtime.
It serves as the first domain-specific TestEnvironment consumer, bridging
the ai-testing framework with rpg-battle-core concepts.

Battle rules (mirrors GDScript logic):
- Damage = max(1, attacker.attack + power - target.defense)
- Party acts first each round, then enemies
- Victory when all enemies defeated; defeat when all party defeated
- Actions: attack, defend, use_skill, heal
"""

from __future__ import annotations

from typing import Any, Dict, List, Optional, Sequence

from ai_testing.contracts import EpisodeResult, StepResult


class Combatant:
    """In-memory combatant matching CombatantState fields."""

    def __init__(
        self,
        combatant_id: str = "",
        team_id: str = "party",
        hp: int = 30,
        mp: int = 0,
        attack: int = 10,
        defense: int = 5,
        speed: int = 5,
        *,
        id: str = "",  # Alias for combatant_id (spec convenience)
    ) -> None:
        self.combatant_id = combatant_id or id
        self.team_id = team_id
        self.max_hp = hp
        self.current_hp = hp
        self.max_mp = mp
        self.current_mp = mp
        self.attack = attack
        self.defense = defense
        self.speed = speed
        self.defending = False

    def is_defeated(self) -> bool:
        return self.current_hp <= 0

    def apply_damage(self, amount: int) -> int:
        actual = max(1, amount)
        self.current_hp = max(0, self.current_hp - actual)
        return actual

    def heal(self, amount: int) -> int:
        actual = min(amount, self.max_hp - self.current_hp)
        self.current_hp = min(self.max_hp, self.current_hp + actual)
        return actual

    def spend_mp(self, cost: int) -> bool:
        if self.current_mp < cost:
            return False
        self.current_mp -= cost
        return True

    def to_obs_dict(self) -> Dict[str, Any]:
        return {
            "id": self.combatant_id,
            "team": self.team_id,
            "hp": self.current_hp,
            "max_hp": self.max_hp,
            "mp": self.current_mp,
            "max_mp": self.max_mp,
            "defeated": self.is_defeated(),
            "defending": self.defending,
        }


def _physical_damage(attacker: Combatant, target: Combatant, power: int = 0) -> int:
    """Mirror of DamageFormula.physical_damage."""
    effective_def = target.defense * 2 if target.defending else target.defense
    return max(1, attacker.attack + max(0, power) - effective_def)


class RPGBattleEnv:
    """Turn-based RPG battle environment for AI testing.

    Implements the ``TestEnvironment`` protocol.  Party members are
    controlled by the agent; enemies use deterministic AI (always attack
    the first alive party member).

    Parameters
    ----------
    party_specs:
        List of dicts defining party members (id, hp, mp, attack, defense, speed).
    enemy_specs:
        List of dicts defining enemies (same keys).
    max_turns:
        Maximum number of party turns before timeout.
    """

    action_space = ("attack", "defend", "use_skill", "heal")  # type: ignore[assignment]

    def __init__(
        self,
        party_specs: Optional[Sequence[Dict[str, Any]]] = None,
        enemy_specs: Optional[Sequence[Dict[str, Any]]] = None,
        max_turns: int = 20,
    ) -> None:
        self._party_specs = party_specs or [
            {"id": "hero", "hp": 50, "mp": 20, "attack": 12, "defense": 5, "speed": 8},
        ]
        self._enemy_specs = enemy_specs or [
            {"id": "goblin", "hp": 30, "mp": 0, "attack": 8, "defense": 3, "speed": 4},
        ]
        self._max_turns = max_turns
        self._done = False
        self._result: Optional[EpisodeResult] = None
        self._party: List[Combatant] = []
        self._enemies: List[Combatant] = []
        self._turn: int = 0
        self._active_party_idx: int = 0
        self._battle_log: List[Dict[str, Any]] = []

    def reset(self, seed: Optional[int] = None) -> Dict[str, Any]:  # noqa: ARG002
        self._done = False
        self._result = None
        self._turn = 0
        self._active_party_idx = 0
        self._battle_log = []

        self._party = [Combatant(**spec) for spec in self._party_specs]
        self._enemies = [Combatant(**spec) for spec in self._enemy_specs]

        return self._observe()

    def step(self, action: str) -> StepResult:
        if self._done:
            return StepResult(self._observe(), 0.0, True, {"result": self._result})

        if action not in self.action_space:
            return StepResult(
                self._observe(), -1.0, False,
                {"error": f"unknown action: {action}"},
            )

        # Get active party member
        actor = self._get_active_party_member()
        if actor is None:
            # All party defeated — should not reach here, but guard
            self._finish_battle()
            return StepResult(self._observe(), -10.0, True, {"result": self._result})

        reward = 0.0
        events: List[str] = []

        # Execute party action
        reward, events = self._execute_party_action(actor, action)

        # Check if battle ended after party action
        if self._check_battle_end():
            return StepResult(self._observe(), reward, True, {"result": self._result, "events": events})

        # Enemy turn: each alive enemy attacks first alive party member
        enemy_reward, enemy_events = self._execute_enemy_turn()
        reward += enemy_reward
        events.extend(enemy_events)

        # Check if battle ended after enemy action
        if self._check_battle_end():
            return StepResult(self._observe(), reward, True, {"result": self._result, "events": events})

        # Advance turn
        self._turn += 1
        self._active_party_idx = self._next_alive_party_idx()

        # Clear defending flags
        for c in self._party:
            c.defending = False

        # Check turn limit
        if self._turn >= self._max_turns:
            self._finish_battle()
            return StepResult(
                self._observe(), reward - 2.0, True,
                {"result": self._result, "events": events},
            )

        return StepResult(self._observe(), reward, False, {"events": events})

    @property
    def result(self) -> Optional[EpisodeResult]:
        return self._result

    # -- Private helpers --

    def _get_active_party_member(self) -> Optional[Combatant]:
        for c in self._party:
            if not c.is_defeated():
                return c
        return None

    def _next_alive_party_idx(self) -> int:
        for idx, c in enumerate(self._party):
            if not c.is_defeated():
                return idx
        return 0

    def _execute_party_action(
        self, actor: Combatant, action: str
    ) -> tuple:
        reward = -0.01  # Small step penalty
        events: List[str] = []

        if action == "attack":
            target = self._first_alive_enemy()
            if target:
                damage = _physical_damage(actor, target)
                actual = target.apply_damage(damage)
                reward += actual * 0.1  # Reward for dealing damage
                events.append(f"{actor.combatant_id}:attack:{target.combatant_id}:{actual}")
                self._battle_log.append({
                    "actor": actor.combatant_id,
                    "action": "attack",
                    "target": target.combatant_id,
                    "damage": actual,
                })

        elif action == "defend":
            actor.defending = True
            reward += 0.05  # Small reward for tactical defense
            events.append(f"{actor.combatant_id}:defend")
            self._battle_log.append({
                "actor": actor.combatant_id,
                "action": "defend",
            })

        elif action == "use_skill":
            mp_cost = 5
            if actor.spend_mp(mp_cost):
                target = self._first_alive_enemy()
                if target:
                    damage = _physical_damage(actor, target, power=actor.attack)
                    actual = target.apply_damage(damage)
                    reward += actual * 0.15  # Higher reward for skill usage
                    events.append(f"{actor.combatant_id}:skill:{target.combatant_id}:{actual}")
                    self._battle_log.append({
                        "actor": actor.combatant_id,
                        "action": "use_skill",
                        "target": target.combatant_id,
                        "damage": actual,
                    })
            else:
                reward -= 0.5  # Penalty for failed skill (no MP)
                events.append(f"{actor.combatant_id}:skill_failed:no_mp")

        elif action == "heal":
            # Heal the most damaged party member
            target = self._most_damaged_party()
            if target:
                heal_amount = max(0, 10)
                actual = target.heal(heal_amount)
                reward += actual * 0.08  # Reward for healing
                events.append(f"{actor.combatant_id}:heal:{target.combatant_id}:{actual}")
                self._battle_log.append({
                    "actor": actor.combatant_id,
                    "action": "heal",
                    "target": target.combatant_id,
                    "heal": actual,
                })

        return reward, events

    def _execute_enemy_turn(self) -> tuple:
        reward = 0.0
        events: List[str] = []
        target = self._first_alive_party()

        for enemy in self._enemies:
            if enemy.is_defeated() or target is None:
                continue
            damage = _physical_damage(enemy, target)
            actual = target.apply_damage(damage)
            reward -= actual * 0.1  # Penalty for damage taken
            events.append(f"{enemy.combatant_id}:attack:{target.combatant_id}:{actual}")
            self._battle_log.append({
                "actor": enemy.combatant_id,
                "action": "attack",
                "target": target.combatant_id,
                "damage": actual,
            })
            # Retarget if current target was defeated
            if target.is_defeated():
                target = self._first_alive_party()

        return reward, events

    def _first_alive_enemy(self) -> Optional[Combatant]:
        for e in self._enemies:
            if not e.is_defeated():
                return e
        return None

    def _first_alive_party(self) -> Optional[Combatant]:
        for p in self._party:
            if not p.is_defeated():
                return p
        return None

    def _most_damaged_party(self) -> Optional[Combatant]:
        most_damaged: Optional[Combatant] = None
        max_missing = 0
        for p in self._party:
            if p.is_defeated():
                continue
            missing = p.max_hp - p.current_hp
            if missing > max_missing:
                max_missing = missing
                most_damaged = p
        return most_damaged

    def _alive_party(self) -> List[Combatant]:
        return [p for p in self._party if not p.is_defeated()]

    def _alive_enemies(self) -> List[Combatant]:
        return [e for e in self._enemies if not e.is_defeated()]

    def _check_battle_end(self) -> bool:
        if not self._alive_enemies():
            self._done = True
            self._result = EpisodeResult(
                "passed", "victory", self._turn,
                metrics={"party_alive": len(self._alive_party())},
            )
            return True
        if not self._alive_party():
            self._done = True
            self._result = EpisodeResult(
                "failed", "defeat", self._turn,
                metrics={"enemies_alive": len(self._alive_enemies())},
            )
            return True
        return False

    def _finish_battle(self) -> None:
        if self._result is not None:
            self._done = True
            return
        # Turn limit reached
        if self._alive_enemies() and self._alive_party():
            self._result = EpisodeResult("failed", "timeout", self._turn)
        elif not self._alive_enemies():
            self._result = EpisodeResult("passed", "victory", self._turn)
        else:
            self._result = EpisodeResult("failed", "defeat", self._turn)

    def _observe(self) -> Dict[str, Any]:
        return {
            "turn": self._turn,
            "party": [c.to_obs_dict() for c in self._party],
            "enemies": [c.to_obs_dict() for c in self._enemies],
            "battle_log_size": len(self._battle_log),
            "valid_actions": list(self.action_space),
            "env": "rpg_battle_v0",
        }


__all__ = ["Combatant", "RPGBattleEnv"]
