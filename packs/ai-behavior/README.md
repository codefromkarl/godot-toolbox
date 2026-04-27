# AI Behavior Optional Pack

This pack vendors `Beehave` as an opt-in behavior-tree addon.

Source:

- Repository: <https://github.com/bitbrain/beehave>
- Version: `v2.9.2`
- Vendored subtree: `addons/beehave`
- Local target: `packs/ai-behavior/godot/addons/beehave`

Current boundaries:

- `default=false`
- Selected explicitly with `--packs=ai-behavior`
- Provides the `beehave` editor plugin and behavior-tree runtime/debugging surface
- Not required for the first version of a turn-based RPG battle template
- Does not own combat turn order, enemy intent rules, encounter rewards, or save truth

Use this pack for projects that need explicit behavior-tree authoring for NPCs, enemies, or simulation actors. Start simpler for deterministic turn-based combat, then opt in when enemy behavior grows beyond small policy functions.

