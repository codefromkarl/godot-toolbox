# Dialogue Pack Candidate Plan

## Purpose

This document defines the boundary for the dialogue pack. Dialogue Manager has been promoted from candidate to optional pack status as of v3.10.4.

The current status is:

| Candidate | Upstream | Status | Current action |
| --- | --- | --- | --- |
| Dialogue Manager | <https://github.com/nathanhoad/godot_dialogue_manager> | **Promoted to optional pack (v3.10.4)** | Vendored in `packs/dialogue/`; non-default; requires `base`, `data-core`, `save-core`, `rules-events-core`. |
| Dialogic | <https://github.com/dialogic-godot/dialogic> | Candidate/reference only | Deferred reference for heavier dialogue/VN workflows. Do not vendor, bootstrap, or enable by default. |

### Version and License

- Dialogue Manager v3.10.4 (stable v3 line, MIT license)
- v4 remains in development; this integration uses the mature v3 stable branch
- License recorded in `docs/rpg-vendor-license-notice.md`
- Autoload note: Dialogue Manager registers `DialogueManager` autoload; registration name does not conflict with `class_name` isolation norms

### Recommended Integration Strategy

- v3 stable (v3.10.4) is the current vendored version
- v4 can be evaluated for upgrade after it reaches stable release and passes Godot 4.6 compatibility checks

## Ownership Boundary

The dialogue pack provides authoring UI, dialogue graph/text resources, runtime line playback, choices, variables local to a conversation, and adapter hooks.

It must not own campaign truth, global story progression, save schema, persistent event history, quest truth, inventory truth, battle truth, or project bootstrap control.

Required integration boundaries:

- `rules-events-core` owns condition/effect/event execution semantics for dialogue-triggered gameplay changes.
- `data-core` owns stable IDs and shared registry boundaries for speakers, dialogue resources, quest refs, item refs, and content lookups.
- `save-core` owns versioned snapshot structure and persistence mechanics.
- `rpg-save-adapter` owns RPG-specific mapping into `save-core`, including dialogue-related RPG state if an RPG template uses it.

Dialogue state may be projected into those contracts through an adapter, but the addon must not define the canonical campaign save schema or become the single source of story truth.

## Promotion Gate

The following gate conditions have been satisfied for Dialogue Manager:

- Godot 4.6 compatibility and upstream maturity are checked against the target repository baseline. ✅ (v3.10.4 stable)
- License and NOTICE obligations are recorded before any vendored files are introduced. ✅ (MIT, recorded in `docs/rpg-vendor-license-notice.md`)
- A dry-run pack contract exists and proves dependency, conflict, bootstrap, and non-default behavior without copying files into a generated project. ✅ (`scripts/verify_dialogue_pack.sh`)
- Adapter tests prove dialogue events cross `rules-events-core`, content IDs cross `data-core`, and persistence crosses `save-core` / `rpg-save-adapter`. ✅ (`packs/dialogue/godot/addons/godot_toolbox_dialogue/tests/dialogue_adapter_smoke.gd`)
- No default bootstrap takeover is possible: no new default pack, no automatic autoload ownership, no replacement of the main scene, and no implicit campaign/save/event authority. ✅ (`default=false`, no autoloads in manifest)

## Verifier Contract

`scripts/verify_dialogue_pack.sh` verifies the promoted optional pack. `scripts/verify_dialogue_pack_candidate.sh` continues to enforce that candidate governance documentation is maintained for Dialogic (still in candidate status).
