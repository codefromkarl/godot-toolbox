# rpg-test-kit

> Toolbox-owned RPG verification pack — evidence layer for RPG-ready claims.

| Field | Value |
|-------|-------|
| Kind | `architecture-test-kit` |
| Default | `false` |
| Requires | `base`, `rpg-core`, `rpg-battle-core`, `rpg-save-adapter` |
| Conflicts | — |

## Quick Start

```bash
./scripts/bootstrap_toolbox_project.sh /path/to/project \
  --packs=rpg-core,rpg-battle-core,rpg-save-adapter,rpg-test-kit
```

Preview without writing:
```bash
./scripts/bootstrap_toolbox_project.sh /path/to/project \
  --packs=rpg-core,rpg-battle-core,rpg-save-adapter,rpg-test-kit --dry-run-report
```

## What It Provides

- `rpg_readiness_smoke.gd` — entrypoint for pack-local RPG smoke checks
- Deterministic battle replay fixtures
- Combat event stream assertion helpers
- State dump utilities for RPG runtime state inspection
- Save roundtrip verification checks
- UI smoke tests for RPG scenes

## When to Enable

- Projects that need evidence-based verification of RPG system correctness
- Teams preparing for RPG milestone reviews or acceptance testing
- Any project making "RPG-ready" claims that need automated evidence

## Verification

```bash
bash ./scripts/verify_rpg_test_kit_pack.sh
bash ./scripts/verify_rpg_ui_content.sh
bash ./scripts/verify_rpg_observability.sh
```

## Contract Details

This pack provides the evidence layer for RPG-ready claims. It is deliberately separate from the implementation packs so that:

- Implementation packs (`rpg-core`, `rpg-battle-core`, `rpg-save-adapter`) are **not** their own final validators
- Acceptance evidence is independently verifiable
- RPG milestone reviews reference this pack's test outputs

### Test Categories

- **Deterministic battle replay** — replays battles with seeded enemy AI and validates identical outcomes
- **Combat event stream** — asserts correct event emission order through `rules-events-core`
- **State dump** — captures and validates RPG runtime state snapshots
- **Save roundtrip** — serializes state via `rpg-save-adapter`, loads, and validates equality
- **UI smoke** — verifies RPG UI scenes load without errors and contain expected nodes

### RPG-Ready Claim

The repository can claim `RPG-ready shell` only when this pack contains runnable evidence for the available RPG domain and battle contracts. `complete RPG template evidence exists` is limited to automated interaction layers; `playable`, `release-ready`, or experience claims must reference `docs/rpg-experience-review.md`.

## Upstream

Toolbox-owned. No vendored dependencies.
