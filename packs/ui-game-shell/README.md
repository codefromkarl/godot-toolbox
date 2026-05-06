# ui-game-shell

> Toolbox-owned app shell primitives — menu, pause, modal, and loading without taking over your project.

| Field | Value |
|-------|-------|
| Kind | `optional-pack` |
| Default | `false` |
| Requires | `base` |
| Conflicts | — |

## Quick Start

```bash
./scripts/bootstrap_toolbox_project.sh /path/to/project --packs=ui-game-shell
```

Preview without writing:
```bash
./scripts/bootstrap_toolbox_project.sh /path/to/project --packs=ui-game-shell --dry-run-report
```

## What It Provides

- `ShellRoot` — hosts shell layers (menu, pause, modal, loading)
- `ModalLayer` — opens and closes named modal controls with stacking support
- `PauseOverlay` — emits pause/resume requests to the game
- `LoadingOverlay` — emits completion signals for loading state
- `ShellFlowBridge` — optionally forwards shell requests to `FlowCore` when that pack is selected

## When to Enable

- Projects needing reusable UI shell composition without committing to a full game template
- Games that want pause, modal, and loading overlays as composable Control scripts
- Teams that prefer shell primitives over a monolithic menu/settings/pause template

## Verification

```bash
bash ./scripts/verify_ui_game_shell_pack.sh
```

## Contract Details

This pack provides reusable Control scripts for shell composition **without** replacing a project's main scene, flow stack, save system, or business state.

### ShellRoot

The root container that manages shell layers. Layers are stacked in a defined order: loading → pause → modal → menu. Each layer can be shown or hidden independently.

### ModalLayer

Opens and closes named modal controls. Supports stacking multiple modals with proper input blocking. Modals are identified by string name and loaded from configurable paths.

### PauseOverlay

Emits `pause_requested` and `resume_requested` signals. Does not directly pause the game tree — the owning project decides how to handle pause state.

### LoadingOverlay

Shows a loading indicator and emits `loading_complete` when done. Useful for scene transitions or resource preloading.

### ShellFlowBridge

An optional bridge that forwards shell events (pause, resume, mode change requests) to `FlowCore` when the `flow-core` pack is also selected. This bridge is inert when `flow-core` is not present.

## Recipe Boundary

See [docs/ui-game-shell-recipe.md](../../docs/ui-game-shell-recipe.md) for the governed shell recipe. `ui-game-shell` is the default controlled route for app shell primitives.

### Candidate Shell Pack

`packs/shell/` (Maaack's Game Template) remains candidate/reference material and must **not** take over `run/main_scene`, autoloads, save truth, or the FlowCore stack. It is not in `packs.manifest.json` by default.

## Upstream

Toolbox-owned. No vendored dependencies.

Candidate reference: `Maaack's Game Template` (vendored at `packs/shell/`, not in manifest).
