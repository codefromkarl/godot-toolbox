# Stateful Optional Pack

This pack vendors `Godot State Charts` as an opt-in explicit state machine/state chart architecture addon.

Source:

- Repository: <https://github.com/derkork/godot-statecharts>
- Version: `0.22.3`
- Vendored subtree: `addons/godot_state_charts`
- Local target: `packs/stateful/godot/addons/godot_state_charts`
- License / NOTICE: MIT; see `docs/rpg-vendor-license-notice.md`

Current boundaries:

- `default=false`
- Selected explicitly with `--packs=stateful`
- Requires `base` only
- Provides the `godot_state_charts` editor plugin and its state chart/transitions primitives
- Does not own project truth, save schemas, gameplay rules, or flow control semantics

Use this pack when a project needs explicit state chart modeling for complex behavior, but keep project-owned adapters responsible for state persistence, transition side effects, and integration with `flow-core` or `rules-events-core`.
