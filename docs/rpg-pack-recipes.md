# RPG Pack Recipes

These recipes are executable dry-run entrypoints for RPG project assembly. Use them before generating a real project so dependencies, autoloads, project settings, verification entries, and conflicts are visible.

For the minimal productized RPG template path, start with `docs/rpg-template-quickstart.md`; this page keeps the individual pack combination recipes.

## Minimal RPG Battle Shell

```bash
./scripts/bootstrap_toolbox_project.sh ../godot-toolbox-rpg-preview \
  --packs=rpg-battle-core,rpg-core,rpg-save-adapter,rpg-test-kit,flow-core,rules-events-core,data-core,save-core \
  --dry-run-report
```

Use when a project needs first-party RPG state, deterministic battle runtime, save mapping, UI/content smoke, replay, event stream, and state dump evidence.

Expected boundaries:

- RPG state truth stays in `rpg-core`.
- Battle truth stays in `rpg-battle-core`.
- Save truth maps through `rpg-save-adapter` and `save-core`.

## RPG With Inventory Authoring

```bash
./scripts/bootstrap_toolbox_project.sh ../godot-toolbox-rpg-preview \
  --packs=inventory,data-core,save-core,rpg-core,rpg-save-adapter,rules-events-core \
  --dry-run-report
```

Use when a project wants GLoot authoring/runtime primitives while keeping stable item refs and save payloads first-party.

## RPG With Quest Authoring

```bash
./scripts/bootstrap_toolbox_project.sh ../godot-toolbox-rpg-preview \
  --packs=quest,data-core,save-core,rules-events-core,rpg-save-adapter,rpg-core \
  --dry-run-report
```

Use when a project wants QuestSystem resources while mapping quest progress through `rules-events-core` and `rpg-save-adapter`.

## RPG With Behavior-Tree AI

```bash
./scripts/bootstrap_toolbox_project.sh ../godot-toolbox-rpg-preview \
  --packs=ai-behavior,rpg-battle-core,rpg-core,flow-core,rules-events-core,data-core,save-core \
  --dry-run-report
```

Use when project enemy/NPC AI needs Beehave behavior-tree authoring. The default battle core still works without Beehave.

## SaveState Lite As Alternative Save Tooling

```bash
./scripts/bootstrap_toolbox_project.sh ../godot-toolbox-rpg-preview \
  --packs=save-state-lite \
  --dry-run-report
```

`save-state-lite` conflicts with `save-core`; do not combine it with the default RPG save path unless one side is adapted or namespaced.
