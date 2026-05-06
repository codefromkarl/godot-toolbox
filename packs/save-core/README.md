# save-core

> Toolbox-owned save boundary for versioned snapshots and atomic JSON writes.

| Field | Value |
|-------|-------|
| Kind | `architecture-core` |
| Default | `false` |
| Requires | `base`, `data-core` |
| Conflicts | `save-state-lite` |

## Quick Start

```bash
./scripts/bootstrap_toolbox_project.sh /path/to/project --packs=save-core
```

Preview without writing:
```bash
./scripts/bootstrap_toolbox_project.sh /path/to/project --packs=save-core --dry-run-report
```

## What It Provides

- `SaveCore` autoload singleton
- `SaveSnapshot` resource for versioned payload snapshots
- Atomic JSON write and load operations

## When to Enable

- Projects needing versioned, structured save data
- Games that require save/load roundtrips with schema migration support
- Any project using `rpg-core`, `rpg-save-adapter`, `inventory`, `quest`, or `dialogue` (they depend on this pack)

## Verification

```bash
bash ./scripts/verify_game_architecture_packs.sh
```

## Contract Details

This pack references SaveState Lite, GDQuest's resource save pattern, and Godot's official save warnings, but keeps save truth in a minimal project-owned facade.

- `SaveCore.create_snapshot(payload)` — deep-copies project-owned payload data into a `SaveSnapshot`
- `SaveSnapshot.to_dictionary()` / `SaveSnapshot.from_dictionary(data)` — versioned dictionary roundtrips
- `SaveCore.save_json(path, snapshot)` — writes JSON through a temporary file and commit step (atomic write)
- `SaveCore.load_json(path)` — loads only snapshot dictionaries; this pack does **not** save arbitrary scene trees

### Conflict with save-state-lite

`save-core` conflicts with `save-state-lite` because both expose a `SaveSlot` global class. Choose one:

- **`save-core`** (recommended for RPG and architecture packs) — project-owned persistence boundary
- **`save-state-lite`** — vendored alternative with SaveManager, atomic writer, and save browser

## Upstream

Toolbox-owned. No vendored dependencies.

References: SaveState Lite, GDQuest save patterns, Godot official save documentation.
