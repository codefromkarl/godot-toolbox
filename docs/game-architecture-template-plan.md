# Reusable Game Architecture Template Plan

## Purpose

`godot-toolbox` should absorb architecture lessons from complex games without becoming a clone of any one game.

The goal is to provide reusable Godot project packs for future games that need:

- multiple game modes
- long-lived simulation state
- data-driven content
- save/load with migration
- event/rule/quest/dialogue flows
- UI overlays and game shell
- flow-level automation

This plan separates:

- what already exists in `godot-toolbox`
- what can be absorbed from open source
- what should be built as toolbox-owned architecture

## Design Rule

Do not vendor gameplay truth by default.

Third-party addons may provide specialized authoring or runtime behavior, but the reusable toolbox layer should own:

- flow contracts
- pack contracts
- state boundaries
- save contracts
- data ID contracts
- verification contracts

This prevents future projects from hiding core game truth inside a third-party plugin that is hard to migrate or test.

## Existing Assets

| Area | Current asset | Keep / change |
| --- | --- | --- |
| Test baseline | `gdUnit4` | Keep in `base`. |
| GDScript quality | `godot-gdscript-toolkit` | Keep in `base`. |
| Scene/resource validation | `Godot Doctor` | Keep as optional `validation`. |
| Signal debugging | `Signal Lens` | Keep as optional `debug`. |
| State charts | `Godot State Charts` | Keep as optional `stateful`; use as one state modeling option, not the only flow mechanism. |
| Feedback authoring | `Sparkle Lite` | Keep as optional `juice`. |
| E2E automation | `GodotE2E` candidate | Promote only after pack contract and project setting injection are implemented. |
| App shell | `Maaack's Game Template` candidate | Keep as source of shell patterns; do not default-enable or let it own project runtime truth. |

## Open Source Absorption Plan

| Pack direction | Candidate source | Absorption mode | First decision |
| --- | --- | --- | --- |
| `input` | `G.U.I.D.E` | Non-default optional pack | Good fit for unified input across devices. Bootstrap injection contract now exists. |
| `quest` | `QuestSystem` | Non-default optional pack | Good resource-based quest model. Bootstrap contract now exists; project truth still needs save/event adapters. |
| `dialogue` | `Dialogue Manager` | Non-default optional pack (v3.10.4) | Vendored as opt-in dialogue pack. Requires `data-core`, `save-core`, `rules-events-core` adapters. |
| `inventory` | `GLoot` | Non-default optional pack | Useful for RPG/sim projects. Keep out of base and bridge through project-owned item/save adapters. |
| `save` | `SaveState Lite`, GDQuest resource save pattern, Godot docs | Optional pack plus references | Save correctness is core truth; SaveState Lite is opt-in tooling/reference, while `save-core` owns the contract. |
| `data` | `Pandora`, Godot Resource pattern | Reference only initially | Pandora is alpha and RPG-scoped. Build a smaller generic registry/resource scaffold first. |
| `rules-events` | `MEF` | Reference only | Its execution group / condition / effect model is useful, but early 0.1.0 is too young to vendor. |
| `flow` | `Maaack's Game Template`, `Scene Manager` | Reference only | Use ideas for transitions and menus, but own game mode/result/pause contracts. |
| `ai` | `Beehave`, `LimboAI` | Non-default optional pack / external reference | Beehave is now opt-in; LimboAI remains external by default due to native-extension surface. |

## Toolbox-Owned Packs To Build

### 1. `flow-core`

Purpose:

- Provide the generic flow backbone every complex game needs.

Owned contracts:

- `GameMode`
- `GameModeStack`
- `FlowRequest`
- `FlowResult`
- `SceneTransitionService`
- `PausePolicy`
- `ReturnPayload`

Non-goals:

- No campaign-specific or combat-specific implementation.
- No hard dependency on a third-party scene manager.

Why own it:

- This is where most large Godot projects either stay clean or become global singleton mud.
- Third-party scene transition plugins do not define game result semantics.

### 2. `simulation-core`

Purpose:

- Provide stable time/tick boundaries for games with long-lived world state.

Owned contracts:

- `SimulationClock`
- `TickSystem`
- `GameSystem`
- `SystemScheduler`
- `TimeScalePolicy`
- `PauseDomain`

Non-goals:

- No genre-specific world model.
- No physics replacement.

Why own it:

- Godot lifecycle callbacks are not enough for complex simulation boundaries.
- Projects need explicit separation between UI time, world time, combat time, and background time.

### 3. `data-core`

Purpose:

- Provide reusable data-driven content scaffolding.

Owned contracts:

- `GameId`
- `DataRegistry`
- `ResourceTable`
- `ContentManifest`
- JSON/CSV import scaffold
- schema validation command
- duplicate ID detection

Absorb:

- Godot `Resource` pattern.
- Pandora-style data taxonomy ideas.

Non-goals:

- Do not become a full RPG database by default.

### 4. `save-core`

Purpose:

- Provide a project-owned save boundary with versioning.

Owned contracts:

- `SaveProfile`
- `SaveSlot`
- `SaveSnapshot`
- `SaveMigration`
- `SaveReferenceResolver`
- `StableObjectId`
- atomic write helper

Absorb:

- GDQuest resource-save pattern.
- Godot official save cautions around nested persistent objects and JSON limits.
- SaveState Lite ideas around atomic commits, backup files, schema migration, and slots.

Non-goals:

- Do not promise one universal save format for every game.
- Do not save arbitrary scene trees as the default strategy.

### 5. `rules-events-core`

Purpose:

- Provide a small event/condition/effect spine for quests, dialogue, simulation hooks, and gameplay triggers.

Owned contracts:

- `GameEvent`
- `Condition`
- `EffectCommand`
- `ExecutionContext`
- `MemoryScope`
- `EventQueue`

Absorb:

- MEF's execution group, priority, cancellation, and shared-context concepts.
- Dialogue/quest addon interoperability points.

Non-goals:

- Do not rebuild a large visual scripting system.

### 6. `ui-game-shell`

Purpose:

- Provide game UI primitives that sit below genre-specific UI.

Owned contracts:

- `HudLayer`
- `OverlayLayer`
- `ModalLayer`
- `TooltipService`
- `TabShell`
- `CommandOverlay`
- `NotificationFeed`

Absorb:

- Maaack shell patterns for menu/options/pause/loading.
- Future project-specific UI components through scene templates.

Non-goals:

- No fixed visual style.
- No hardcoded RPG, strategy, or shooter UI.

### 7. `flow-test-kit`

Purpose:

- Provide reusable flow-level testing around a bootstrapped project.

Owned contracts:

- smoke scene fixture
- flow fixture API
- E2E launch wrapper
- result assertion helpers
- pack-combination matrix entry

Absorb:

- Existing `GodotE2E` candidate.
- Existing `gdUnit4` smoke.

Non-goals:

- No full test runner replacement.

## Implementation Phases

### Phase 0: Pack Contract Foundation

Deliverables:

- Extend `packs.manifest.json` with a richer pack schema.
- Add fields for `requires`, `conflicts`, `autoloads`, `project_settings`, `input_map`, `verification`, and `godot_version`.
- Add a manifest validation script.
- Add a dry-run bootstrap report that shows what each selected pack will inject.

Exit criteria:

- Candidate packs can describe required autoloads and project settings without custom verification scripts patching `project.godot` manually.

### Phase 1: Toolbox-Owned Architecture Core

Deliverables:

- Add `flow-core` as the first architecture pack.
- Add `simulation-core` as a separate pack.
- Add `data-core` minimal registry and schema scaffold.
- Add `save-core` minimal versioned resource/JSON snapshot scaffold.
- Add `flow-test-kit` smoke that verifies one mode transition and one result payload.

Exit criteria:

- A fresh project can be bootstrapped with `flow-core,simulation-core,data-core,save-core,flow-test-kit`.
- It can run headless smoke and one E2E-style flow test.

### Phase 2: Promote Existing Candidates Carefully

Deliverables:

- Promote `automation` if Phase 0 pack injection supports its autoload requirements.
- Keep `shell` candidate isolated until it can install only shell scenes without owning game flow truth.
- Keep `G.U.I.D.E` as a non-default `input` pack and avoid making input modeling part of `base`.
- `QuestSystem` has been vendored as a non-default `quest` pack against `save-core`, `data-core`, and `rules-events-core`.

Exit criteria:

- Promoted packs have source lock entries, manifest entries, bootstrap integration, and at least one verification path.

### Phase 3: Specialized Gameplay Packs

Deliverables:

- Evaluate `dialogue` once Dialogue Manager 4 maturity is acceptable.
- `Dialogue Manager` has been vendored as a non-default `dialogue` pack (v3.10.4); adapter tests for dialogue events crossing `rules-events-core`/`data-core`/`save-core` remain a follow-up task.
- `GLoot` has been vendored as a non-default `inventory` pack.
- `SaveState Lite` has been vendored as a non-default `save-state-lite` pack.
- Add `rules-events-core` before integrating quest/dialogue deeply.
- Add `ui-game-shell` after flow/pause/modal boundaries are stable.

Exit criteria:

- Quest/dialogue/inventory/save-tooling packs can remain optional and can interoperate through toolbox-owned data/save/event contracts.

### Phase 4: Advanced AI / Behavior Optionality

Deliverables:

- Keep `Beehave` as an optional `ai-behavior` pack; use self-owned deterministic policies for first-pass turn-based RPG combat.
- Keep `LimboAI` as external reference unless a project explicitly needs GDExtension-based behavior trees/HSM.

Exit criteria:

- AI pack is not required for starter projects.
- AI pack does not alter base runtime ownership.

## Immediate Next Steps

1. Implement `packs.manifest.json` schema validation before adding new gameplay packs.
2. Design the `flow-core` API and minimal Godot scene/autoload layout.
3. Build one bootstrap smoke project using `flow-core` only.
4. Add `simulation-core` and `save-core` only after flow contracts are stable.
5. Revisit `automation` promotion once project setting and autoload injection are declarative.

## Non-Goals

- Do not turn `godot-toolbox` into a full game framework.
- Do not make any genre-specific pack default.
- Do not vendor alpha projects into default bootstrap.
- Do not let third-party plugins own save truth, data truth, or flow truth.
- Do not copy app shell templates wholesale into generated projects without explicit pack selection.

## Current Recommendation

The next useful repository work is not adding `inventory` or `quest` immediately (both are done).

The next useful work is:

```text
pack contract -> flow-core -> simulation-core -> data-core -> save-core -> flow-test-kit
```

Once that spine exists, specialized open-source addons become safe optional packs rather than architectural dependencies.

## Landing Status

Current repository landing after this plan:

- Phase 0 pack contract foundation exists in `packs.manifest.json` schema version `2`.
- `scripts/pack_manifest.py` validates pack contracts, renders bootstrap project settings/autoloads, and produces dry-run injection reports.
- `scripts/bootstrap_toolbox_project.sh --dry-run-report` previews selected pack overlays, enabled plugins, autoloads, project settings, and verification entries.
- `flow-core`, `simulation-core`, `data-core`, `save-core`, and `flow-test-kit` now exist as toolbox-owned scaffold packs.
- `rules-events-core` now exists as a toolbox-owned event/condition/effect spine with a runnable smoke verifier.
- `ui-game-shell` now exists as a toolbox-owned shell primitives pack with a runnable smoke verifier and no dependency on `Maaack's Game Template` runtime ownership.
- `scripts/verify_pack_matrix.sh` now verifies deploy/import/smoke behavior across key pack combinations.
- Open-source architecture candidates are linked in `docs/open-source-architecture-links.md`, `docs/rpg-template-absorption-plan.md`, `packs.manifest.json`, and `upstreams.lock.json`; vendored third-party gameplay packs remain non-default.
- `scripts/verify_game_architecture_packs.sh` validates the new architecture pack bootstrap contract.
