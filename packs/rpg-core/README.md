# rpg-core

> Toolbox-owned RPG state and data contracts.

| Field | Value |
|-------|-------|
| Kind | `architecture-core` |
| Default | `false` |
| Requires | `base`, `data-core`, `save-core` |
| Conflicts | — |

## Quick Start

```bash
./scripts/bootstrap_toolbox_project.sh /path/to/project --packs=rpg-core
```

Preview without writing:
```bash
./scripts/bootstrap_toolbox_project.sh /path/to/project --packs=rpg-core --dry-run-report
```

Note: `rpg-core` requires `data-core` and `save-core`, which are automatically resolved.

## What It Provides

- `RPGCore` autoload singleton
- `StatBlock` / `StatModifier` — character attribute system with additive/multiplicative modifiers
- `LevelCurve` — configurable leveling progression
- `CharacterData` / `CharacterState` — character definition and runtime state
- `PartyState` — party member management
- `Wallet` — currency tracking across multiple currency types
- `ItemRef` — stable item reference using `data-core` IDs
- `EquipmentSlot` / `EquipmentLoadout` — equipment management with slot constraints
- `RPGGLootAdapter` — optional adapter mapping `ItemRef` to GLoot dictionary payloads

## When to Enable

- Projects building RPG-style character progression, party management, or equipment systems
- Games that need first-party RPG state truth independent of third-party inventory/quest plugins
- Any project using `rpg-battle-core`, `rpg-save-adapter`, or `rpg-test-kit` (they depend on this pack)

## Verification

```bash
bash ./scripts/verify_rpg_core_pack.sh
```

## Contract Details

This pack defines the first-party boundary for RPG character, party, currency, item reference, and equipment state. It is intentionally independent of GLoot, QuestSystem, Beehave, and SaveState Lite so RPG truth can remain project-owned and serializable through `data-core` and `save-core`.

- `RPGCore.pack_id()` — returns `rpg-core`
- `RPGCore.required_contracts()` — declares `data-core` and `save-core` as the persistence/data boundary
- `StatBlock` — base stats with `StatModifier` stacking (additive, multiplicative, override)
- `LevelCurve` — XP-to-level mapping via configurable curve resource
- `CharacterData` — immutable character definition (base stats, growth curve, abilities)
- `CharacterState` — mutable runtime state (current HP/MP, level, buffs, equipment)
- `PartyState` — ordered party member list with active/reserve slots
- `Wallet` — multi-currency balance tracking (gold, gems, etc.)
- `ItemRef` — stable item reference using `data-core` `GameId` system
- `EquipmentLoadout` — slot-to-`ItemRef` mapping with slot type validation

### Third-Party Adapter

`RPGGLootAdapter` maps first-party `ItemRef` data to dictionary payloads that can be bridged to GLoot when the `inventory` pack is selected. This adapter does **not** make GLoot a default dependency.

## Upstream

Toolbox-owned. No vendored dependencies.
