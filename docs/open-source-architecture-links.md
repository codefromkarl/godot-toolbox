# Open Source Architecture Links

This document is the repository-facing link map for the game architecture scan.

The links are also mirrored in `packs.manifest.json` under `open_source_references` and in `upstreams.lock.json` as `plugin`, `reference`, `candidate-reference`, or `external-reference` entries. They are intentionally not enabled by default unless the toolbox owns the relevant truth boundary.

## Absorbed Optional Packs

| Direction | Upstream | Link | Current repository action |
| --- | --- | --- | --- |
| `input` | G.U.I.D.E | <https://github.com/godotneers/G.U.I.D.E> | Landed as non-default `input` pack; explicit opt-in only. |
| `quest` | QuestSystem | <https://github.com/shomykohai/quest-system> | Landed as non-default `quest` pack; requires adapters before owning project quest state. |
| `inventory` | GLoot | <https://github.com/peter-kish/gloot> | Landed as non-default `inventory` pack; RPG item/equipment truth stays project-owned. |
| `ai` | Beehave | <https://github.com/bitbrain/beehave> | Landed as non-default `ai-behavior` pack; optional for complex behavior authoring. |
| `save` | SaveState Lite | <https://github.com/youssof20/savestate> | Landed as non-default `save-state-lite` pack; isolated from `save-core` due to `SaveSlot` class conflict. |
| `dialogue` | Dialogue Manager | <https://github.com/nathanhoad/godot_dialogue_manager> | Landed as non-default `dialogue` pack; requires adapters before owning project dialogue state. |

Specialized gameplay packs remain non-default. Promotion to default is not allowed unless the toolbox owns the corresponding data, save, event, and verification contract.

## Art And Audio Asset Sources

RPG demo art/audio candidates are tracked separately in `docs/rpg-art-asset-sources.md`. They are source links only until a concrete optional asset pack is imported with license/NOTICE records.

## Candidate Optional Packs

| Direction | Upstream | Link | Current repository action |
| --- | --- | --- | --- |
| `dialogue` | Dialogic | <https://github.com/dialogic-godot/dialogic> | Reference candidate for heavier dialogue/VN workflows. |

Dialogic candidate governance is tracked in `docs/dialogue-pack-candidate-plan.md`; these links remain reference/candidate only and do not grant campaign truth, save schema, event truth, vendoring, or default bootstrap authority.

## Reference-Only Inputs

| Direction | Upstream | Link | Current repository action |
| --- | --- | --- | --- |
| `data-core` | Pandora | <https://github.com/bitbrain/pandora> | Taxonomy reference only; current implementation is a small registry scaffold. |
| `save-core` | GDQuest save pattern | <https://www.gdquest.com/library/save_game_godot4/> | Resource-save pattern reference only. |
| `save-core` | Godot save docs | <https://docs.godotengine.org/en/4.0/tutorials/io/saving_games.html> | Official caution baseline for arbitrary object persistence. |
| `flow-core` | Scene Manager | <https://github.com/glass-brick/Scene-Manager> | Transition reference only; `flow-core` owns flow result semantics. |
| `rules-events-core` | MEF | <https://godotengine.org/asset-library/asset/4798> | Execution group / condition / effect reference. |
| `ai` | LimboAI | <https://github.com/limbonaut/limboai> | External reference by default due to native extension surface. |

## Small Integration Now

The current small functional integration is toolbox-owned rather than direct vendoring:

- `flow-core` provides the project-owned flow truth that scene/menu/dialogue addons can call into.
- `simulation-core` provides explicit tick/time-scale boundaries.
- `data-core` provides stable IDs and a registry scaffold for future quest/dialogue/inventory integration.
- `save-core` provides versioned snapshots and atomic JSON writes.
- `flow-test-kit` provides a runner-agnostic smoke fixture for mode/result payload checks.
- `rules-events-core` provides event/condition/effect execution boundaries for future quest, dialogue, inventory, and simulation hooks.
- `ui-game-shell` provides app-shell primitives without adopting the candidate Maaack template as runtime truth.
- `inventory`, `quest`, `ai-behavior`, `save-state-lite`, and `dialogue` provide opt-in third-party addon surfaces, while RPG combat/character/save adapters remain self-owned.
