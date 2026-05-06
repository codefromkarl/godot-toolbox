# RPG Template Quickstart

This quickstart is the user-facing entrypoint for assembling the current RPG-ready shell. It is an executable recipe backed by the final automated evidence in `docs/rpg-final-acceptance-receipt.md` and the batch history in `docs/rpg-execution-verification-log.md`.

## Minimal RPG Template Recipe

Use this recipe when you want the smallest first-party RPG template surface with RPG state, deterministic battle runtime, save mapping, UI/content smoke, replay, event stream, and state dump evidence.

Required packs:

- `rpg-core`
- `rpg-battle-core`
- `rpg-save-adapter`
- `rpg-test-kit`
- `flow-core`
- `rules-events-core`
- `data-core`
- `save-core`

Optional packs:

- `inventory`: GLoot authoring/runtime primitives. Keep stable item and equipment IDs in `rpg-core` / `rpg-save-adapter`.
- `quest`: QuestSystem resources. Persist quest progress through `rpg-save-adapter` and `save-core`.
- `ai-behavior`: Beehave authoring for behavior-tree AI. The default deterministic battle core must still work without it.
- `save-state-lite`: alternative save tooling/reference only. It is not part of the default RPG save path.
- `dialogue`: Dialogue Manager authoring/runtime for dialogue graphs, text resources, and line playback. Dialogue state must bridge through `rules-events-core`, `data-core`, and `save-core` adapters.

Art/audio status:

- The minimal RPG recipe supplies first-party RPG state, battle, save, UI smoke, and example gameplay data.
- It does not vendor a complete RPG art/audio library for characters, monsters, scenes, tilesets, battle backgrounds, fonts, SFX, or BGM.
- Candidate CC0/open-source art/audio sources are recorded in `docs/rpg-art-asset-sources.md`.
- RPG example content authoring boundaries are recorded in `docs/rpg-content-authoring.md`; sample content is teaching/fixture data, not balance or release content.

Install order:

1. Start with `rpg-core` so character, party, item, equipment, level, and wallet truth is first-party.
2. Add `rpg-battle-core` for deterministic combat rules, turn order, action validation, AI policy, battle UI, and example content.
3. Add `rpg-save-adapter` so RPG state is serialized through `save-core` snapshots.
4. Add `rpg-test-kit` so replay, event stream, state dump, and RPG readiness smoke entrypoints are present.
5. Add infrastructure packs `flow-core`, `rules-events-core`, `data-core`, and `save-core`.
6. Add optional authoring packs only after the minimal recipe resolves cleanly.

Preview the minimal pack set before generating a project:

```bash
python3 scripts/pack_manifest.py report --packs=rpg-core,rpg-battle-core,rpg-save-adapter,rpg-test-kit,flow-core,rules-events-core,data-core,save-core
```

Generate a dry-run bootstrap report:

```bash
./scripts/bootstrap_toolbox_project.sh ../godot-toolbox-rpg-preview \
  --packs=rpg-core,rpg-battle-core,rpg-save-adapter,rpg-test-kit,flow-core,rules-events-core,data-core,save-core \
  --dry-run-report
```

## Verification commands

Run these from the repository root:

```bash
python3 scripts/pack_manifest.py validate
bash scripts/verify_pack_matrix.sh --row=rpg-core,rpg-battle-core,rpg-save-adapter,rpg-test-kit,flow-core,rules-events-core,data-core,save-core
bash scripts/verify_rpg_final_acceptance.sh
bash scripts/verify_rpg_template_recipe.sh
```

If the local Godot binary is not on `PATH`, set `GODOT_BIN` to your Godot executable before running the pack matrix row.

## Conflict boundaries

- `save-state-lite conflicts with save-core`: do not enable both in one generated project.
- The conflict exists because both expose a global SaveSlot surface.
- The default RPG path is `rpg-save-adapter` plus `save-core`.
- `save-state-lite` can be used as isolated reference tooling, but it cannot replace the default RPG persistence contract without a future namespacing or adapter decision.

The conflict should remain visible with:

```bash
python3 scripts/pack_manifest.py report --packs=save-state-lite,save-core
```

## Completion-language boundary

Allowed language:

- `RPG-ready shell evidence exists` at Runtime layer.
- `complete RPG template evidence exists` at automated Interaction layer.

Not allowed from this quickstart alone:

- Experience-layer claims.
- Human playtest claims.
- Release claims.

Use `docs/rpg-experience-review.md` if separate human or AI-assisted Experience review evidence is needed. Use `docs/rpg-playable-sample-recipe.md` for the route that separates the current automated Interaction sample from the future Experience/playable sample plan.
