# RPG Art Asset Sources

This document records the current RPG art/audio asset gap and a curated list of external CC0/open-source candidate sources. These sources are not vendored by default. If any asset is imported later, add the exact downloaded version, source URL, license text, attribution requirements, and local target to the relevant NOTICE document.

## Current Repository Assets

The current repository has RPG functionality, example data, UI scenes, plugin icons, controller/input prompts, logos, and theme resources. It does not yet vendor a complete RPG art/audio library.

`packs/rpg-art-demo` is an optional, non-default first-party placeholder pack for validating the future RPG art/audio import policy. It currently contains text placeholders and NOTICE/import-policy documentation only; it must not define canonical RPG stats, item IDs, save schemas, battle rules, or other gameplay truth.

RPG example content governance is defined in `docs/rpg-content-authoring.md`; art packs may reference stable content IDs, but they must not define canonical RPG stats, item IDs, save schemas, or battle rules.

Current useful assets:

| Area | Current source | License status | Notes |
| --- | --- | --- | --- |
| RPG functionality | `GLoot`, `QuestSystem`, `Beehave`, `SaveState Lite` | MIT; see `docs/rpg-vendor-license-notice.md` | Functional addons, not art/audio asset packs. |
| Input prompts | `packs/shell/godot/addons/maaacks_game_template/assets/input-icons` | CC0 via Kenney Input Prompts | Useful for controls/help overlays. |
| Remapping icons | `packs/shell/godot/addons/maaacks_game_template/base/assets/remapping_input_icons` | CC0 via Marek Belski license file | Useful for settings/input remapping UI. |
| Plugin/control/theme images | `packs/input`, `packs/shell`, `packs/ai-behavior`, `packs/stateful`, `packs/validation` | Mixed upstream addon assets | Keep scoped to plugin/editor/support UI unless separately audited. |
| RPG example content | `packs/rpg-core/godot/content/rpg_example/rpg_example_content.json` | First-party data | Gameplay data only; no character sprites, enemy art, backgrounds, BGM, SFX, or fonts. |

## Recommended 2D Pixel RPG Starter Set

| Missing category | Candidate source | License | Why it fits |
| --- | --- | --- | --- |
| Tiles, town props, furniture, simple RPG sprites | [Kenney Roguelike/RPG Pack](https://kenney.nl/assets/roguelike-rpg-pack) | CC0 | 16x16 pixel pack with RPG/town/tile/furniture coverage; good for a lightweight 2D demo. |
| Dungeon tiles, player/enemy sprites, props | [0x72 16x16 DungeonTileset II](https://0x72.itch.io/dungeontileset-ii) | CC0 for assets; MIT for code metadata on itch | Good compact dungeon baseline with monsters, hazards, props, and autotile-oriented updates. |
| RPG UI skin | [Kenney UI Pack RPG Expansion](https://kenney.nl/assets/ui-pack-rpg-expansion) | CC0 | Buttons, panels, sliders, and RPG interface elements. |
| Item/equipment/skill icons | [OpenGameArt RPG Icons](https://opengameart.org/content/rpg-icons-3) | CC0 | 64x64 and 128x128 fantasy RPG icons. |
| Pixel item icons | [OpenGameArt 16x16 Assorted RPG Icons](https://opengameart.org/content/16x16-assorted-rpg-icons) | CC0 | Smaller inventory/item icons that match 16x16 pixel-art projects. |
| Broad SVG icons | [Game-icons.net](https://game-icons.net/) | Mostly CC BY, some public domain | Large catalog for skills/status/equipment; attribution is required for CC BY icons. |
| Battle backgrounds | [OpenGameArt Backgrounds](https://opengameart.org/content/backgrounds-3) | CC0 | Static RPG battleback-style backgrounds. |
| RPG SFX | [Kenney RPG Audio](https://kenney.nl/assets/rpg-audio) | CC0 | Footsteps, weapons, and RPG foley. |
| UI SFX | [Kenney Interface Sounds](https://kenney.nl/assets/interface-sounds) | CC0 | Click/button sounds for menu and battle UI. |
| Town/BGM music | [OpenGameArt Town Theme RPG](https://opengameart.org/content/town-theme-rpg) | CC0 | Useful town/peaceful RPG BGM. |
| Battle BGM | [OpenGameArt Battle Theme](https://opengameart.org/content/battle-theme-0) | CC0 | Useful battle or tense-moment BGM. |
| Broader fantasy BGM/SFX scan | [OpenGameArt CC0 Fantasy Music & Sounds](https://opengameart.org/content/cc0-fantasy-music-sounds) | Collection claims CC0, verify each collected asset | Good discovery collection, but each linked asset must be checked before vendoring. |
| Pixel fonts | [Kenney Fonts](https://kenney.nl/assets/kenney-fonts) | CC0 | Simple pixel/game fonts for prototype UI and HUD text. |

Recommended 2D demo shortlist:

1. Use Kenney Roguelike/RPG Pack plus 0x72 DungeonTileset II for the visual world and combatants.
2. Use Kenney UI Pack RPG Expansion, Kenney Fonts, and the existing Kenney Input Prompts for UI consistency.
3. Use OpenGameArt RPG Icons or 16x16 Assorted RPG Icons for item/skill/equipment coverage.
4. Use Kenney RPG Audio, Kenney Interface Sounds, Town Theme RPG, and Battle Theme for the first audio pass.
5. Use OpenGameArt Backgrounds only if the battle scene stays static/side-view rather than tilemap-driven.

## Recommended 3D Low-Poly RPG Starter Set

| Missing category | Candidate source | License | Why it fits |
| --- | --- | --- | --- |
| Player characters | [KayKit Character Pack: Adventurers](https://kaylousberg.itch.io/kaykit-adventurers) | CC0 | Rigged/animated low-poly adventurers with weapons/accessories and Godot-compatible formats. |
| Skeleton enemies | [KayKit Character Pack: Skeletons](https://kaylousberg.itch.io/kaykit-skeletons) | CC0 | Rigged/animated skeleton enemies with weapons/accessories. |
| Dungeon scenes/props | [KayKit Dungeon Pack Remastered](https://kaylousberg.itch.io/kaykit-dungeon-remastered) | CC0 | Modular dungeon walls, floors, stairs, doors, chests, barrels, traps, furniture, and props. |
| Broader RPG props/models | [Quaternius Ultimate RPG Pack](https://quaternius.com/packs/ultimaterpg.html) | CC0 | Large low-poly 3D RPG model pack with animated/textured assets and source formats. |

Recommended 3D demo shortlist:

1. Use KayKit Adventurers, Skeletons, and Dungeon Pack Remastered as the coherent core style.
2. Add Quaternius Ultimate RPG Pack only when extra props/models are needed and visual style differences are acceptable.
3. Reuse the same SFX, BGM, icon, and font candidates from the 2D starter set for UI/audio.

## Import Policy

Before any source above becomes a vendored asset pack:

1. Prefer CC0 sources for the first demo to keep NOTICE friction low.
2. If a source is CC BY or mixed-license, record exact attribution text and make credits visible in the generated project.
3. Download from the primary source page, not reposts or mirrors.
4. Record the source URL, author, license, downloaded version/date, local target, and any conversion steps.
5. Keep raw third-party assets in a dedicated optional pack, for example `packs/rpg-art-demo`, not inside `rpg-core` or `rpg-battle-core`.
6. Keep gameplay truth in first-party data and code; art packs must not define canonical RPG stats, item IDs, save schemas, or battle rules.
7. When importing into `packs/rpg-art-demo`, update that pack's `NOTICE.md` before committing binaries or converted Godot import outputs.
