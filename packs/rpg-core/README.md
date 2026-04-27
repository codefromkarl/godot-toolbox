# rpg-core

Toolbox-owned RPG state and data contract scaffold.

This pack defines the first-party boundary for RPG character, party, currency, item reference, and equipment state. It is intentionally independent of GLoot, QuestSystem, Beehave, and SaveState Lite so RPG truth can remain project-owned and serializable through `data-core` and `save-core`.

## Minimal Contract

- `RPGCore.pack_id()` returns `rpg-core`.
- `RPGCore.required_contracts()` declares `data-core` and `save-core` as the persistence/data boundary.
- Future resources in this pack own `StatBlock`, `LevelCurve`, `CharacterData`, `CharacterState`, `PartyState`, `Wallet`, `ItemRef`, `EquipmentSlot`, and `EquipmentLoadout`.

Use this pack as the base RPG domain layer before adding battle, inventory adapters, quest adapters, or UI.
