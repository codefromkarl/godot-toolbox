# Inventory Optional Pack

This pack vendors `GLoot` as an opt-in inventory/equipment workflow addon.

Source:

- Repository: <https://github.com/peter-kish/gloot>
- Version: `v3.0.1`
- Vendored subtree: `addons/gloot`
- Local target: `packs/inventory/godot/addons/gloot`

Current boundaries:

- `default=false`
- Selected explicitly with `--packs=inventory`
- Requires `data-core` and `save-core`
- Provides the `gloot` editor plugin and its inventory/item/equipment primitives
- Does not own RPG item truth, equipment rules, economy, loot rewards, or save format

Use this pack when a project wants a mature inventory authoring/runtime surface, but keep project-owned adapters responsible for stable item IDs, inventory serialization, equipment stat contribution, and `save-core` snapshot mapping.

