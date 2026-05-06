# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-05-05

### Added

- RPG battle core contracts: CombatantState, BattleSession, TurnQueue, BattleAction,
  SkillAction, ItemAction, TargetRule, DamageFormula, BattleResult, RewardGrant,
  DeterministicEnemyAI
- RPG save adapter: schema versioning, party/inventory/equipment/quest serialization
  to save-core snapshots
- RPG UI scenes and example content for battle, party, and inventory
- RPG test kit: deterministic battle replay, combat event stream assertions, state
  dump helpers
- RPG observability verification script
- gdtoolkit lint/format check and pre-commit hooks
- gdUnit4 smoke test upgraded from placeholder to bootstrap contract checks

### Changed

- Hardened RPG optional pack integration and adapter boundaries

## [0.2.0] - 2026-04-29

### Added

- Architecture pack contracts: flow-core, simulation-core, data-core, save-core,
  flow-test-kit, rules-events-core
- RPG core domain contracts: StatBlock, CharacterData, PartyState, Wallet, ItemRef,
  EquipmentLoadout
- RPG art demo pack (first-party placeholders, no third-party assets)
- RPG pack recipes, template quickstart, and vendor upgrade checklist docs
- ai-testing pack: strategy-driven exploration, coverage tracking, bug discovery
  templates
- dialogue pack: vendored Dialogue Manager v3.10.4

## [0.1.0] - 2026-04-23

### Added

- Initial project scaffold with base template, gdUnit4, godot-gdscript-toolkit
- Manifest-driven bootstrap system (packs.manifest.json)
- Upstream import/update scripts with lock file (upstreams.lock.json)
- Optional packs: validation (Godot Doctor), debug (Signal Lens), stateful
  (Godot State Charts), juice (Sparkle Lite)
- Optional vendor packs: automation (GodotE2E), input (G.U.I.D.E), inventory (GLoot),
  quest (QuestSystem), ai-behavior (Beehave), save-state-lite (SaveState Lite)
- Plugin catalog, integration standard, selection framework, and maintenance workflow
  docs
- CI workflow with Godot 4.6.2 headless import + gdUnit4 smoke
- Continuous verification script suite

[Unreleased]: https://github.com/codefromkarl/godot-toolbox/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/codefromkarl/godot-toolbox/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/codefromkarl/godot-toolbox/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/codefromkarl/godot-toolbox/releases/tag/v0.1.0
