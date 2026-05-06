# flow-test-kit

> Reusable flow-level smoke fixtures for projects bootstrapped from godot-toolbox.

| Field | Value |
|-------|-------|
| Kind | `architecture-test-kit` |
| Default | `false` |
| Requires | `base`, `flow-core` |
| Conflicts | — |

## Quick Start

```bash
./scripts/bootstrap_toolbox_project.sh /path/to/project --packs=flow-core,flow-test-kit
```

Preview without writing:
```bash
./scripts/bootstrap_toolbox_project.sh /path/to/project --packs=flow-core,flow-test-kit --dry-run-report
```

## What It Provides

- `FlowSmokeFixture` — runner-agnostic fixture for testing flow contracts
- `flow_core_smoke_test.gd` — gdUnit4 smoke suite copied into bootstrapped projects at `res://test/gdunit/flow_core_smoke_test.gd`

## When to Enable

- Projects using `flow-core` that need ready-made smoke tests for mode transitions
- Teams that want CI-verified flow contracts without writing boilerplate test fixtures
- Any project validating push/replace/pop/complete flow behavior

## Verification

```bash
bash ./scripts/verify_game_architecture_packs.sh
```

## Contract Details

The smoke suite verifies:

- **Push mode** via `FlowRequest.Kind.PUSH` — pushes a valid `GameMode`
- **Replace and pop mode** via `FlowRequest.Kind.REPLACE` and `FlowRequest.Kind.POP`
- **Complete flow result** — `FlowRequest.Kind.COMPLETE` records and emits a `FlowResult`
- **Minimal flow contract** — `FlowSmokeFixture.run_minimal_flow()` as the smallest reusable flow contract

`FlowSmokeFixture` is runner-agnostic: it can be used with gdUnit4 or any other test framework. The pack does not define its own autoload — it provides test utilities that exercise `flow-core` autoloads.

## Upstream

Toolbox-owned. No vendored dependencies.
