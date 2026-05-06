# RPG Art Demo Import Policy

This pack is a controlled staging area for future RPG art/audio demo assets.

## Allowed Content

- First-party placeholder metadata for visual and audio categories.
- Imported art/audio assets after license review.
- NOTICE and source records for each imported external asset.
- Conversion notes that explain how raw assets became Godot-ready files.

## Disallowed Content

- Canonical gameplay stats, item IDs, quest state, save schemas, economy values, battle formulas, or battle rules.
- Runtime scripts, autoloads, plugins, or project settings beyond the manifest opt-in marker.
- Third-party assets without NOTICE coverage.
- Large binary bundles added without an explicit import review.

## Future CC0 Import Gate

Before importing a CC0 source:

1. Verify the primary source page and license.
2. Record the source URL, author, license, downloaded version or date, local target path, and conversion steps in `NOTICE.md`.
3. Keep gameplay truth in RPG core/data packs, not in filenames or metadata in this pack.
4. Run `bash scripts/verify_rpg_art_demo_pack.sh`.
