# rpg-test-kit

Toolbox-owned RPG verification pack.

This pack provides the evidence layer for RPG-ready claims. It includes deterministic battle replay fixtures, combat event stream assertions, state dump helpers, save roundtrip checks, and UI smoke tests for the current RPG packs.

## Minimal Contract

- Depends on `rpg-core` and `rpg-battle-core`.
- Ships a `rpg_readiness_smoke.gd` entrypoint for pack-local smoke checks.
- Ships deterministic replay and state dump smoke checks through `scripts/verify_rpg_observability.sh`.
- Keeps acceptance evidence separate from runtime truth so implementation packs are not their own final validators.

The repository can claim `RPG-ready shell` only when this pack contains runnable evidence for the available RPG domain and battle contracts.
