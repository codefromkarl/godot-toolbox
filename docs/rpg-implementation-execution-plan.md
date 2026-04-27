# RPG Implementation Execution Plan

Status date: 2026-04-27.

This document is the repository-owned execution plan for the full RPG backlog in `docs/rpg-template-absorption-plan.md`. It replaces generic Vibe-generated planning text for implementation control. Vibe may be used later only as an outer cleanup / acceptance receipt layer after real implementation evidence, verification logs, and cleanup receipts exist in this repository.

## Scope Freeze

Frozen scope includes every RPG task from `RPG-I01` through `RPG-D04`:

- `RPG-I01` to `RPG-I05`: integration hardening.
- `RPG-C01` to `RPG-C07`: `rpg-core`.
- `RPG-B01` to `RPG-B10`: `rpg-battle-core`.
- `RPG-S01` to `RPG-S04`: `rpg-save-adapter`.
- `RPG-U01` to `RPG-U06`: RPG UI and example content.
- `RPG-T01` to `RPG-T05`: RPG test kit and observability.
- `RPG-D01` to `RPG-D04`: documentation governance.

Completion cannot be claimed from plans, placeholders, `planned_contracts`, documentation-only assertions, a single readiness sentinel, or pack scaffold existence unless the source task is explicitly a scaffold task. Code tasks require failing-first checks or equivalent targeted red checks, then green verification evidence.

## Persistent Execution Mechanism

Task status matrix:

- Each task is tracked as `not_started`, `red_written`, `implemented`, `verified`, `blocked`, or `deferred_with_receipt`.
- `verified` requires implementation evidence, exact command evidence, and a cleanup receipt.
- `blocked` requires a concrete blocker, failed command or missing dependency, owner decision needed, and next retry condition.

Batch commit strategy:

- Commit once per coherent batch after green checks pass.
- Use the `commit_label` in the matrix as the first line prefix for commit messages.
- Do not mix unrelated batches in one commit unless the verification log explicitly explains why they were coupled.
- Never commit generated temporary Godot projects, Vibe runtime folders, or autoresearch scratch outputs.

Per-batch verification log:

- Append every batch to `docs/rpg-execution-verification-log.md`.
- Required fields are `batch`, `tasks`, `red_check`, `green_check`, `status`, `commit`, `artifacts`, `cleanup_receipt`, and `remaining_gaps`.
- A green check must include the exact command, exit status, and the evidence artifact or log location when a command emits one.

Scaffold-only判定规则:

- `scaffold_only_allowed=true` only permits task closure when the original source task is explicitly about creating a scaffold or manifest entry.
- `RPG-C01` and `RPG-B01` may close on scaffold evidence because their source tasks are pack creation / scaffold tasks.
- `RPG-T01` may not close on a readiness smoke alone because its source task requires test fixtures across core, battle, save, and UI smoke.
- Any task with `scaffold_only_allowed=false` must show runnable behavior, tests, or reviewable documentation evidence matching its acceptance row.

Unfinished-task writeback rules:

- After every batch, update this document or the verification log with remaining task state before moving to the next batch.
- If a task is split, keep the original task ID visible and record subtask evidence under that ID.
- If a task is deferred, document the failure boundary, retry command, and why it does not block already-verified tasks.
- Completion language must match evidence: `RPG-ready shell`, `complete RPG template`, and `playable RPG sample` are separate claims.

## Batch Plan

| Batch | Goal | Commit boundary | Required green commands |
| --- | --- | --- | --- |
| `B0-integration-hardening` | Close integration hardening gaps and license/update policy evidence. | One docs/scripts commit. | `python3 scripts/pack_manifest.py validate`; `bash scripts/verify_specialized_pack_candidates.sh`; `bash scripts/verify_pack_matrix.sh --all`. |
| `B1-rpg-core-tdd` | Implement first-party RPG state/data contracts. | One pack implementation commit. | `bash scripts/verify_rpg_core_pack.sh`; targeted Godot test runner once fixtures exist. |
| `B2-rpg-battle-core-tdd` | Implement deterministic battle runtime. | One battle implementation commit. | `bash scripts/verify_rpg_battle_core_pack.sh`; deterministic smoke/replay commands. |
| `B3-rpg-save-adapter-tdd` | Implement RPG save snapshot mapping and migrations. | One adapter commit. | Save adapter roundtrip tests; `bash scripts/verify_rpg_test_kit_pack.sh`. |
| `B4-rpg-ui-content` | Add battle scene, HUD, menus, party/equipment UI, and example content. | One UI/content commit unless content fixtures need a separate commit. | Headless import, UI smoke, fixed battle smoke using example data. |
| `B5-rpg-test-observability` | Add replay, event stream, state dump, and acceptance matrix evidence. | One observability/test-kit commit. | Replay twice and compare; event stream assertions; state dump JSON validation. |
| `B6-doc-governance` | Close README, recipes, adapter boundary docs, and upgrade checklist. | One documentation commit. | `rg` evidence for all docs claims; dry-run recipes; markdown link/path sanity check. |
| `B7-final-acceptance-cleanup` | Produce full task status matrix, implementation evidence, verification commands, and cleanup receipt. | One final receipt commit. | Full verification chain plus no untracked temp artifacts. |

## RPG Executable Task Matrix

| task_id | batch | write_scope | implementation_files | test_or_smoke_files | red_check | green_check | acceptance_evidence | failure_boundary | commit_label | scaffold_only_allowed |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `RPG-I01` | `B0-integration-hardening` | README and maintenance docs for pack dry-run examples. | `README.md`; `docs/maintenance-workflow.md`; `docs/rpg-template-absorption-plan.md` if source plan needs status notes. | `scripts/pack_manifest.py`; `scripts/bootstrap_toolbox_project.sh`. | `rg -n "--packs=inventory,data-core,save-core|--packs=quest,data-core,save-core,rules-events-core|--packs=ai-behavior|--packs=save-state-lite" README.md docs/maintenance-workflow.md` must show missing or stale examples before edit. | `python3 scripts/pack_manifest.py report --packs=inventory,data-core,save-core`; repeat for quest, ai-behavior, save-state-lite. | Dry-run commands and expected dependencies match current manifest output. | Stop if manifest report does not support the documented pack set or dependency wording. | `docs: harden RPG optional pack recipes` | `false` |
| `RPG-I02` | `B0-integration-hardening` | Explicit conflict validation for `save-state-lite,save-core`. | `scripts/verify_specialized_pack_candidates.sh`; optional helper in `scripts/verify_pack_matrix.sh`. | `scripts/verify_specialized_pack_candidates.sh`; `scripts/bootstrap_toolbox_project.sh`. | Run conflict selection before assertion and capture missing/unclear failure message. | `bash scripts/verify_specialized_pack_candidates.sh` and direct bootstrap conflict command fail with a clear `save-state-lite` / `save-core` conflict message. | Verification output proves conflict is enforced and understandable. | Stop if bootstrap allows both packs or emits only a generic failure. | `test: enforce RPG save pack conflict` | `false` |
| `RPG-I03` | `B0-integration-hardening` | License and NOTICE summary for new vendored RPG packs. | `packs/inventory/README.md`; `packs/quest/README.md`; `packs/ai-behavior/README.md`; `packs/save-state-lite/README.md`; optional `docs/vendor-license-inventory.md`. | `scripts/verify_specialized_pack_candidates.sh`; `rg` license checks. | `rg -n "License|NOTICE|GLoot|QuestSystem|Beehave|SaveState Lite" packs/{inventory,quest,ai-behavior,save-state-lite}/README.md docs` identifies gaps. | `bash scripts/verify_specialized_pack_candidates.sh`; `rg` confirms source, license, version, and local path for all four packs. | Each vendored RPG pack has source URL, locked version, license/NOTICE summary, and local path. | Stop if upstream license cannot be identified from vendored source or lock file. | `docs: record RPG vendor license inventory` | `false` |
| `RPG-I04` | `B0-integration-hardening` | SaveState Lite ResourceUID patch policy. | `upstreams.lock.json`; `packs/save-state-lite/README.md`; `docs/maintenance-workflow.md`. | `scripts/update_plugin_from_upstream.sh --id=savestate_lite --dry-run`; `scripts/verify_specialized_pack_candidates.sh`. | `rg -n "ResourceUID|local patch|upstream" upstreams.lock.json packs/save-state-lite/README.md docs/maintenance-workflow.md` shows missing policy. | Dry-run update docs identify the patch as either upstream-submit or locally-maintained with preservation steps. | Patch ownership and re-import/update preservation procedure are explicit. | Stop if upstream ID differs from lock file or patch path cannot be located. | `docs: define SaveState Lite patch policy` | `false` |
| `RPG-I05` | `B0-integration-hardening` | Pack matrix coverage or documented local-only decision. | `scripts/verify_pack_matrix.sh`; `.github/workflows/*` if CI matrix changes; `docs/maintenance-workflow.md`. | `scripts/verify_pack_matrix.sh`. | `bash scripts/verify_pack_matrix.sh --all` must expose missing RPG rows or documented local-only exclusions before edit. | `bash scripts/verify_pack_matrix.sh --all` covers all accepted RPG rows and documents any intentionally local-only row. | Matrix evidence proves new pack combinations are either CI-covered or explicitly excluded with cost reason. | Stop if a runtime-cost exclusion lacks a replacement local verification command. | `ci: expand RPG pack matrix coverage` | `false` |
| `RPG-C01` | `B1-rpg-core-tdd` | `rpg-core` pack manifest and folder scaffold. | `packs.manifest.json`; `packs/rpg-core/README.md`; `packs/rpg-core/godot/addons/godot_toolbox_architecture/rpg_core/rpg_core.gd`; `scripts/verify_rpg_core_pack.sh`. | `scripts/verify_rpg_core_pack.sh`. | Remove or withhold manifest entry in a branch-local red step and verify bootstrap cannot select `rpg-core`. | `python3 scripts/pack_manifest.py validate`; `bash scripts/verify_rpg_core_pack.sh`. | Manifest validates and bootstrap overlays `rpg-core` with `data-core` and `save-core`. | Stop if pack overlays without required dependencies or autoload/class names are unstable. | `feat: add rpg-core pack contract` | `true` |
| `RPG-C02` | `B1-rpg-core-tdd` | `StatBlock` and stat modifier implementation. | `packs/rpg-core/godot/addons/godot_toolbox_architecture/rpg_core/stats/*.gd`. | `packs/rpg-test-kit/godot/addons/godot_toolbox_architecture/rpg_test_kit/tests/test_stat_block.gd`; `scripts/verify_rpg_core_pack.sh`. | Add stat calculation tests first; `bash scripts/verify_rpg_core_pack.sh` must fail on missing `StatBlock` or wrong totals. | `bash scripts/verify_rpg_core_pack.sh` passes deterministic base/additive/multiplicative/derived stat tests. | Test output proves deterministic stat calculation and modifier order. | Stop if modifier stacking order is ambiguous or not documented in code/tests. | `feat: implement RPG stat blocks` | `false` |
| `RPG-C03` | `B1-rpg-core-tdd` | `LevelCurve` thresholds and reward application. | `packs/rpg-core/godot/addons/godot_toolbox_architecture/rpg_core/progression/*.gd`. | `packs/rpg-test-kit/.../tests/test_level_curve.gd`; `scripts/verify_rpg_core_pack.sh`. | Add tests for one-level, multi-level, and max-level behavior before implementation; expect failure. | `bash scripts/verify_rpg_core_pack.sh` passes progression tests. | Evidence covers level-up, multi-level gain, and max-level clamp. | Stop if XP threshold semantics conflict with reward application. | `feat: implement RPG level curves` | `false` |
| `RPG-C04` | `B1-rpg-core-tdd` | `CharacterData` static definition and `CharacterState` runtime state. | `packs/rpg-core/.../characters/character_data.gd`; `packs/rpg-core/.../characters/character_state.gd`. | `packs/rpg-test-kit/.../tests/test_character_state.gd`. | Add mutation isolation test first; expect static data to mutate or class to be missing. | `bash scripts/verify_rpg_core_pack.sh` passes character data/state tests. | Runtime HP/MP/XP/status changes do not mutate static character definition. | Stop if data/state split requires Resource duplication policy not yet specified. | `feat: implement RPG character state` | `false` |
| `RPG-C05` | `B1-rpg-core-tdd` | `PartyState` and `Wallet`. | `packs/rpg-core/.../party/party_state.gd`; `packs/rpg-core/.../party/wallet.gd`. | `packs/rpg-test-kit/.../tests/test_party_wallet.gd`. | Add add/remove member and currency constraint tests first; expect failure. | `bash scripts/verify_rpg_core_pack.sh` passes party roster and wallet mutation tests. | Evidence covers active/reserve roster, member removal, and non-negative currency constraints. | Stop if party ordering or active-member limit is not defined. | `feat: implement RPG party and wallet` | `false` |
| `RPG-C06` | `B1-rpg-core-tdd` | Item/equipment reference contracts independent of GLoot internals. | `packs/rpg-core/.../items/item_ref.gd`; `packs/rpg-core/.../equipment/equipment_slot.gd`; `packs/rpg-core/.../equipment/equipment_loadout.gd`. | `packs/rpg-test-kit/.../tests/test_equipment_contracts.gd`. | Add stable ID and slot compatibility tests first; expect missing class/failure. | `bash scripts/verify_rpg_core_pack.sh` passes item/equipment contract tests. | Stable IDs and equipment slot compatibility are verified without GLoot runtime. | Stop if references leak third-party GLoot class names into core state. | `feat: implement RPG item equipment contracts` | `false` |
| `RPG-C07` | `B1-rpg-core-tdd` | Optional GLoot adapter boundary. | `packs/rpg-core/godot/addons/godot_toolbox_architecture/rpg_core/adapters/gloot_adapter.gd`; optional adapter docs. | `scripts/verify_rpg_core_pack.sh`; adapter smoke with `inventory,data-core,save-core,rpg-core`. | Add adapter tests selecting inventory pack first; expect failure without adapter. | Adapter test passes with `inventory,data-core,save-core,rpg-core`; core smoke still passes without inventory. | Adapter maps project-owned refs to GLoot objects without making GLoot a core dependency. | Stop if adapter requires `inventory` for default `rpg-core` bootstrap. | `feat: add RPG GLoot adapter boundary` | `false` |
| `RPG-B01` | `B2-rpg-battle-core-tdd` | `rpg-battle-core` pack manifest and folder scaffold. | `packs.manifest.json`; `packs/rpg-battle-core/README.md`; `packs/rpg-battle-core/godot/addons/godot_toolbox_architecture/rpg_battle_core/rpg_battle_core.gd`; `scripts/verify_rpg_battle_core_pack.sh`. | `scripts/verify_rpg_battle_core_pack.sh`. | Branch-local selection without manifest entry must fail before scaffold is accepted. | `python3 scripts/pack_manifest.py validate`; `bash scripts/verify_rpg_battle_core_pack.sh`. | Manifest validates and bootstrap overlays battle pack with `rpg-core`, `flow-core`, and `rules-events-core`. | Stop if battle pack can load without required core/event/flow dependencies. | `feat: add rpg-battle-core pack contract` | `true` |
| `RPG-B02` | `B2-rpg-battle-core-tdd` | `CombatantState` runtime projection. | `packs/rpg-battle-core/.../combat/combatant_state.gd`. | `packs/rpg-test-kit/.../tests/test_combatant_state.gd`. | Add initialization/death/status tests first; expect missing class/failure. | `bash scripts/verify_rpg_battle_core_pack.sh` passes combatant projection tests. | HP/MP/status initialization and KO/death checks are deterministic. | Stop if enemy data source is undefined. | `feat: implement RPG combatant state` | `false` |
| `RPG-B03` | `B2-rpg-battle-core-tdd` | `BattleSession` state machine. | `packs/rpg-battle-core/.../battle/battle_session.gd`. | `packs/rpg-test-kit/.../tests/test_battle_session.gd`; fixed smoke scene/script. | Add fixed smoke battle test first; expect no victory or missing session. | `bash scripts/verify_rpg_battle_core_pack.sh` completes a deterministic victory smoke. | Session tracks party, enemies, turn phase, log, and outcome. | Stop if battle session mutates source character data directly. | `feat: implement RPG battle session` | `false` |
| `RPG-B04` | `B2-rpg-battle-core-tdd` | Deterministic `TurnQueue`. | `packs/rpg-battle-core/.../battle/turn_queue.gd`. | `packs/rpg-test-kit/.../tests/test_turn_queue.gd`. | Add tie-break and repeatability tests first; expect failure. | Turn queue tests pass across repeated runs. | Evidence covers speed ordering, priority hook, and stable tie-break. | Stop if randomness enters queue without seeded replay control. | `feat: implement RPG turn queue` | `false` |
| `RPG-B05` | `B2-rpg-battle-core-tdd` | `BattleAction`, `SkillAction`, and `ItemAction`. | `packs/rpg-battle-core/.../actions/*.gd`. | `packs/rpg-test-kit/.../tests/test_battle_actions.gd`. | Add valid/invalid selection and cost tests first; expect failure. | Action tests pass and battle smoke still completes. | Actions are UI-independent and enforce MP/item/cooldown constraints. | Stop if action validation needs inventory semantics not yet in adapter. | `feat: implement RPG battle actions` | `false` |
| `RPG-B06` | `B2-rpg-battle-core-tdd` | `TargetRule` legality. | `packs/rpg-battle-core/.../targeting/target_rule.gd`. | `packs/rpg-test-kit/.../tests/test_target_rules.gd`. | Add single/all/self/random target tests first; expect failure. | Target rule tests pass with deterministic random target under seed. | Evidence covers legal target sets and invalid selection rejection. | Stop if random targeting cannot be replayed deterministically. | `feat: implement RPG target rules` | `false` |
| `RPG-B07` | `B2-rpg-battle-core-tdd` | `DamageFormula` for damage and healing. | `packs/rpg-battle-core/.../formula/damage_formula.gd`. | `packs/rpg-test-kit/.../tests/test_damage_formula.gd`. | Add clamp/defense/heal tests first; expect failure. | Formula tests pass and smoke battle result remains deterministic. | Evidence covers physical/magical damage, defense, healing, and min/max clamp. | Stop if formula uses undefined stats from `rpg-core`. | `feat: implement RPG damage formula` | `false` |
| `RPG-B08` | `B2-rpg-battle-core-tdd` | `BattleResult` and `RewardGrant`. | `packs/rpg-battle-core/.../results/*.gd`; `packs/rpg-core/.../party` integration if needed. | `packs/rpg-test-kit/.../tests/test_battle_rewards.gd`. | Add reward application tests first; expect no XP/gold/item application. | Reward tests pass and party state reflects result. | Evidence covers outcome, XP, gold, and item reward application. | Stop if reward application conflicts with save adapter schema. | `feat: implement RPG battle rewards` | `false` |
| `RPG-B09` | `B2-rpg-battle-core-tdd` | Simple deterministic enemy AI policy. | `packs/rpg-battle-core/.../ai/deterministic_enemy_ai.gd`. | `packs/rpg-test-kit/.../tests/test_enemy_ai_replay.gd`. | Add replay action sequence fixture first; expect mismatch or missing policy. | Replay produces identical enemy action sequence across repeated runs. | Evidence shows non-Beehave AI can drive first-pass turn-based combat. | Stop if AI depends on Beehave or non-seeded randomness. | `feat: implement deterministic RPG enemy AI` | `false` |
| `RPG-B10` | `B2-rpg-battle-core-tdd` | Optional Beehave adapter design and boundary. | `packs/rpg-battle-core/.../adapters/beehave_ai_adapter.gd`; adapter boundary docs. | Optional smoke with `ai-behavior,rpg-battle-core,...`; default battle smoke without Beehave. | Add default no-Beehave smoke and optional adapter presence test first; expect missing adapter. | Default `bash scripts/verify_rpg_battle_core_pack.sh` passes without Beehave; optional adapter smoke passes when selected. | Adapter is optional and cannot block default battle core. | Stop if battle core imports Beehave in default path. | `feat: add optional Beehave RPG adapter` | `false` |
| `RPG-S01` | `B3-rpg-save-adapter-tdd` | RPG state serializer/deserializer to `save-core` snapshot payload. | `packs/rpg-save-adapter/**` or `packs/rpg-core/.../save_adapter/*.gd`; `packs.manifest.json` if subpack. | `packs/rpg-test-kit/.../tests/test_rpg_save_roundtrip.gd`; `scripts/verify_rpg_test_kit_pack.sh`. | Add roundtrip tests for party/gold/levels/inventory/equipment first; expect failure. | Save roundtrip tests pass through `save-core` snapshot shape. | Party, gold, levels, inventory refs, and equipment refs survive serialize/deserialize. | Stop if adapter writes live Resource objects instead of explicit dictionaries. | `feat: implement RPG save adapter` | `false` |
| `RPG-S02` | `B3-rpg-save-adapter-tdd` | RPG save schema version and migration stub. | `packs/rpg-save-adapter/.../rpg_save_schema.gd`; migration docs. | `packs/rpg-test-kit/.../tests/test_rpg_save_migrations.gd`. | Add malformed payload and old-version tests first; expect acceptance of bad payloads. | Migration tests reject malformed payloads and migrate supported old version. | Versioned dictionary shape and migration stub are verified. | Stop if schema version is not stored inside payload. | `feat: version RPG save schema` | `false` |
| `RPG-S03` | `B3-rpg-save-adapter-tdd` | Inventory/equipment save adapter independent of GLoot runtime unless selected. | `packs/rpg-save-adapter/.../inventory_equipment_save_adapter.gd`; optional GLoot bridge. | `packs/rpg-test-kit/.../tests/test_inventory_equipment_save.gd`. | Add no-GLoot roundtrip and optional GLoot bridge tests first; expect failure. | Roundtrip passes without GLoot; optional bridge passes with `inventory` selected. | Stable item/equipment refs persist without third-party runtime dependency. | Stop if default save adapter requires `inventory`. | `feat: save RPG inventory equipment state` | `false` |
| `RPG-S04` | `B3-rpg-save-adapter-tdd` | Quest state save adapter through `rules-events-core` and `save-core`. | `packs/rpg-save-adapter/.../quest_save_adapter.gd`; optional QuestSystem bridge. | `packs/rpg-test-kit/.../tests/test_quest_save_adapter.gd`. | Add quest-selected roundtrip test first; expect missing adapter/failure. | Quest state roundtrip passes with `quest,data-core,save-core,rules-events-core,rpg-save-adapter`. | Quest progress mapping is explicit and serializable. | Stop if QuestSystem state shape cannot be observed without plugin internals. | `feat: save RPG quest state` | `false` |
| `RPG-U01` | `B4-rpg-ui-content` | Minimal battle scene. | `packs/rpg-battle-core/godot/scenes/rpg_battle/battle_root.tscn`; related scene script. | `packs/rpg-test-kit/.../ui/test_battle_scene_smoke.gd`; headless import smoke. | Add UI tree smoke first; expect missing scene or controls. | Headless import succeeds and UI tree smoke finds party panel, enemy panel, command area. | `BattleRoot` scene is importable and structurally observable. | Stop if scene requires editor-only plugins to import. | `feat: add RPG battle scene` | `false` |
| `RPG-U02` | `B4-rpg-ui-content` | Battle HUD scripts and controls. | `packs/rpg-battle-core/godot/scenes/rpg_battle/battle_hud.gd`; HUD scene nodes. | `packs/rpg-test-kit/.../ui/test_battle_hud_state.gd`. | Add HUD state text/bar update test first; expect missing bindings. | UI smoke verifies HP/MP bars, turn indicator, and log update. | Visible controls reflect battle state transitions. | Stop if HUD cannot update from `BattleSession` without tight coupling. | `feat: add RPG battle HUD` | `false` |
| `RPG-U03` | `B4-rpg-ui-content` | Skill menu. | `packs/rpg-battle-core/godot/scenes/rpg_battle/skill_menu.tscn`; `skill_menu.gd`. | `packs/rpg-test-kit/.../ui/test_skill_menu.gd`. | Add insufficient-MP disabled-state and selection test first; expect failure. | UI test selects one skill and validates disabled state for insufficient MP. | Skill list, disabled state, and target prompt are observable. | Stop if skill data source is not stable. | `feat: add RPG skill menu` | `false` |
| `RPG-U04` | `B4-rpg-ui-content` | Item menu. | `packs/rpg-battle-core/godot/scenes/rpg_battle/item_menu.tscn`; `item_menu.gd`. | `packs/rpg-test-kit/.../ui/test_item_menu.gd`. | Add item consumption and HP change test first; expect failure. | UI test consumes an item and verifies HP/state delta. | Consumable item list and use action are wired to battle state. | Stop if inventory ownership is ambiguous between core refs and GLoot. | `feat: add RPG item menu` | `false` |
| `RPG-U05` | `B4-rpg-ui-content` | Equipment and party management UI. | `packs/rpg-core/godot/scenes/rpg_party/*.tscn`; `packs/rpg-core/godot/scenes/rpg_party/*.gd`. | `packs/rpg-test-kit/.../ui/test_party_equipment_ui.gd`. | Add UI smoke for equipment stat change first; expect missing scene/action. | UI smoke changes equipment and verifies stat output changes. | Minimal loadout and active party management are usable. | Stop if stat contribution cannot be traced to `EquipmentLoadout`. | `feat: add RPG party equipment UI` | `false` |
| `RPG-U06` | `B4-rpg-ui-content` | Example heroes, enemies, skills, items, and equipment. | `packs/rpg-core/godot/content/rpg_example/**`; `packs/rpg-battle-core/godot/content/rpg_example/**`. | Fixed battle smoke and content manifest validation. | Add content count and fixed battle tests first; expect missing data. | Fixed battle smoke uses at least two heroes, three enemies, five skills, five items, and three equipment pieces. | Real example content drives a deterministic battle. | Stop if sample data bypasses public core/battle APIs. | `feat: add RPG example content` | `false` |
| `RPG-T01` | `B5-rpg-test-observability` | `rpg-test-kit` fixtures for core, battle, save, and UI smoke. | `packs/rpg-test-kit/**`; `scripts/verify_rpg_test_kit_pack.sh`. | Core/battle/save/UI test fixture files under `packs/rpg-test-kit`. | Run pack verifier after writing tests but before implementations; expect targeted failures. | `bash scripts/verify_rpg_test_kit_pack.sh` passes with all fixture categories. | Pack-local verification proves fixtures cover RPG core, battle, save, and UI smoke. | Stop if test-kit only reports readiness scaffold. | `test: expand RPG test kit fixtures` | `false` |
| `RPG-T02` | `B5-rpg-test-observability` | Deterministic battle replay fixture. | `packs/rpg-test-kit/.../replay/*.json`; replay runner script/GDScript. | `packs/rpg-test-kit/.../tests/test_battle_replay.gd`. | Add replay compare test first; expect mismatch or missing runner. | Replay command runs twice and produces identical event/action output. | Input/action trace and expected event log are stable. | Stop if any replay field depends on wall-clock time. | `test: add deterministic RPG battle replay` | `false` |
| `RPG-T03` | `B5-rpg-test-observability` | Combat event stream. | `packs/rpg-battle-core/.../events/combat_event_stream.gd`; event schemas. | `packs/rpg-test-kit/.../tests/test_combat_event_stream.gd`. | Add ordered event payload assertions first; expect missing events. | Event stream tests assert order and payload shape. | Events cover action selected, damage, heal, KO, reward, and save boundary. | Stop if event payloads cannot be serialized for replay/state dump. | `feat: add RPG combat event stream` | `false` |
| `RPG-T04` | `B5-rpg-test-observability` | State dump for AI/manual verification. | `packs/rpg-test-kit/.../dump/rpg_state_dump.gd`; optional CLI wrapper. | JSON schema smoke for battle, party, inventory, and save payload dump. | Add dump schema test first; expect missing dump or invalid JSON. | State dump test emits valid JSON inspectable without debugger. | AI/manual audit can inspect battle state, party state, inventory, and save payload. | Stop if dump omits state needed to reproduce battle/save defects. | `test: add RPG state dump evidence` | `false` |
| `RPG-T05` | `B5-rpg-test-observability` | Acceptance matrix for `RPG-ready shell` and `complete RPG template`. | `docs/rpg-acceptance-matrix.md`; README claim updates. | `scripts/check_rpg_readiness.py` may be narrowed or replaced; `rg` claim checks. | `rg -n "RPG-ready shell|complete RPG template|Completion language" docs README.md` reveals missing or overbroad claim boundaries. | Claim checks prove README language does not exceed evidence layer. | Evidence requirements and allowed completion language are documented. | Stop if README claims completion before UI/save/replay evidence exists. | `docs: define RPG acceptance matrix` | `false` |
| `RPG-D01` | `B6-doc-governance` | RPG template README section. | `README.md`; `docs/rpg-template-absorption-plan.md`. | `rg` docs checks. | `rg -n "RPG template|rpg-template-absorption-plan|rpg-core|rpg-battle-core" README.md` identifies missing or stale language. | README links to plan and pack docs with current implementation status. | User-facing explanation distinguishes available packs from remaining self-owned implementation. | Stop if README language claims complete RPG template without evidence. | `docs: update RPG template README` | `false` |
| `RPG-D02` | `B6-doc-governance` | RPG pack selection recipes. | `docs/rpg-pack-recipes.md`; `README.md`; `docs/maintenance-workflow.md`. | Dry-run recipe commands. | Add recipe command checks before docs finalization; expect unsupported packs or stale dependencies. | Dry-run report commands work for minimal RPG battle, inventory, quest, and behavior AI recipes. | Recipes are executable and match manifest dependencies/conflicts. | Stop if any recipe requires packs not yet in manifest. | `docs: add RPG pack recipes` | `false` |
| `RPG-D03` | `B6-doc-governance` | Source boundary docs for every adapter. | `docs/rpg-adapter-boundaries.md`; pack READMEs. | `rg` boundary checks; adapter tests from `B1` to `B3`. | `rg -n "source boundary|state ownership|save ownership" docs packs/*/README.md` shows missing boundary statements. | Boundary docs cover GLoot, Beehave, QuestSystem, SaveState Lite, and save-core mapping. | Each adapter records source API boundary, state ownership, and save ownership. | Stop if docs assign project truth to third-party plugin internals. | `docs: document RPG adapter boundaries` | `false` |
| `RPG-D04` | `B6-doc-governance` | Vendored RPG pack upgrade checklist. | `docs/rpg-vendor-upgrade-checklist.md`; `docs/maintenance-workflow.md`; pack READMEs. | `scripts/update_plugin_from_upstream.sh --id=... --dry-run` examples. | Run or document dry-run commands for all four upstream IDs; expect missing IDs or stale docs. | Dry-run examples are documented for GLoot, QuestSystem, Beehave, and SaveState Lite, including patch preservation. | Upgrade checklist covers update, import, conflict, license, smoke, and patch steps. | Stop if any upstream lock ID is unknown or upgrade path is unsafe. | `docs: add RPG vendor upgrade checklist` | `false` |

## Acceptance And Observability Matrix

Target claim:

- `RPG-ready shell`: opt-in packs bootstrap, first-party RPG core/battle/save contracts run, one complete deterministic battle can grant rewards, save, reload, and preserve party state.
- `complete RPG template`: `RPG-ready shell` plus battle UI scenes, skill/item/equipment/party UI, real example content, replay/state dump/event stream evidence, and end-to-end sample flow.

Required layer:

- `RPG-ready shell` requires `Runtime`.
- `complete RPG template` requires `Interaction`.
- Any user-facing "playable" claim requires `Experience` review evidence in addition to automated `Interaction` checks.

Actors:

- CI runner decides whether pack manifests, bootstrap, import, test, replay, save, and matrix checks pass.
- AI observer decides whether UI tree, state dump, event stream, and replay evidence are sufficient to debug failures.
- Human reviewer decides whether sample content and UI are understandable enough for a template.
- Maintainer decides whether vendored upstream updates preserve licenses, patches, and conflicts.

Automation coverage:

- Manifest validation, bootstrap dry-run reports, pack conflict tests, Godot headless import, core/battle/save tests, deterministic replay comparison, event stream assertions, JSON state dump validation, and dry-run recipe checks.

Human/AI-assisted coverage:

- UI layout readability, battle HUD clarity, menu affordance clarity, example content usefulness, and final README claim wording require reviewer notes with screenshots or UI-tree/state-dump evidence.

Observability available:

- Current repository has pack manifests, bootstrap scripts, specialized pack verification, pack matrix verification, and readiness scaffold checks.

Observability missing:

- Full combat event stream, battle replay artifact, RPG state dump, UI tree smoke evidence, save roundtrip artifact, and final cleanup receipt are not yet implemented.

Implementation tasks before acceptance:

- Complete `RPG-T02`, `RPG-T03`, and `RPG-T04` before using replay/state dump/event stream as acceptance evidence.
- Complete `RPG-U01` to `RPG-U06` before claiming complete RPG template.
- Complete `RPG-S01` to `RPG-S04` before claiming save/reload preservation.

Completion language allowed:

- Before `B1` to `B5` are green: "RPG optional pack absorption and scaffold planning exist."
- After `B1` to `B3` are green: "RPG runtime contracts and save adapter pass targeted checks."
- After `B4` and `B5` are green: "RPG-ready shell evidence exists" if save/reload/reward checks pass.
- Only after `B6` and `B7` are green: "complete RPG template evidence exists" if UI/content/replay/state dump and human/AI-assisted review receipts exist.

## Vibe Boundary Decision

Vibe is not the source of this implementation plan. The repository plan above is the execution authority for task coverage, write scopes, red/green checks, and completion evidence.

Allowed Vibe use later:

- Record a cleanup / acceptance wrapper after a batch already has repository verification evidence.
- Attach Vibe receipts to `docs/rpg-execution-verification-log.md` as secondary governance artifacts.
- Reject or revise any Vibe plan that lacks this task matrix, concrete write scopes, exact commands, failure boundaries, and cleanup receipts.

Disallowed Vibe use:

- Generating a replacement plan that only restates revision deltas.
- Treating Vibe readiness, `planned_contracts`, or one sentinel metric as implementation completion.
- Dispatching noisy unrelated specialists into RPG implementation write scopes.
