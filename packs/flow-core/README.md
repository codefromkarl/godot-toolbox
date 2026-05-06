# flow-core

> Toolbox-owned flow contracts for complex Godot games.

| Field | Value |
|-------|-------|
| Kind | `architecture-core` |
| Default | `false` |
| Requires | `base` |
| Conflicts | — |

## Quick Start

```bash
./scripts/bootstrap_toolbox_project.sh /path/to/project --packs=flow-core
```

Preview without writing:
```bash
./scripts/bootstrap_toolbox_project.sh /path/to/project --packs=flow-core --dry-run-report
```

## What It Provides

- `FlowCore` autoload singleton
- `GameMode` resource contract — defines a game mode (menu, exploration, battle, cutscene, etc.)
- `FlowRequest` resource contract — operations on the mode stack (push, replace, pop, complete)
- `FlowResult` resource contract — structured result data from a completed mode
- `PausePolicy` resource contract — pause/resume behavior per mode

## When to Enable

- Games with multiple game modes that need a managed mode stack
- Projects requiring structured transitions between screens, scenes, or gameplay states
- Any project using `simulation-core`, `rpg-battle-core`, or `flow-test-kit` (they depend on this pack)

## Verification

```bash
bash ./scripts/verify_game_architecture_packs.sh
```

## Contract Details

This pack intentionally provides small runtime primitives instead of adopting a third-party scene manager as the source of truth. Projects can still use menu, transition, dialogue, or quest addons above this layer, but game mode/result/pause boundaries stay owned by the project.

`FlowCore.apply_request(request)` executes the request contract used by tests and bootstrapped projects:

- `FlowRequest.Kind.PUSH` — pushes a valid `GameMode` onto the stack
- `FlowRequest.Kind.REPLACE` — replaces the current `GameMode`
- `FlowRequest.Kind.POP` — pops the current `GameMode`
- `FlowRequest.Kind.COMPLETE` — records and emits a `FlowResult`

Observable state for tests:

- `FlowCore.stack_size()` — current mode stack depth
- `FlowCore.current_mode()` — the active `GameMode`
- `FlowCore.last_result()` — the most recent `FlowResult`

These provide the minimal observable state needed by smoke tests without exposing the internal stack.

## Upstream

Toolbox-owned. No vendored dependencies.

Reference: `scene_manager` (reference-only, not vendored) for transition ideas; `flow-core` owns result semantics.
