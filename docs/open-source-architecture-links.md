# Open Source Architecture Links

This document is the repository-facing link map for the game architecture scan.

The links are also mirrored in `packs.manifest.json` under `open_source_references` and in `upstreams.lock.json` as `reference`, `candidate-reference`, or `external-reference` entries. They are intentionally not vendored unless a pack has an explicit bootstrap contract, version lock, and verification path.

## Candidate Optional Packs

| Direction | Upstream | Link | Current repository action |
| --- | --- | --- | --- |
| `input` | G.U.I.D.E | <https://github.com/godotneers/G.U.I.D.E> | Candidate link only; wait for declarative input/project-setting injection. |
| `quest` | QuestSystem | <https://github.com/shomykohai/quest-system> | Candidate/reference; evaluate against `data-core` and `save-core`. |
| `dialogue` | Dialogue Manager | <https://github.com/nathanhoad/godot_dialogue_manager> | Deferred candidate; watch Godot 4.6+ v4 maturity. |
| `inventory` | GLoot | <https://github.com/peter-kish/gloot> | Candidate optional pack, never baseline. |
| `ai` | Beehave | <https://github.com/bitbrain/beehave> | Optional reference for a future `ai-behavior` pack. |

## Reference-Only Inputs

| Direction | Upstream | Link | Current repository action |
| --- | --- | --- | --- |
| `data-core` | Pandora | <https://github.com/bitbrain/pandora> | Taxonomy reference only; current implementation is a small registry scaffold. |
| `save-core` | SaveState Lite | <https://github.com/youssof20/savestate> | Atomic slot and migration reference only. |
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

