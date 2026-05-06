# rules-events-core

> Toolbox-owned event / condition / effect spine for quest, dialogue, simulation, and gameplay trigger packs.

| Field | Value |
|-------|-------|
| Kind | `architecture-core` |
| Default | `false` |
| Requires | `base` |
| Conflicts | — |

## Quick Start

```bash
./scripts/bootstrap_toolbox_project.sh /path/to/project --packs=rules-events-core
```

Preview without writing:
```bash
./scripts/bootstrap_toolbox_project.sh /path/to/project --packs=rules-events-core --dry-run-report
```

## What It Provides

- `RulesEventsCore` autoload singleton
- `GameEvent` — stable event ID plus payload dictionary
- `ExecutionContext` — memory scopes shared by conditions and effects
- `EventCondition` — deterministic pass/fail checks with a reason
- `EffectCommand` — bounded side effects against an execution context
- `EventQueue` — ordered event processing with execution results

## When to Enable

- Projects needing a centralized event/condition/effect execution spine
- Games with quest, dialogue, or trigger systems that require stable event boundaries
- Any project using `quest`, `dialogue`, `rpg-battle-core`, or `rpg-save-adapter` (they depend on this pack)

## Verification

```bash
bash ./scripts/verify_rules_events_core_pack.sh
```

## Contract Details

This pack provides a minimal runtime contract for event-driven gameplay:

- `RulesEventsCore.emit(event)` — queues a `GameEvent` for processing
- `RulesEventsCore.register_condition(id, condition)` — binds an `EventCondition` to an event ID
- `RulesEventsCore.register_effect(id, effect)` — binds an `EffectCommand` to an event ID
- `RulesEventsCore.process_queue()` — evaluates conditions and executes effects in order
- `EventQueue` ensures deterministic processing order

The pack does **not** replace a quest, dialogue, or visual scripting system. It provides the stable execution boundary that higher-level packs (quest, dialogue, RPG battle) build upon.

## Upstream

Toolbox-owned. No vendored dependencies.

Reference: `mef` (reference-only, not vendored) for execution group / condition / effect model ideas.
