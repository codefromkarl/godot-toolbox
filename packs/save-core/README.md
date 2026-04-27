# save-core

Toolbox-owned save boundary for versioned snapshots and atomic JSON writes.

This pack references SaveState Lite, GDQuest's resource save pattern, and Godot's official save warnings, but keeps save truth in a minimal project-owned facade.

## Minimal Contract

- `SaveCore.create_snapshot(payload)` deep-copies project-owned payload data into a `SaveSnapshot`.
- `SaveSnapshot.to_dictionary()` and `SaveSnapshot.from_dictionary(data)` provide versioned dictionary roundtrips.
- `SaveCore.save_json(path, snapshot)` writes JSON through a temporary file and commit step.
- `SaveCore.load_json(path)` loads only snapshot dictionaries; this pack does not save arbitrary scene trees.
