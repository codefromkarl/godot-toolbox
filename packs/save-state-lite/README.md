# SaveState Lite Optional Pack

This pack vendors `SaveState Lite` as an opt-in advanced save tooling/reference addon.

Source:

- Repository: <https://github.com/youssof20/savestate>
- Version: `v1.2.0`
- Vendored subtree: `addons/savestate`
- Local target: `packs/save-state-lite/godot/addons/savestate`
- License / NOTICE: MIT; see `docs/rpg-vendor-license-notice.md`

Current boundaries:

- `default=false`
- Selected explicitly with `--packs=save-state-lite`
- Conflicts with `save-core` because both define a global `SaveSlot` class
- Provides the `savestate` editor plugin and its SaveManager/atomic writer/save browser tooling
- Does not replace `save-core` as the project-owned persistence contract

Use this pack when a project wants SaveState Lite's editor tooling or component patterns as an alternative save surface. For the default RPG template path, keep long-term saves expressed through `save-core` snapshots so project state remains explicit, migratable, and testable.

## Local Patch Policy

This pack carries a locally maintained `ResourceUID` guard in `addons/savestate/editor/save_browser_dock.gd` for headless bootstrap/import stability. Preserve the patch during re-imports unless upstream ships an equivalent fix and the verification log proves the guard is no longer required.
