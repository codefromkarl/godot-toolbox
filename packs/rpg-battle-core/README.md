# rpg-battle-core

Toolbox-owned deterministic turn-based battle contracts.

This pack defines the first-party boundary for battle sessions, combatants, turn queues, actions, target rules, damage formulas, rewards, and deterministic enemy policy. It depends on `rpg-core` for RPG state, `flow-core` for mode/result boundaries, and `rules-events-core` for event emission.

## Minimal Contract

- `RPGBattleCore.pack_id()` returns `rpg-battle-core`.
- `RPGBattleCore.required_contracts()` declares `rpg-core`, `flow-core`, and `rules-events-core`.
- This pack owns `CombatantState`, `BattleSession`, `TurnQueue`, `BattleAction`, `SkillAction`, `ItemAction`, `TargetRule`, `DamageFormula`, `BattleResult`, `RewardGrant`, and `DeterministicEnemyAI`.
- `RPGBeehaveAIAdapter` is an optional adapter boundary. The default battle smoke works without Beehave.

Beehave remains optional for authored behavior trees. The first-pass battle template must work with deterministic policy code and no behavior-tree dependency.
