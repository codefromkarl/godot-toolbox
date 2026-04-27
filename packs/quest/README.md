# Quest Optional Pack

This pack vendors `QuestSystem` as an opt-in quest workflow addon.

Source:

- Repository: <https://github.com/shomykohai/quest-system>
- Version: `2.0.1.4_4`
- Vendored subtree: `addons/quest_system`
- Local target: `packs/quest/godot/addons/quest_system`
- License / NOTICE: MIT; see `docs/rpg-vendor-license-notice.md`

Current boundaries:

- `default=false`
- Selected explicitly with `--packs=quest`
- Requires `data-core`, `save-core`, and `rules-events-core`
- Provides the `quest_system` editor plugin and its quest resources/runtime
- Does not own campaign truth, quest save format, story state, or gameplay event semantics

Use this pack when a project wants resource-based quests, but bridge quest state through toolbox-owned event and save contracts before treating it as durable project truth.
