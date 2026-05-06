# RPG Vendor License And NOTICE Summary

This file records license, NOTICE, local target, and patch policy details for RPG-related vendored optional packs. These packs remain non-default and are selected explicitly through `--packs=...`.

This file covers vendored functional packs, not external art/audio candidates. RPG demo art/audio sources are tracked separately in `docs/rpg-art-asset-sources.md` until a concrete asset pack is imported.

## Summary

| Pack | Upstream | Version | Local target | License | NOTICE summary |
| --- | --- | --- | --- | --- | --- |
| `inventory` | `GLoot` at <https://github.com/peter-kish/gloot> | `v3.0.1` | `packs/inventory/godot/addons/gloot` | MIT | No separate NOTICE file is vendored in the selected `addons/gloot` subtree. Preserve upstream attribution in pack docs and lock metadata. |
| `quest` | `QuestSystem` at <https://github.com/shomykohai/quest-system> | `2.0.1.4_4` | `packs/quest/godot/addons/quest_system` | MIT | Vendored subtree includes `LICENSE`; no separate NOTICE file is required by the current subtree. |
| `ai-behavior` | `Beehave` at <https://github.com/bitbrain/beehave> | `v2.9.2` | `packs/ai-behavior/godot/addons/beehave` | MIT | Vendored subtree includes `LICENSE`; no separate NOTICE file is required by the current subtree. |
| `save-state-lite` | `SaveState Lite` at <https://github.com/youssof20/savestate> | `v1.2.0` | `packs/save-state-lite/godot/addons/savestate` | MIT | No separate NOTICE file is vendored in the selected `addons/savestate` subtree. Preserve upstream attribution in pack docs and lock metadata. |
| `dialogue` | `Dialogue Manager` at <https://github.com/nathanhoad/godot_dialogue_manager> | `v3.10.4` | `packs/dialogue/godot/addons/dialogue_manager` | MIT | No separate NOTICE file is vendored in the selected `addons/dialogue_manager` subtree. Preserve upstream attribution in pack docs and lock metadata. |

## SaveState Lite Patch Policy

`save-state-lite` carries a locally maintained patch in `packs/save-state-lite/godot/addons/savestate/editor/save_browser_dock.gd`.

Patch reason:

- Guard `ResourceUID` lookup during headless bootstrap/import so missing UID registrations fall back to the vendored Lite SaveManager path without emitting engine errors.

Policy:

- The patch is locally maintained until the upstream project accepts an equivalent guard or removes the failing `ResourceUID` lookup path.
- Any `savestate_lite` re-import or update must preserve or deliberately retire this patch.
- Retiring the patch requires a successful `save-state-lite` import smoke and an explicit verification log entry showing the upstream version no longer needs the guard.

Required dry-run before update:

```bash
./scripts/update_plugin_from_upstream.sh --id=savestate_lite --dry-run
```

Required post-update checks:

```bash
bash ./scripts/verify_specialized_pack_candidates.sh
bash ./scripts/verify_pack_matrix.sh --row=save-state-lite
```

## Upgrade Checklist

For each RPG vendored pack update:

1. Run the matching dry-run command from `docs/maintenance-workflow.md`.
2. Confirm `upstreams.lock.json` still records source URL, version/ref, local target, and source subtree.
3. Confirm this license / NOTICE summary still matches the vendored subtree.
4. Run `bash ./scripts/verify_specialized_pack_candidates.sh`.
5. Run the matching `bash ./scripts/verify_pack_matrix.sh --row=<packs>` row.
6. For `save-state-lite`, confirm the locally maintained patch policy above is still satisfied.
