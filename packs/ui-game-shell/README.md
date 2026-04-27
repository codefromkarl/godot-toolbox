# ui-game-shell

Optional toolbox-owned app shell primitives.

This pack provides reusable Control scripts for shell composition without replacing a project's main scene, flow stack, save system, or business state.

Runtime contracts:

- `ShellRoot`: hosts shell layers.
- `ModalLayer`: opens and closes named modal controls.
- `PauseOverlay`: emits pause/resume requests.
- `LoadingOverlay`: emits completion for loading state.
- `ShellFlowBridge`: optionally forwards shell requests to `FlowCore` when that pack is selected.
