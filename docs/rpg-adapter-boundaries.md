# RPG Adapter Boundaries

This document records source boundary, state ownership, and save ownership for every RPG adapter surface.

## GLoot

- source boundary: GLoot is available through the optional `inventory` pack for inventory/equipment authoring and runtime primitives.
- state ownership: `rpg-core` owns stable `ItemRef`, `EquipmentSlot`, and `EquipmentLoadout` contracts.
- save ownership: `rpg-save-adapter` serializes stable item/equipment refs to dictionaries before they enter `save-core`.
- adapter rule: GLoot objects may be generated from first-party refs, but GLoot internals must not become durable RPG truth.

## QuestSystem

- source boundary: QuestSystem is available through the optional `quest` pack for quest resources and authoring.
- state ownership: campaign truth, quest IDs, objective progress, and event mapping remain project-owned.
- save ownership: `rpg-save-adapter` persists quest progress dictionaries through `save-core`.
- adapter rule: QuestSystem state must cross the `rules-events-core` boundary before becoming gameplay truth.

## Beehave

- source boundary: Beehave is available through the optional `ai-behavior` pack for authored behavior trees.
- state ownership: `rpg-battle-core` owns deterministic first-pass enemy AI and battle action selection.
- save ownership: enemy AI runtime decisions are replay/event-stream evidence, not durable save truth by default.
- adapter rule: `RPGBeehaveAIAdapter` remains optional; battle smoke must pass without Beehave.

## SaveState Lite

- source boundary: SaveState Lite is available through the optional `save-state-lite` pack as an alternative save tooling/reference surface.
- state ownership: default RPG durable state remains explicit first-party dictionaries.
- save ownership: default RPG saves use `rpg-save-adapter` and `save-core`.
- adapter rule: `save-state-lite` conflicts with `save-core` because both expose a global `SaveSlot`; do not enable both in one generated project without a future namespacing/adaptation decision.

## save-core Mapping

- source boundary: `save-core` is toolbox-owned and provides versioned snapshot and slot primitives.
- state ownership: RPG runtime objects stay in `rpg-core` and `rpg-battle-core`.
- save ownership: `rpg-save-adapter` owns RPG schema version, migration stub, and payload dictionaries.
- adapter rule: no live scene tree object or third-party plugin object should be saved directly.
