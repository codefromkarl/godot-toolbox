# Dialogue Optional Pack

This pack vendors `Dialogue Manager` as an opt-in dialogue authoring/runtime addon.

Source:

- Repository: <https://github.com/nathanhoad/godot_dialogue_manager>
- Version: `v3.10.4`
- Vendored subtree: `addons/dialogue_manager`
- Local target: `packs/dialogue/godot/addons/dialogue_manager`
- License / NOTICE: MIT; see `docs/rpg-vendor-license-notice.md`

Current boundaries:

- `default=false`
- Selected explicitly with `--packs=dialogue`
- Requires `base`, `data-core`, `save-core`, `rules-events-core`
- Provides the `dialogue_manager` editor plugin and its dialogue graph/text resource authoring and runtime line playback primitives
- Does not own campaign truth, global story progression, save schema, persistent event history, quest truth, or inventory truth

Required integration boundaries:

- `rules-events-core` owns condition/effect/event execution semantics for dialogue-triggered gameplay changes
- `data-core` owns stable IDs and shared registry boundaries for speakers, dialogue resources, and content lookups
- `save-core` owns versioned snapshot structure and persistence mechanics
- Dialogue state may be projected into those contracts through an adapter, but the addon must not define the canonical campaign save schema or become the single source of story truth

Use this pack when a project wants dialogue graph/text resource authoring and runtime line playback, but keep project-owned adapters responsible for dialogue state persistence, event integration, and stable content IDs.
