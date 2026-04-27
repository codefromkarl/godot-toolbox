# flow-core

Toolbox-owned flow contracts for complex Godot games.

This pack intentionally provides small runtime primitives instead of adopting a third-party scene manager as the source of truth. Projects can still use menu, transition, dialogue, or quest addons above this layer, but game mode/result/pause boundaries stay owned by the project.

## Provides

- `FlowCore` autoload
- `GameMode` resource contract
- `FlowRequest` resource contract
- `FlowResult` resource contract
- `PausePolicy` resource contract

## Minimal contract

`FlowCore.apply_request(request)` executes the request contract used by tests and bootstrapped projects:

- `FlowRequest.Kind.PUSH` pushes a valid `GameMode`.
- `FlowRequest.Kind.REPLACE` replaces the current `GameMode`.
- `FlowRequest.Kind.POP` pops the current `GameMode`.
- `FlowRequest.Kind.COMPLETE` records and emits a `FlowResult`.

`FlowCore.stack_size()`, `FlowCore.current_mode()`, and `FlowCore.last_result()` provide the minimal observable state needed by smoke tests without exposing the internal stack.
