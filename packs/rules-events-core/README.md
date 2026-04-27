# rules-events-core

Toolbox-owned event / condition / effect spine for optional quest, dialogue, simulation, and gameplay trigger packs.

The pack provides a minimal runtime contract:

- `GameEvent`: stable event id plus payload dictionary.
- `ExecutionContext`: memory scopes shared by conditions and effects.
- `EventCondition`: deterministic pass/fail checks with a reason.
- `EffectCommand`: bounded side effects against an execution context.
- `EventQueue`: ordered event processing with execution results.

It does not replace a quest, dialogue, or visual scripting system.
