# RPG Template Absorption Plan

## Purpose

This document records which RPG-related open-source capabilities are now absorbed into `godot-toolbox`, which remain references, and which RPG template systems should be self-owned.

The target is not to turn `godot-toolbox` into one fixed RPG framework. The target is to make it a better Godot template repository for RPG projects while preserving clear truth boundaries around combat, character progression, save format, data IDs, and verification.

## Absorbed Optional Packs

| Pack | Source | Version | Why absorbed | Boundary |
| --- | --- | --- | --- | --- |
| `inventory` | [GLoot](https://github.com/peter-kish/gloot) | `v3.0.1` | Mature inventory/item/equipment addon with a clear `addons/gloot` subtree. | RPG item definitions, equipment rules, loot rewards, and save adapters remain project-owned. |
| `quest` | [QuestSystem](https://github.com/shomykohai/quest-system) | `2.0.1.4_4` | Resource-based quest system with a clear addon subtree and tests upstream. | Campaign truth, quest event mapping, and quest persistence must bridge through `rules-events-core` and `save-core`. |
| `ai-behavior` | [Beehave](https://github.com/bitbrain/beehave) | `v2.9.2` | Mature behavior-tree addon for projects needing explicit AI authoring. | Basic turn-based enemy AI should start self-owned; behavior trees are optional once behavior complexity justifies them. |
| `save-state-lite` | [SaveState Lite](https://github.com/youssof20/savestate) | `v1.2.0` | Useful SaveManager, atomic writer, save browser, and component patterns. | It is an isolated alternative save tooling pack because it defines `SaveSlot`, which conflicts with `save-core`; `save-core` remains the default RPG persistence contract. |

All absorbed packs are non-default. They only enter a generated project through explicit `--packs=...` selection.

## Source Details

| ID | Upstream repository | Upstream version/ref | Upstream subtree | Local path | Local pack | Current status |
| --- | --- | --- | --- | --- | --- | --- |
| `gloot` | <https://github.com/peter-kish/gloot> | `v3.0.1` | `addons/gloot` | `packs/inventory/godot/addons/gloot` | `inventory` | Vendored optional pack, explicit opt-in. |
| `quest_system` | <https://github.com/shomykohai/quest-system> | `2.0.1.4_4` | `addons/quest_system` | `packs/quest/godot/addons/quest_system` | `quest` | Vendored optional pack, explicit opt-in. |
| `beehave` | <https://github.com/bitbrain/beehave> | `v2.9.2` | `addons/beehave` | `packs/ai-behavior/godot/addons/beehave` | `ai-behavior` | Vendored optional pack, explicit opt-in. |
| `savestate_lite` | <https://github.com/youssof20/savestate> | `v1.2.0` | `addons/savestate` | `packs/save-state-lite/godot/addons/savestate` | `save-state-lite` | Vendored optional pack, explicit opt-in, conflicts with `save-core`. |
| `pandora` | <https://github.com/bitbrain/pandora> | Reference only | Not vendored | `packs/data-core` references only | none | Reference for RPG data taxonomy; no runtime dependency. |
| `dialogue_manager` | <https://github.com/nathanhoad/godot_dialogue_manager> | Reference only | Not vendored | future `packs/dialogue` candidate | none | Deferred dialogue candidate. |
| `dialogic` | <https://github.com/dialogic-godot/dialogic> | Reference only | Not vendored | future dialogue/VN candidate | none | Reference for heavier dialogue/VN workflows. |
| `gdquest_open_rpg` | <https://github.com/gdquest-demos/godot-open-rpg> | Reference only | Not vendored | design reference only | none | Reference for simple RPG scene/data/combat organization. |
| `gdquest_save_guide` | <https://www.gdquest.com/library/save_game_godot4/> | Reference only | Not vendored | `save-core` references only | none | Reference for save resource patterns. |
| `godot_save_docs` | <https://docs.godotengine.org/en/4.0/tutorials/io/saving_games.html> | Reference only | Not vendored | `save-core` references only | none | Reference for persistence cautions and object boundaries. |
| `scene_manager` | <https://github.com/glass-brick/Scene-Manager> | Reference only | Not vendored | `flow-core` references only | none | Reference for scene transitions; `flow-core` owns result semantics. |
| `limboai` | <https://github.com/limbonaut/limboai> | External reference only | Not vendored | future AI candidate only | none | Kept external due to native-extension/GDExtension maintenance surface. |

## Reference-Only Sources

| Direction | Source | Why reference-only |
| --- | --- | --- |
| RPG data taxonomy | [Pandora](https://github.com/bitbrain/pandora) | Useful data-management ideas, but too RPG-scoped and not the generic `data-core` truth. |
| Dialogue | [Dialogue Manager](https://github.com/nathanhoad/godot_dialogue_manager) | Strong candidate, but should remain deferred until the target Godot version and release maturity are acceptable for this template. |
| Dialogue/VN | [Dialogic](https://github.com/dialogic-godot/dialogic) | Powerful but heavier than the current RPG battle template goal; keep as a future dialogue/VN candidate. |
| Save design | [GDQuest save guide](https://www.gdquest.com/library/save_game_godot4/) and [Godot save docs](https://docs.godotengine.org/en/4.0/tutorials/io/saving_games.html) | Good persistence cautions and patterns, but `save-core` should own the minimal facade. |
| Flow transitions | [Scene Manager](https://github.com/glass-brick/Scene-Manager) | Good transition reference, but `flow-core` owns game mode/result semantics. |
| Advanced AI | [LimboAI](https://github.com/limbonaut/limboai) | Powerful, but native-extension/GDExtension surface is too heavy for a default template dependency. |
| Turn-based RPG example | [GDQuest Open RPG](https://github.com/gdquest-demos/godot-open-rpg) | Valuable learning/demo source, but not a reusable framework to vendor as template truth. |

## Self-Owned RPG Work

### `rpg-core`

Own the RPG state and data contracts that every RPG project needs:

- `StatBlock`
- `LevelCurve`
- `CharacterData`
- `CharacterState`
- `PartyState`
- `Wallet`
- `ItemRef`
- `EquipmentSlot`
- `EquipmentLoadout`

External influence:

- GLoot can inform inventory/equipment shapes.
- Pandora can inform RPG content taxonomy.
- GDQuest Open RPG can inform scene/data organization.

### `rpg-battle-core`

Own the deterministic turn-based combat contract:

- `BattleSession`
- `CombatantState`
- `TurnQueue`
- `BattleAction`
- `SkillAction`
- `ItemAction`
- `TargetRule`
- `DamageFormula`
- `BattleResult`
- `RewardGrant`

External influence:

- GDQuest Open RPG can inform simple RPG combat layout.
- Beehave can remain optional for complex AI, but first-party battle AI should start as deterministic policy code.

### `rpg-save-adapter`

Own the mapping from RPG state to `save-core` snapshots:

- party roster
- current HP/MP/status
- experience and level
- wallet/gold
- inventory stacks
- equipment loadouts
- unlocked skills
- completed battle rewards

External influence:

- SaveState Lite can inform atomic writes, save browser UX, and saveable component ideas, but it cannot be enabled beside `save-core` until one side is namespaced or adapted.
- Godot/GDQuest save guidance should inform migration and persistent object boundaries.

### `rpg-test-kit`

Own evidence that the template is actually usable:

- fixed battle smoke
- skill damage/heal tests
- equipment stat contribution test
- level-up and reward test
- inventory use test
- save/load roundtrip test
- deterministic replay fixture for one battle

## Completion Bar

The repository can claim `RPG-ready shell` when:

- `inventory`, `quest`, `ai-behavior`, and isolated `save-state-lite` bootstrap as opt-in packs.
- `rpg-core` and `rpg-battle-core` have runnable smoke tests.
- A generated project can run one complete battle, grant rewards, save, reload, and preserve party state.

The repository should not claim `complete RPG template` until it also has battle UI scenes, example content, item/equipment UI, and at least one playable end-to-end sample flow.

## Follow-Up Task Backlog

### Integration Hardening

| Task ID | Task | Output | Acceptance evidence |
| --- | --- | --- | --- |
| RPG-I01 | Add pack-specific dry-run examples for `inventory`, `quest`, `ai-behavior`, and `save-state-lite` to README or maintenance docs. | Documented commands and expected pack dependencies. | `pack_manifest.py report` examples match current manifest. |
| RPG-I02 | Add explicit conflict test for `save-state-lite,save-core`. | Verification assertion in `verify_specialized_pack_candidates.sh` or dedicated script. | Command fails with a clear conflict message. |
| RPG-I03 | Add source-license/NOTICE summary for each newly vendored pack. | License section in pack README or central license inventory. | Each vendored pack has source, license, version, and local path recorded. |
| RPG-I04 | Decide whether the SaveState Lite `ResourceUID` patch should be upstreamed or maintained locally. | Patch policy note in `upstreams.lock.json` and pack README. | Re-import/update procedure documents patch preservation. |
| RPG-I05 | Add import smoke rows for all new pack combinations to CI if runtime cost is acceptable. | CI matrix entries or documented local-only decision. | `verify_pack_matrix.sh --all` covers new rows without unexpected errors. |

### RPG Core

| Task ID | Task | Output | Acceptance evidence |
| --- | --- | --- | --- |
| RPG-C01 | Create `packs/rpg-core` manifest entry and folder scaffold. | Non-default `rpg-core` pack requiring `data-core` and `save-core`. | Manifest validates and bootstrap overlays the pack. |
| RPG-C02 | Implement `StatBlock` and stat modifier model. | Typed resources/classes for base stats, derived stats, additive/multiplicative modifiers. | Unit tests prove deterministic stat calculation. |
| RPG-C03 | Implement `LevelCurve`. | Resource/class for level thresholds and reward application. | Tests cover level-up, multi-level gain, and max-level boundary. |
| RPG-C04 | Implement `CharacterData` and `CharacterState`. | Static character definition plus runtime mutable state. | Tests prove data is not mutated when runtime state changes. |
| RPG-C05 | Implement `PartyState` and `Wallet`. | Party roster, active members, reserve members, gold/currency state. | Tests cover add/remove member and currency mutation constraints. |
| RPG-C06 | Implement item/equipment reference contracts. | `ItemRef`, `EquipmentSlot`, `EquipmentLoadout` independent of GLoot internals. | Tests cover stable IDs and equipment slot compatibility. |
| RPG-C07 | Add GLoot adapter design. | Adapter that maps project-owned item/equipment state to GLoot objects when `inventory` is enabled. | Adapter tests run with `inventory,data-core,save-core,rpg-core`. |

### RPG Battle Core

| Task ID | Task | Output | Acceptance evidence |
| --- | --- | --- | --- |
| RPG-B01 | Create `packs/rpg-battle-core` manifest entry and scaffold. | Non-default battle pack requiring `rpg-core`, `flow-core`, and `rules-events-core`. | Manifest validates and bootstrap overlays the pack. |
| RPG-B02 | Implement `CombatantState`. | Runtime combatant projection from character/enemy data. | Tests cover HP/MP/status initialization and death checks. |
| RPG-B03 | Implement `BattleSession`. | Session state for party, enemies, turn phase, log, outcome. | Fixed smoke battle reaches victory deterministically. |
| RPG-B04 | Implement `TurnQueue`. | Deterministic order calculation with speed/priority hooks. | Tests cover tie-breaking and repeatability. |
| RPG-B05 | Implement `BattleAction`, `SkillAction`, and `ItemAction`. | Action contracts independent of UI. | Tests cover valid/invalid action selection and cost checks. |
| RPG-B06 | Implement `TargetRule`. | Single target, all enemies, all allies, self, random target. | Tests cover target legality. |
| RPG-B07 | Implement `DamageFormula`. | First-pass physical/magical damage and healing formulas. | Tests cover damage, defense, healing, min/max clamp. |
| RPG-B08 | Implement `BattleResult` and `RewardGrant`. | Outcome, experience, gold, item rewards. | Tests cover reward application to `PartyState`. |
| RPG-B09 | Add simple enemy AI policy. | Deterministic non-Beehave AI for first-pass turn-based combat. | Replay test produces the same action sequence. |
| RPG-B10 | Add optional Beehave adapter design. | Adapter boundary for behavior-tree enemy selection when `ai-behavior` is enabled. | Adapter remains optional and battle smoke works without Beehave. |

### RPG Save Adapter

| Task ID | Task | Output | Acceptance evidence |
| --- | --- | --- | --- |
| RPG-S01 | Create `rpg-save-adapter` module or subpack. | Serializer/deserializer from RPG state to `save-core` snapshot payload. | Roundtrip test preserves party, gold, levels, inventory refs, equipment refs. |
| RPG-S02 | Define RPG save schema version. | Versioned dictionary shape and migration stub. | Tests reject malformed payloads and migrate old versions. |
| RPG-S03 | Add inventory/equipment save adapter. | Project-owned stable item/equipment refs, optionally bridgeable to GLoot. | Roundtrip test does not require GLoot runtime unless adapter is selected. |
| RPG-S04 | Add quest state save adapter. | Quest progress mapping through `rules-events-core` and `save-core`. | Quest state roundtrip test with `quest` pack selected. |

### RPG UI And Example Content

| Task ID | Task | Output | Acceptance evidence |
| --- | --- | --- | --- |
| RPG-U01 | Create minimal battle scene. | `BattleRoot` scene with party/enemy panels and command area. | Headless scene import and UI tree smoke. |
| RPG-U02 | Create battle HUD scripts. | HP/MP bars, turn indicator, battle log. | Smoke verifies visible controls and state text update. |
| RPG-U03 | Create skill menu. | Skill list, disabled state for insufficient MP, target prompt. | UI test covers selecting one skill. |
| RPG-U04 | Create item menu. | Consumable item list and use action. | UI test covers item consumption and HP change. |
| RPG-U05 | Create equipment/party management UI. | Minimal menu for loadout and active party. | UI smoke proves equipment changes stat output. |
| RPG-U06 | Add example content. | At least two heroes, three enemies, five skills, five items, three equipment pieces. | Fixed battle smoke uses real example data. |

### RPG Test And Observability

| Task ID | Task | Output | Acceptance evidence |
| --- | --- | --- | --- |
| RPG-T01 | Add `rpg-test-kit`. | Test fixtures for RPG core, battle, save, and UI smoke. | Pack-local verification script passes. |
| RPG-T02 | Add deterministic battle replay. | Input/action trace plus expected event log. | Replay produces identical result across runs. |
| RPG-T03 | Add combat event stream. | Events for action selected, damage, heal, KO, reward, save. | Tests assert event order and payload shape. |
| RPG-T04 | Add state dump for AI/manual verification. | JSON dump of battle state, party state, inventory, save payload. | E2E/manual audit can inspect state without debugger. |
| RPG-T05 | Add acceptance matrix for `RPG-ready shell` and `complete RPG template`. | Documented evidence requirements and allowed completion language. | Claims in README match available evidence layer. |

### Documentation And Governance

| Task ID | Task | Output | Acceptance evidence |
| --- | --- | --- | --- |
| RPG-D01 | Add RPG template README section. | User-facing explanation of what is available now and what remains self-owned. | README links to this plan and pack docs. |
| RPG-D02 | Add RPG pack selection recipes. | Recipes for minimal RPG battle, RPG with inventory, RPG with quest, RPG with behavior AI. | `bootstrap_toolbox_project.sh --dry-run-report` commands in docs work. |
| RPG-D03 | Add source boundary docs for every adapter. | Explanation of third-party API boundary vs project-owned truth. | Each adapter has source, state ownership, and save ownership notes. |
| RPG-D04 | Add upgrade checklist for vendored RPG packs. | Steps for updating GLoot, QuestSystem, Beehave, SaveState Lite. | `update_plugin_from_upstream.sh --id=... --dry-run` examples are documented. |
