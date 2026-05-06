# Debug Optional Pack

This pack vendors `Signal Lens` as an opt-in runtime signal graph debugging addon.

Source:

- Repository: <https://github.com/yannlemos/signal-lens>
- Version: `1.4.1`
- Vendored subtree: `addons/signal_lens`
- Local target: `packs/debug/godot/addons/signal_lens`
- License / NOTICE: MIT; see `docs/rpg-vendor-license-notice.md`

Current boundaries:

- `default=false`
- Selected explicitly with `--packs=debug`
- Requires `base` only
- Provides the `signal_lens` editor plugin and its signal visualization/debugging primitives
- Does not own project truth, save schemas, gameplay rules, or runtime state

Use this pack when a project heavily relies on signal-based architecture and needs visual signal flow debugging, but keep project-owned code responsible for signal design patterns and runtime behavior.
