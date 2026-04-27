# data-core

Toolbox-owned data registry and stable content ID scaffold.

This pack absorbs the useful shape of Godot Resource-driven content and heavier data tools such as Pandora without making an RPG database the default.

## Minimal Contract

- `GameId.is_valid_id(id)` accepts non-empty, trim-safe, slash-separated stable IDs.
- `DataCore.register_resource(id, resource)` returns `OK`, `ERR_INVALID_PARAMETER`, or `ERR_ALREADY_EXISTS`.
- Duplicate IDs default to `REJECT`; callers can switch `duplicate_id_policy` to `REPLACE` or `KEEP_EXISTING`.
- `DataCore.list_ids()` returns the currently registered IDs; `DataCore.clear()` empties the registry.
