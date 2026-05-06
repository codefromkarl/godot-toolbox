# RPG Content Authoring Governance

This document defines the authoring boundary for `packs/rpg-core/godot/content/rpg_example/rpg_example_content.json`.

## Purpose

The RPG example content is teaching material, verifier fixture data, and sample data for the minimal RPG template. It exists so smoke tests and readers can see how heroes, enemies, skills, items, and equipment are shaped.

It is not:

- A balance standard for a production RPG.
- Release content for a shipped game.
- The authoritative source for save schemas.
- The authoritative source for battle formulas or combat rules.
- A registry for third-party plugin behavior or asset pack truth.

Changing the sample values should be treated as fixture maintenance, not gameplay balancing.

## Source Of Truth Boundaries

| Concern | Truth owner | Authoring rule |
| --- | --- | --- |
| Content IDs and RPG state data shape | `rpg-core` with `data-core` conventions | Keep IDs stable and human-readable. The example JSON may demonstrate IDs, but it must not become a cross-pack global registry. |
| Art asset references | future optional `rpg-art-demo` or another audited art pack | The example JSON must not vendor binary art, audio, fonts, or third-party asset metadata. Art packs may map their own audited resources to stable content IDs. |
| Save schema and migrations | `rpg-save-adapter` with `save-core` | Save snapshots, schema versions, migrations, and persistence compatibility must stay out of the example content file. |
| Battle formulas and combat rules | `rpg-battle-core` | Damage, healing, action validation, turn order, AI policy, rewards processing, and formula constants belong in battle code/tests, not content fixtures. |
| Third-party plugin truth | the relevant optional plugin pack and its NOTICE/import policy | Example content may interoperate with optional packs through adapters, but it must not define GLoot, QuestSystem, Beehave, SaveState Lite, or art-pack contracts. |

## Allowed Content File Responsibilities

The example content file may contain:

- Stable sample IDs such as `hero/lyra`, `enemy/slime`, `skill/fire`, and `item/potion`.
- Small fixture-scale stats and rewards needed by smoke tests.
- Names and minimal fields needed to teach authoring shape.
- Sample item, skill, and equipment rows used by deterministic verifier flows.

The example content file must not contain:

- Save schema versions, migration metadata, serialized slot layouts, or replay storage contracts.
- Damage formulas, turn-order formulas, AI decision trees, or battle tuning policy.
- Sprite paths, audio paths, font paths, raw asset source URLs, imported binary metadata, or third-party license records.
- Plugin-specific state that would make an optional plugin the canonical owner of RPG data.

## Future Art Pack Boundary

Future art packs should treat the example content IDs as optional lookup keys, not as art ownership. A pack such as `rpg-art-demo` may provide audited placeholder or imported resources and document how those resources map to content IDs, but the art pack must not redefine canonical RPG stats, item IDs, save schemas, or battle rules.

If an art pack needs richer presentation metadata, add it in that pack's own data/docs with source URL, license, attribution, and import policy records. Do not add third-party asset truth to `rpg_example_content.json`.

## Verification

Run the content authoring verifier from the repository root:

```bash
bash scripts/verify_rpg_content_authoring.sh
```

The verifier checks that the example content file exists, parses as JSON, the governance documents contain the boundary language above, and the authored docs do not include local machine absolute paths.
