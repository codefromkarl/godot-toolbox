# Game Architecture Template Open Source Scan 2026-04

## Snapshot

- Date: `2026-04-27`
- Scope: Godot 4.x reusable game architecture capabilities that can inform `godot-toolbox`
- Goal: identify what already exists, what can be vendored or referenced, and what should remain toolbox-owned

This scan is not about migrating any specific game. It looks for reusable architecture patterns that help future Godot projects avoid late-stage coupling around game flow, simulation, data, save, UI, quests, dialogue, input, events, and AI.

## Current Toolbox Baseline

Already present in this repository:

- `base`: `gdUnit4` and `godot-gdscript-toolkit`.
- `validation`: `Godot Doctor`.
- `debug`: `Signal Lens`.
- `stateful`: `Godot State Charts`.
- `juice`: `Sparkle Lite`.
- Candidate `automation`: `GodotE2E`, currently isolated from default bootstrap.
- Candidate `shell`: `Maaack's Game Template`, currently isolated from default bootstrap.

The current toolbox already covers engineering quality, testing, validation, debug visibility, state chart authoring, feedback authoring, E2E PoC, and app shell candidate research. It does not yet provide reusable gameplay architecture packs.

## Findings

| Candidate | Area | License / status | Absorption decision | Reason |
| --- | --- | --- | --- | --- |
| `Maaack/Godot-Game-Template` | App shell, menus, options, pause, loading, credits | MIT, already vendored as candidate `shell` | Keep as candidate reference, do not default-enable | It covers shell features well but carries template-level assumptions about scenes, autoloads, saving, and state. |
| `RandallLiuXin/godot-e2e` | Out-of-process E2E | Already vendored as candidate `automation` | Promote only after pack contract exists | It is valuable for flow-level tests, but needs controlled autoload/project setting injection. |
| `godotneers/G.U.I.D.E` | Unified input | MIT, Godot Asset Library 0.12.0 | Landed non-default `input` pack | Strong reusable input abstraction across keyboard, mouse, gamepad, and touch. Keep optional. |
| `nathanhoad/godot_dialogue_manager` | Dialogue | Godot 4.6+ addon; v4 warns it is not officially released yet | Candidate `dialogue` pack, defer promotion | Good stateless branching dialogue model, but version and release maturity should be watched. |
| `shomykohai/quest-system` | Quests | MIT, Godot 4.4+ | Candidate `quest` pack or reference implementation | Resource-based quests, serialization/deserialization, localization, and GDUnit4 tests align with toolbox goals. |
| `peter-kish/gloot` | Inventory | MIT, Godot 4.4+ | Candidate `inventory` pack, not base | Strong focused inventory system; too domain-specific for base. |
| `bitbrain/pandora` | RPG data management | MIT, alpha / not production-ready | Reference only for `data` pack design | Useful data-management ideas, but alpha status and RPG scope make direct absorption risky. |
| `youssof20/savestate` | Save system | MIT Lite, new project | Reference or candidate `save` PoC | Atomic writes, backups, schema migration, and slots are exactly the right concerns, but maturity is low. |
| GDQuest resource save guide/demo | Save pattern | Code MIT, assets CC BY 4.0 | Reference pattern, not vendor | Resource-based save approach is a strong pattern, but toolbox should own its save facade. |
| Godot official save docs | Save pattern | Official docs | Reference baseline | Confirms complexity around arbitrary objects, nested persist objects, JSON limits, and binary serialization. |
| `AlexRmCreative/MEF` | Event framework | MIT, Asset Library 0.1.0 | Reference only for `rules-events` | Good execution-group/conditions/effects model, but too early to vendor. |
| `glass-brick/Scene-Manager` | Scene transitions | MIT, latest release observed 2026-04-18 | Reference, maybe compare against shell/flow | Useful transition plugin, but `godot-toolbox` should own game mode and flow result contracts. |
| `bitbrain/beehave` | Behavior tree AI | MIT, Godot 4.x | Candidate AI reference, optional | GDScript behavior tree option; useful for AI-heavy projects but not a generic architecture base. |
| `limbonaut/limboai` | Behavior trees + HSM | MIT source, CC BY assets, GDExtension/C++ | External reference, not default pack | Powerful and mature, but native extension surface and asset licensing make it a poor default baseline. |

## Source Notes

- `Maaack/Godot-Game-Template`: main menu, options, pause, credits, loading, persistent settings, simple config, scene loading, level progress, win/lose, state management; MIT. Source: <https://github.com/Maaack/Godot-Game-Template>
- `Pandora`: manages RPG data such as items, inventories, spells, mobs, quests, and NPCs; explicitly marked alpha / not production-ready; MIT. Source: <https://github.com/bitbrain/pandora>
- `QuestSystem`: Godot 4.4+ resource-based quests, custom quests, CSV/POT localization, serialization/deserialization, GDUnit4 tests; MIT. Source: <https://github.com/shomykohai/quest-system>
- `Dialogue Manager`: Godot 4.6+ stateless branching dialogue editor/runtime; v4 page warns to use v3 until v4 is officially released. Source: <https://github.com/nathanhoad/godot_dialogue_manager>
- `GLoot`: universal inventory system for Godot 4.4+; MIT. Source: <https://github.com/peter-kish/gloot>
- `LimboAI`: behavior trees and hierarchical state machines; MIT code, CC BY logo/demo art, GDExtension/module distribution. Source: <https://github.com/limbonaut/limboai>
- `MEF`: modular event framework with execution groups, priority ordering, async effects, cancellation, shared context; MIT; early 0.1.0. Source: <https://godotengine.org/asset-library/asset/4798>
- `G.U.I.D.E`: unified input detection and handling for keyboard, mouse, gamepad, touch; MIT. Source: <https://github.com/godotneers/G.U.I.D.E>
- GDQuest save guide: resource-based save data using `ResourceSaver`/`ResourceLoader`, migration caveats, binary vs text tradeoffs; code MIT, assets CC BY 4.0. Source: <https://www.gdquest.com/library/save_game_godot4/>
- Godot save docs: save complexity grows across levels and objects; official examples mark persistent objects, serialize dictionaries, warn about nested persistent object path issues and JSON limits. Source: <https://docs.godotengine.org/en/4.0/tutorials/io/saving_games.html>
- Godot resources docs: nodes provide behavior, resources are data containers, and saved/loaded engine assets are resources. Source: <https://docs.godotengine.org/en/stable/tutorials/scripting/resources.html>
- `SaveState Lite`: atomic save files, backups, schema versioning, slots, MIT; new and low star count but focused on correct save-system failure modes. Source: <https://github.com/youssof20/savestate>
- `Scene Manager`: scene transition and node-reference plugin; MIT. Source: <https://github.com/glass-brick/Scene-Manager>
- `Beehave`: behavior tree AI addon, debug view, performance monitors, test automation, MIT. Source: <https://github.com/bitbrain/beehave>

## Main Conclusion

The ecosystem already has good specialized addons. The missing piece for `godot-toolbox` is not more feature collection. It is a reusable architecture layer that decides how these addons plug into stable game-flow, simulation, data, save, and verification contracts.

Direct vendoring should be conservative. The first toolbox-owned work should define pack contracts, flow contracts, simulation boundaries, data registries, save contracts, and flow-level test fixtures. After that, specialized addons can be optional packs.
