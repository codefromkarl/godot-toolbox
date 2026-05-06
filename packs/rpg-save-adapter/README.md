# rpg-save-adapter

> Toolbox-owned adapter from RPG runtime state to save-core snapshots.

| Field | Value |
|-------|-------|
| Kind | `architecture-core` |
| Default | `false` |
| Requires | `base`, `rpg-core`, `save-core`, `rules-events-core` |
| Conflicts | — |

## Quick Start

```bash
./scripts/bootstrap_toolbox_project.sh /path/to/project --packs=rpg-save-adapter
```

Preview without writing:
```bash
./scripts/bootstrap_toolbox_project.sh /path/to/project --packs=rpg-save-adapter --dry-run-report
```

Note: requires `rpg-core`, `save-core`, and `rules-events-core` (auto-resolved with their dependencies).

## What It Provides

- `RPGSaveAdapter` autoload singleton
- RPG save schema versioning
- Party, inventory, equipment, and quest state serialization
- Save schema migration stubs for backward compatibility

## When to Enable

- RPG projects that need durable, structured save data for party and progression state
- Games planning save/load cycles with potential schema evolution
- Any project using `rpg-test-kit` (it depends on this pack for save roundtrip verification)

## Verification

```bash
bash ./scripts/verify_rpg_save_adapter_pack.sh
```

## Contract Details

This pack owns the RPG save schema version, migration stub, party serialization, inventory/equipment reference serialization, and quest progress serialization. It keeps RPG durable state as explicit dictionaries instead of saving live scene tree objects or third-party plugin internals.

- `RPGSaveAdapter.pack_id()` — returns `rpg-save-adapter`
- `RPGSaveAdapter.schema_version()` — returns the current RPG save schema version
- `RPGSaveAdapter.to_payload(...)` — serializes party, inventory, equipment, and quest state into a versioned dictionary
- `RPGSaveAdapter.from_payload(...)` — validates and migrates payloads before exposing dictionaries for runtime restoration

### Serialization Scope

The adapter serializes:

- **Party state** — character list, active party order, reserve members
- **Inventory references** — `ItemRef` IDs from `data-core`, quantities, equipment assignments
- **Equipment loadout** — slot-to-`ItemRef` mappings
- **Quest progress** — quest completion flags and stage tracking

### Migration Strategy

`from_payload()` checks the schema version and applies migration steps in sequence. Migration stubs are provided for forward-compatible schema evolution.

### Third-Party Boundaries

GLoot and QuestSystem remain optional surfaces. Their state must be bridged through first-party stable IDs and dictionaries before becoming durable save truth.

## Upstream

Toolbox-owned. No vendored dependencies.
