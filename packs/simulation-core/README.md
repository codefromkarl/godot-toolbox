# simulation-core

> Toolbox-owned simulation boundaries for projects with long-lived world state.

| Field | Value |
|-------|-------|
| Kind | `architecture-core` |
| Default | `false` |
| Requires | `base`, `flow-core` |
| Conflicts | — |

## Quick Start

```bash
./scripts/bootstrap_toolbox_project.sh /path/to/project --packs=simulation-core
```

Preview without writing:
```bash
./scripts/bootstrap_toolbox_project.sh /path/to/project --packs=simulation-core --dry-run-report
```

Note: `simulation-core` requires `flow-core`, which is automatically resolved.

## What It Provides

- `SimulationCore` autoload singleton
- `TickScheduler` contract for stable tick/time-scale boundaries
- `ISimSystem` interface for registering simulation systems
- `SimClock` for controlled time progression with pause/resume support

## When to Enable

- Projects with long-lived world state that should not be tied to arbitrary Node lifecycles
- Games needing deterministic tick scheduling separate from Godot physics frames
- Simulation or strategy games with time-scale controls (pause, fast-forward)

## Verification

```bash
bash ./scripts/verify_game_architecture_packs.sh
```

## Contract Details

`SimulationCore` provides a small tick scheduler and system contract:

- `SimulationCore.register_system(system)` registers an `ISimSystem` implementation
- `SimulationCore.tick(delta)` advances all registered systems with the given delta
- `SimulationCore.set_time_scale(scale)` controls simulation speed; `0.0` pauses
- `SimulationCore.get_time_scale()` returns the current time scale

The pack intentionally does not replace Godot physics or impose a genre-specific world model. It provides a stable boundary so long-lived simulation state is not accidentally coupled to Node tree lifecycle.

## Upstream

Toolbox-owned. No vendored dependencies.

References: `flow-core` for mode boundaries; `scene_manager` (reference-only, not vendored) for transition ideas.
