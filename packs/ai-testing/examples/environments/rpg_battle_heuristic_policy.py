"""Domain-specific heuristic policy for RPG battle testing.

Implements ``HeuristicPolicy`` with rule-based decisions based on
combatant HP, MP, and enemy state.  Designed to exercise the
``RPGBattleEnv`` more thoroughly than random or scripted policies
by prioritizing survival and efficient damage output.

Strategy:
1. Heal any party member below 30% HP (if a healer is available)
2. Use skills when MP > 50% and enemies are alive
3. Attack the weakest enemy (lowest HP)
4. Defend as last resort when HP is critically low
"""

from __future__ import annotations

from typing import Any, Mapping

from ai_testing.policies import HeuristicPolicy


class RPGBattleHeuristicPolicy(HeuristicPolicy):
    """Rule-based policy for RPG battle environments.

    Parameters
    ----------
    heal_threshold:
        HP fraction below which healing is prioritized (0.0-1.0).
    skill_mp_threshold:
        MP fraction above which skills are used (0.0-1.0).
    aggressive:
        If True, prioritize offense over defense.
    """

    def __init__(
        self,
        heal_threshold: float = 0.3,
        skill_mp_threshold: float = 0.5,
        aggressive: bool = True,
    ) -> None:
        self.heal_threshold = heal_threshold
        self.skill_mp_threshold = skill_mp_threshold
        self.aggressive = aggressive

    def choose_action(self, observation: Mapping[str, Any]) -> str:
        party = observation.get("party", [])
        enemies = observation.get("enemies", [])
        valid_actions = observation.get("valid_actions", [])

        if not party:
            return "attack"

        # Analyze party state
        any_critical = False
        any_low_hp = False
        has_mp = False

        for member in party:
            if member.get("defeated", False):
                continue
            hp_frac = member.get("hp", 0) / max(1, member.get("max_hp", 1))
            mp_frac = member.get("mp", 0) / max(1, member.get("max_mp", 1))
            if hp_frac < self.heal_threshold * 0.5:
                any_critical = True
            if hp_frac < self.heal_threshold:
                any_low_hp = True
            if mp_frac > self.skill_mp_threshold:
                has_mp = True

        # Analyze enemy state
        alive_enemies = [e for e in enemies if not e.get("defeated", False)]
        enemies_alive = len(alive_enemies) > 0

        # Decision priority

        # 1. Critical HP → heal if available
        if any_critical and "heal" in valid_actions:
            return "heal"

        # 2. Low HP with multiple enemies → defend (non-aggressive mode)
        if any_low_hp and not self.aggressive and enemies_alive and "defend" in valid_actions:
            return "defend"

        # 3. Use skill when MP is available and enemies are alive
        if has_mp and enemies_alive and "use_skill" in valid_actions:
            return "use_skill"

        # 4. Attack if enemies alive
        if enemies_alive and "attack" in valid_actions:
            return "attack"

        # 5. Heal if low HP (non-critical)
        if any_low_hp and "heal" in valid_actions:
            return "heal"

        # 6. Fallback
        if "attack" in valid_actions:
            return "attack"

        return str(list(valid_actions)[0]) if valid_actions else "noop"


__all__ = ["RPGBattleHeuristicPolicy"]
