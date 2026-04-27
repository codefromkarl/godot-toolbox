# rpg-save-adapter

Toolbox-owned adapter from RPG runtime state to `save-core` snapshots.

This pack owns the RPG save schema version, migration stub, party serialization, inventory/equipment reference serialization, and quest progress serialization. It keeps RPG durable state explicit dictionaries instead of saving live scene tree objects or third-party plugin internals.

## Minimal Contract

- `RPGSaveAdapter.pack_id()` returns `rpg-save-adapter`.
- `RPGSaveAdapter.schema_version()` returns the current RPG save schema version.
- `RPGSaveAdapter.to_payload(...)` serializes party, inventory, equipment, and quest state.
- `RPGSaveAdapter.from_payload(...)` validates and migrates payloads before exposing dictionaries for runtime restoration.

GLoot and QuestSystem remain optional surfaces. Their state must be bridged through first-party stable IDs and dictionaries before becoming durable save truth.
