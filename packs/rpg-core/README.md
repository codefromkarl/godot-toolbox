# rpg-core

Toolbox-owned RPG state and data contracts.

This pack defines the first-party boundary for RPG character, party, currency, item reference, and equipment state. It is intentionally independent of GLoot, QuestSystem, Beehave, and SaveState Lite so RPG truth can remain project-owned and serializable through `data-core` and `save-core`.

## Minimal Contract

- `RPGCore.pack_id()` returns `rpg-core`.
- `RPGCore.required_contracts()` declares `data-core` and `save-core` as the persistence/data boundary.
- This pack owns `StatBlock`, `StatModifier`, `LevelCurve`, `CharacterData`, `CharacterState`, `PartyState`, `Wallet`, `ItemRef`, `EquipmentSlot`, and `EquipmentLoadout`.
- `RPGGLootAdapter` maps first-party `ItemRef` data to dictionary payloads that can be bridged to GLoot when `inventory` is selected, without making GLoot a default dependency.

Use this pack as the base RPG domain layer before adding battle, inventory adapters, quest adapters, or UI.
