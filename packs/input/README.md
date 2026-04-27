# Input Optional Pack

This pack vendors `G.U.I.D.E` as an opt-in input workflow addon.

Current boundaries:

- `default=false`
- Not included in default bootstrap
- Selected explicitly with `--packs=input`
- Provides the `guide` editor plugin and `GUIDE` autoload
- Does not own gameplay input semantics, save truth, or project-specific action maps

## Bootstrap

```bash
./scripts/bootstrap_toolbox_project.sh /path/to/new-project --packs=input
```

This copies `addons/guide`, enables `res://addons/guide/plugin.cfg`, injects:

```text
GUIDE="*res://addons/guide/guide.gd"
```

and writes:

```text
godot_toolbox/input/enabled=true
```

## Verification

```bash
bash ./scripts/verify_input_pack_poc.sh
```

The verification checks the locked upstream metadata, default bootstrap exclusion, opt-in bootstrap injection, and a Godot headless import of the generated project.
