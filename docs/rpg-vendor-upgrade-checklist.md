# RPG Vendor Upgrade Checklist

Use this checklist before updating any vendored RPG optional pack.

## Dry-Run Commands

```bash
./scripts/update_plugin_from_upstream.sh --id=gloot --dry-run
./scripts/update_plugin_from_upstream.sh --id=quest_system --dry-run
./scripts/update_plugin_from_upstream.sh --id=beehave --dry-run
./scripts/update_plugin_from_upstream.sh --id=savestate_lite --dry-run
```

## Common Checklist

1. Confirm the target upstream version/ref is intentional.
2. Run the matching dry-run command.
3. Confirm `upstreams.lock.json` still records source URL, version/ref, source subtree, and local target.
4. Confirm `docs/rpg-vendor-license-notice.md` still matches the vendored license / NOTICE state.
5. Confirm pack README source and boundary notes still match the selected version.
6. Run `bash ./scripts/verify_specialized_pack_candidates.sh`.
7. Run the relevant matrix row with `bash ./scripts/verify_pack_matrix.sh --row=<packs>`.
8. If the update touches RPG adapters, run the relevant RPG verifier.

## Pack-Specific Rows

GLoot:

```bash
bash ./scripts/verify_pack_matrix.sh --row=inventory,data-core,save-core
bash ./scripts/verify_rpg_core_pack.sh
```

QuestSystem:

```bash
bash ./scripts/verify_pack_matrix.sh --row=quest,data-core,save-core,rules-events-core
bash ./scripts/verify_rpg_save_adapter_pack.sh
```

Beehave:

```bash
bash ./scripts/verify_pack_matrix.sh --row=ai-behavior
bash ./scripts/verify_rpg_battle_core_pack.sh
```

SaveState Lite:

```bash
bash ./scripts/verify_pack_matrix.sh --row=save-state-lite
bash ./scripts/verify_specialized_pack_candidates.sh
```

SaveState Lite has a locally maintained `ResourceUID` guard patch in `packs/save-state-lite/godot/addons/savestate/editor/save_browser_dock.gd`. Preserve it unless upstream ships an equivalent fix and the verification log records that the patch is no longer required.
