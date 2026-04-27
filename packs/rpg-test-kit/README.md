# rpg-test-kit

Toolbox-owned RPG verification scaffold.

This pack provides the evidence layer for RPG-ready claims. It should grow deterministic battle replay fixtures, combat event stream assertions, state dump helpers, save roundtrip checks, and UI smoke tests as `rpg-core`, `rpg-battle-core`, and RPG UI mature.

## Minimal Contract

- Depends on `rpg-core` and `rpg-battle-core`.
- Ships a `rpg_readiness_smoke.gd` entrypoint for pack-local smoke checks.
- Keeps acceptance evidence separate from runtime truth so implementation packs are not their own final validators.

The repository can claim `RPG-ready shell` only when this pack contains runnable evidence for the available RPG domain and battle contracts.
