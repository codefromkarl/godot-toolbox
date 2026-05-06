# AI Testing Strategy: ai-testing + rpg-test-kit Bridge

## Overview

godot-toolbox provides two complementary test packs for RPG validation:

| Pack | Layer | Scope | Method |
|------|-------|-------|--------|
| **rpg-test-kit** | Godot (GDScript) | Unit / Integration | gdUnit4 + SceneTree tests; deterministic replay fixtures |
| **ai-testing** | Python + Godot | System / Exploration | Policy-driven exploration; coverage-guided; bug discovery |

They are **not competitors** — they cover different testing layers and should be used together for comprehensive RPG validation.

## Testing Pyramid

```
           ┌─────────────────┐
           │  ai-testing     │  ← Exploration / stress / policy-driven
           │  (Python + Godot)│    Random/Heuristic/EpsilonGreedy policies
           ├─────────────────┤    Coverage tracking, bug discovery
           │  rpg-test-kit   │  ← Integration / replay / state dump
           │  (GDScript)     │    Battle replay fixtures, save roundtrip
           ├─────────────────┤    State dump validation
           │  gdUnit4        │  ← Unit tests
           │  (base)         │    Per-class smoke, edge cases
           └─────────────────┘
```

## rpg-test-kit Capabilities

- **Battle Replay Runner**: Runs deterministic battle fixtures through `BattleSession.run_to_completion()` and validates outcomes
- **RPG State Dump**: Captures battle/party/inventory/save state as serializable dictionaries
- **Edge Case Tests**: Validates boundary conditions (empty party, zero HP, etc.)
- **Godot-native**: All tests run in Godot headless via SceneTree or gdUnit4

## ai-testing Capabilities

- **TestEnvironment protocol**: `reset()` / `step()` / `action_space` / `result` — domain-agnostic
- **Policies**: Random, Scripted, Heuristic (abstract base), EpsilonGreedy
- **EpisodeRunner**: Orchestrates episodes, collects telemetry, writes artifacts
- **CoverageTracker**: Tracks observation keys and event types
- **BugDiscovery**: Post-hoc analysis for stuck states, reward anomalies, unexplored actions
- **RPGBattleEnv**: First domain-specific TestEnvironment consumer (turn-based battle)

## Bridge Points

### 1. Fixture Generation

ai-testing can generate battle fixtures that rpg-test-kit can replay:

```python
# ai-testing generates fixtures via RPGBattleEnv
from rpg_battle_env import RPGBattleEnv
from ai_testing.runner import EpisodeRunner, EpisodeConfig
from ai_testing.policies import RandomPolicy

env = RPGBattleEnv()
runner = EpisodeRunner("build/ai-testing")
runner.run_episode(EpisodeConfig("gen-001", "rpg_battle", "random"), env, RandomPolicy(seed=42))
# → artifacts include telemetry with action sequences
# → these can be converted to rpg-test-kit replay fixtures
```

### 2. State Dump Validation

ai-testing's observation format overlaps with rpg-test-kit's `RPGStateDump`:

| ai-testing observation | rpg-test-kit dump |
|------------------------|-------------------|
| `party[].hp` | `dump_battle().party[].current_hp` |
| `party[].defeated` | `dump_battle().party[].defeated` |
| `enemies[].hp` | `dump_battle().enemies[].current_hp` |

A bridge adapter could convert between these formats for cross-validation.

### 3. Coverage-Guided Test Generation

ai-testing's `CoverageTracker` identifies unexplored action sequences. These gaps can feed into rpg-test-kit fixture creation:

```python
# After running exploration episodes
summary = runner.coverage.summary()
unexplored = [a for a in summary["unique_actions"]
              if a not in summary["seen_events"]]
# → Generate rpg-test-kit fixtures for uncovered scenarios
```

## Recommended Workflow

1. **Start with rpg-test-kit**: Write deterministic replay fixtures for known battle scenarios (victory, defeat, edge cases)
2. **Add ai-testing exploration**: Run `RPGBattleEnv` with `RandomPolicy` and `RPGBattleHeuristicPolicy` to discover unexpected behaviors
3. **Promote findings**: When ai-testing discovers a bug, capture the action sequence as a new rpg-test-kit replay fixture
4. **Track coverage**: Use ai-testing's `CoverageTracker` to monitor which battle states have been explored

## File Locations

| Component | Path |
|-----------|------|
| ai-testing Python framework | `packs/ai-testing/python/ai_testing/` |
| ai-testing GDScript autoload | `packs/ai-testing/godot/addons/godot_toolbox_architecture/ai_testing/` |
| RPG battle environment | `packs/ai-testing/examples/environments/rpg_battle_env.py` |
| RPG battle heuristic policy | `packs/ai-testing/examples/environments/rpg_battle_heuristic_policy.py` |
| Battle replay runner | `packs/rpg-test-kit/.../rpg_test_kit/replay/battle_replay_runner.gd` |
| RPG state dump | `packs/rpg-test-kit/.../rpg_test_kit/dump/rpg_state_dump.gd` |
