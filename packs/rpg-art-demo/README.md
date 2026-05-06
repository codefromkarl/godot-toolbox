# RPG Art Demo Pack

`rpg-art-demo` is an optional, non-default placeholder pack for validating RPG art/audio import policy and bootstrap overlay behavior.

It currently contains only first-party text placeholders:

- `art/placeholders/placeholder_assets.json` records intended visual placeholder categories.
- `audio/placeholders/placeholder_audio_assets.json` records intended audio placeholder categories.
- `import-policy.md` records the future import gate for third-party assets.
- `NOTICE.md` records the current first-party placeholder status.

## Boundaries

This pack must stay presentation-only. It must not define canonical RPG stats, item IDs, save schema, economy values, quest truth, battle formulas, battle rules, or runtime autoloads. Those remain owned by `rpg-core`, `rpg-battle-core`, `rpg-save-adapter`, and project-specific data.

## License And Import Policy

The current placeholder files are first-party repository text fixtures and are not downloaded third-party art/audio.

Future real asset imports should prefer CC0 sources. Every imported source must add or update NOTICE coverage with the exact source URL, author, license text or license URL, downloaded version or date, local target path, and any conversion steps. CC BY or mixed-license sources require explicit attribution text and visible credits in generated projects.

Do not download assets from mirrors. Do not add large binary art/audio bundles to this pack until the license, target path, and verification policy are recorded.
