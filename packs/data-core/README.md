# data-core

> Toolbox-owned data registry and stable content ID scaffold.

| Field | Value |
|-------|-------|
| Kind | `architecture-core` |
| Default | `false` |
| Requires | `base` |
| Conflicts | — |

## Quick Start

```bash
./scripts/bootstrap_toolbox_project.sh /path/to/project --packs=data-core
```

Preview without writing:
```bash
./scripts/bootstrap_toolbox_project.sh /path/to/project --packs=data-core --dry-run-report
```

## What It Provides

- `DataCore` autoload singleton
- `GameId` utility for stable ID validation
- Data registry with duplicate ID policy control

## When to Enable

- Projects needing a centralized content ID registry
- Games with resource-driven content that requires stable, serializable identifiers
- Any project using `save-core`, `rpg-core`, `inventory`, `quest`, or `dialogue` (they all depend on this pack)

## Verification

```bash
bash ./scripts/verify_game_architecture_packs.sh
```

## Contract Details

This pack absorbs the useful shape of Godot Resource-driven content and heavier data tools such as Pandora without making an RPG database the default.

- `GameId.is_valid_id(id)` — accepts non-empty, trim-safe, slash-separated stable IDs
- `DataCore.register_resource(id, resource)` — returns `OK`, `ERR_INVALID_PARAMETER`, or `ERR_ALREADY_EXISTS`
- Duplicate IDs default to `REJECT`; callers can switch `duplicate_id_policy` to `REPLACE` or `KEEP_EXISTING`
- `DataCore.list_ids()` — returns the currently registered IDs
- `DataCore.clear()` — empties the registry

IDs are designed to be serializable, stable across save/load cycles, and independent of Godot Resource UIDs.

## Upstream

Toolbox-owned. No vendored dependencies.

Reference: `pandora` (reference-only, not vendored) for data taxonomy inspiration.
