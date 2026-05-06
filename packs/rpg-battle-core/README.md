# rpg-battle-core

> Toolbox-owned deterministic turn-based battle contracts.

| Field | Value |
|-------|-------|
| Kind | `architecture-core` |
| Default | `false` |
| Requires | `base`, `rpg-core`, `flow-core`, `rules-events-core` |
| Conflicts | — |

## Quick Start

```bash
./scripts/bootstrap_toolbox_project.sh /path/to/project --packs=rpg-battle-core
```

Preview without writing:
```bash
./scripts/bootstrap_toolbox_project.sh /path/to/project --packs=rpg-battle-core --dry-run-report
```

Note: requires `rpg-core`, `flow-core`, and `rules-events-core` (auto-resolved with their dependencies).

## What It Provides

- `RPGBattleCore` autoload singleton
- `CombatantState` — battle-specific combatant state (HP, buffs, position)
- `BattleSession` — bounded battle lifecycle (start → turns → result)
- `TurnQueue` — deterministic turn ordering with speed/priority
- `BattleAction` / `SkillAction` / `ItemAction` — typed action contracts
- `TargetRule` — target selection constraints (single, all, self, ally)
- `DamageFormula` — configurable damage calculation with modifiers
- `BattleResult` — structured outcome with rewards
- `RewardGrant` — XP, item, and currency rewards
- `DeterministicEnemyAI` — seedable enemy decision policy
- `RPGBeehaveAIAdapter` — optional adapter for Beehave behavior trees

## When to Enable

- Projects implementing turn-based RPG combat with deterministic rules
- Games that need battle state independent of AI authoring tools
- Any project using `rpg-test-kit` (it depends on this pack)

## Verification

```bash
bash ./scripts/verify_rpg_battle_core_pack.sh
```

## Contract Details

This pack defines the first-party boundary for battle sessions, combatants, turn queues, actions, target rules, damage formulas, rewards, and deterministic enemy policy.

- `RPGBattleCore.pack_id()` — returns `rpg-battle-core`
- `RPGBattleCore.required_contracts()` — declares `rpg-core`, `flow-core`, and `rules-events-core`
- `BattleSession` — manages battle lifecycle; integrates with `flow-core` as a game mode
- `TurnQueue` — deterministic ordering based on combatant speed and action priority
- `DamageFormula` — configurable formula with attacker stats, defender stats, elemental modifiers
- `DeterministicEnemyAI` — seed-based decision making for reproducible battle replays

### Beehave Integration

`RPGBeehaveAIAdapter` provides an optional adapter boundary for projects using the `ai-behavior` pack. The default battle smoke works **without** Beehave. Beehave remains optional for authored behavior trees — the first-pass battle template must work with deterministic policy code and no behavior-tree dependency.

### Event Integration

Battle events (turn start, action executed, damage applied, battle ended) are emitted through `rules-events-core`, enabling quest triggers, dialogue hooks, and achievement tracking.

## Upstream

Toolbox-owned. No vendored dependencies.
