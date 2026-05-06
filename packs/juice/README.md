# Juice Optional Pack

This pack vendors `Sparkle Lite` as an opt-in game-feel/feedback authoring addon.

Source:

- Asset Library: <https://godotassetlibrary.com/asset/4KshIx/sparkle-lite-%E2%80%94-game-feel-plugin-for-godot-4>
- Version: `1.0.0`
- Vendored subtree: `addons/sparkle_lite`
- Local target: `packs/juice/godot/addons/sparkle_lite`
- License / NOTICE: MIT; see `docs/rpg-vendor-license-notice.md`

Current boundaries:

- `default=false`
- Selected explicitly with `--packs=juice`
- Requires `base` only
- Provides the `sparkle_lite` editor plugin and its game-feel feedback primitives
- Does not own project truth, save schemas, gameplay rules, or visual asset pipeline

Use this pack when a project needs quick game-feel feedback authoring workflows, but keep project-owned code responsible for feedback triggers, timing, and integration with gameplay systems.
