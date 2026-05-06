# RPG Playable Sample Recipe

Status date: 2026-04-27.

This route document separates what the repository can verify today from the future work needed for a player-facing sample project. It is a planning and verification entrypoint, not a Release claim.

## Current Automated Interaction Sample

The current sample route is an automated Interaction sample. It proves that the minimal RPG template pack set can resolve through the manifest and expose RPG state, deterministic battle runtime, save mapping, replay/state dump tooling, event stream evidence, UI/content smoke entrypoints, and supporting architecture packs.

Current minimal RPG pack set:

- `rpg-core`
- `rpg-battle-core`
- `rpg-save-adapter`
- `rpg-test-kit`
- `flow-core`
- `rules-events-core`
- `data-core`
- `save-core`

Verify the current route with:

```bash
python3 scripts/pack_manifest.py report --packs=rpg-core,rpg-battle-core,rpg-save-adapter,rpg-test-kit,flow-core,rules-events-core,data-core,save-core
```

Preview bootstrap injection with:

```bash
./scripts/bootstrap_toolbox_project.sh ../godot-toolbox-rpg-preview \
  --packs=rpg-core,rpg-battle-core,rpg-save-adapter,rpg-test-kit,flow-core,rules-events-core,data-core,save-core \
  --dry-run-report
```

This current route supports automated Runtime and Interaction evidence only. Use `docs/rpg-template-quickstart.md` for the minimal template recipe and `docs/rpg-experience-review.md` for the separate Experience evidence carrier.

## Future Experience/Playable Sample

A future Experience/playable sample should add player-facing evidence that cannot be proven by the current manifest report alone:

- Clear start-to-battle flow with visible objective, party state, enemy state, and action feedback.
- Sample content that demonstrates reusable heroes, enemies, skills, items, equipment, and save/reload behavior.
- Reviewer notes, screenshots, video, UI tree notes, or equivalent artifacts captured from an actual human or AI-assisted playtest session.
- Issue records for unclear controls, confusing affordances, weak sample content, pacing problems, or replay/save interpretation problems.

`rpg-art-demo` is an existing non-default placeholder overlay for this route. It validates art/audio import policy, NOTICE discipline, and bootstrap overlay behavior, but it currently contains only first-party text placeholders and does not provide real player-facing art/audio. It is not part of the current required command, and selecting it must not upgrade the current automated route into an Experience/playable claim.

## Release Claim Boundary

Release claims are prohibited from this document and from the current automated route. The current recipe may say:

- `RPG-ready shell evidence exists` at Runtime layer.
- `complete RPG template evidence exists` at automated Interaction layer.
- Future Experience/playable evidence is planned but not claimed here.

The current recipe must not claim a shipped-quality sample, a completed Release layer, or production suitability. Those claims require separate Release acceptance criteria and evidence beyond this document.

## Verifier

Run the guardrail verifier from the repository root:

```bash
bash scripts/verify_rpg_playable_sample_recipe.sh
```

The verifier checks that this document keeps the minimal RPG command executable, keeps `rpg-art-demo` optional and non-promotional despite being available as a placeholder pack, uses repository-relative paths, links from the existing recipe docs, and avoids overclaim language.
