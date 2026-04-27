# rpg-battle-core

Toolbox-owned deterministic turn-based battle contract scaffold.

This pack defines the first-party boundary for battle sessions, combatants, turn queues, actions, target rules, damage formulas, rewards, and deterministic enemy policy. It depends on `rpg-core` for RPG state, `flow-core` for mode/result boundaries, and `rules-events-core` for event emission.

## Minimal Contract

- `RPGBattleCore.pack_id()` returns `rpg-battle-core`.
- `RPGBattleCore.required_contracts()` declares `rpg-core`, `flow-core`, and `rules-events-core`.
- Future resources in this pack own `CombatantState`, `BattleSession`, `TurnQueue`, `BattleAction`, `SkillAction`, `ItemAction`, `TargetRule`, `DamageFormula`, `BattleResult`, and `RewardGrant`.

Beehave remains optional for authored behavior trees. The first-pass battle template must work with deterministic policy code and no behavior-tree dependency.
