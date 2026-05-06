# UI Game Shell Recipe

This recipe productizes the split between the toolbox-owned shell primitives and the Maaack template candidate.

## Decision

`ui-game-shell is the default governed extension route`.

`shell/Maaack's Game Template is a candidate/reference`.

Use `packs/ui-game-shell` when a project needs owned, minimal app-shell primitives that can be reviewed, verified, and evolved inside this repository. Use `packs/shell` only as a source of ideas for menus, pause flows, settings screens, credits, loading screens, opening scenes, input mapping, and persistent settings patterns.

## Hard Boundaries

Any recipe derived from the shell candidate must preserve these boundaries:

- `ui-game-shell` provides controlled primitives, not a full project template.
- `packs/shell` may inform design, but must not be copied as the default runtime shell.
- The shell candidate must not take over `run/main_scene`.
- The shell candidate must not add or replace project autoloads.
- The shell candidate must not become the save truth.
- The shell candidate must not replace the FlowCore stack.
- The shell candidate must not own project business runtime state, gameplay truth, UI copy truth, or release readiness claims.

## Absorption Pattern

Menus, pause, settings, and loading ideas may be absorbed selectively.

The governed path is:

1. Study the candidate implementation in `packs/shell/godot/addons/maaacks_game_template/`.
2. Extract the user-facing interaction idea, not the candidate's project ownership model.
3. Re-express the behavior through `packs/ui-game-shell` primitives such as `ShellRoot`, `ModalLayer`, `PauseOverlay`, `LoadingOverlay`, and `ShellFlowBridge`.
4. Keep project-specific scene selection, autoloads, save schema, FlowCore routes, and business state in the consuming project.
5. Add or update verification before claiming that a new shell behavior is governed.

## Current Verifiable Route

The current dry-run/report command for the governed route is:

```bash
python3 scripts/pack_manifest.py report --packs=ui-game-shell
```

The current pack verifier remains:

```bash
bash scripts/verify_ui_game_shell_pack.sh
```

This recipe verifier checks the boundary language, README/catalog links, the `ui-game-shell` pack report, and repository-portable documentation paths:

```bash
bash scripts/verify_ui_game_shell_recipe.sh
```

## Candidate Use

`packs/shell` can be used for product discovery and reference review. It should not appear in `packs.manifest.json`, default bootstrap paths, or generated app ownership instructions unless a later governance decision explicitly promotes a narrow, verified subset.

When adding shell features, prefer small self-owned primitives in `packs/ui-game-shell` over importing the candidate's template-level scene tree, autoload model, settings persistence, or runtime orchestration.
