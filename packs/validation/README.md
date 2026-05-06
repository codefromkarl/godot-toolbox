# Validation Optional Pack

This pack vendors `Godot Doctor` as an opt-in scene/resource rule validation addon.

Source:

- Repository: <https://github.com/codevogel/godot_doctor>
- Version: `2.1.2`
- Vendored subtree: `addons/godot_doctor`
- Local target: `packs/validation/godot/addons/godot_doctor`
- License / NOTICE: MIT; see `docs/rpg-vendor-license-notice.md`

Current boundaries:

- `default=false`
- Selected explicitly with `--packs=validation`
- Requires `base` only
- Provides the `godot_doctor` editor plugin and its scene/resource constraint checking primitives
- Does not own project truth, save schemas, gameplay rules, or CI pipeline configuration

Use this pack when a project wants executable scene/resource validation contracts in CI, but keep project-owned adapters responsible for rule definitions and CI integration.
