# flow-test-kit

Reusable flow-level smoke fixtures for projects bootstrapped from `godot-toolbox`.

The pack provides a runner-agnostic `FlowSmokeFixture` plus a gdUnit4 smoke suite copied into bootstrapped projects at `res://test/gdunit/flow_core_smoke_test.gd`.

The smoke suite verifies:

- push mode via `FlowRequest`.
- replace and pop mode via `FlowRequest`.
- `complete_flow` result payload preservation.
- `FlowSmokeFixture.run_minimal_flow()` as the smallest reusable flow contract.
