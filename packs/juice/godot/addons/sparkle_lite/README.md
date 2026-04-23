# Sparkle Lite

A free, drop-in game-feel ("juice") plugin for **Godot 4.6**. Author layered feedback sequences — camera shakes, hit pauses, screen flashes, audio one-shots, scale punches, and gameplay hooks — directly in the inspector, then fire them from code with a single `play()` call.

GDScript only. Zero dependencies. Seven feedback types. One `FeedbackPlayerLite` node that ties them together.

```gdscript
$FeedbackPlayer.play()           # fire the full authored sequence
$FeedbackPlayer.play(1.8)        # same sequence at 1.8x intensity
```

---

## Why Sparkle Lite?

Game feel lives in the small stuff — the shake when you fire, the freeze on impact, the flash when you get hit. Wiring each of those things ad-hoc adds up quickly and buries your gameplay code under timers and tweens.

Sparkle Lite gives you:

- **A single player node** (`FeedbackPlayerLite`) that owns an ordered list of feedback resources.
- **A custom inspector** with live preview, drag-reorder, copy/paste, per-feedback enable/disable, and saved preset `.tres` files.
- **Seven shippable feedback types** covering 2D and 3D games.
- **Resource-based** — feedbacks are `Resource` subclasses, so they save as `.tres`, diff cleanly in version control, and can be composed into reusable presets.
- **Runtime API** for anything you can't (or don't want to) author in the inspector.

---

## Install

1. Copy the `addons/sparkle_lite/` folder into your project's `addons/` directory.
2. Open **Project → Project Settings → Plugins** and enable **Sparkle Lite**.
3. Done. A `FeedbackPlayerLite` is now available from the "Add Node" dialog.

The plugin requires Godot **4.6+** and uses no native extensions.

---

## Quick start (60 seconds)

1. Add a `FeedbackPlayerLite` node to your scene.
2. Select it. In the inspector, click **+ Add Feedback** and pick **Camera Shake**.
3. Press the **Preview** button on the shake row to see it in the viewport.
4. Call `play()` from your gameplay code:

```gdscript
@onready var feedback: FeedbackPlayerLite = $FeedbackPlayer

func _on_enemy_hit() -> void:
    feedback.play()
```

Every feedback has its own `delay_ms`, so stacking a **Camera Shake** at 0 ms and a **Hit Pause** at 50 ms in the same player gives you a full juicy hit reaction from one `play()` call.

---

## The seven feedbacks

| # | Type | What it does |
|---|------|--------------|
| 1 | **Camera Shake** | Layered-noise positional + rotational shake on a `Camera3D`. Per-axis amplitudes, smooth/chaotic noise blend, distance falloff. |
| 2 | **Camera Shake 2D** | Same shake for `Camera2D` — pixel amplitudes, degree rotation, distance falloff in pixels. |
| 3 | **Hit Pause** | Drops `Engine.time_scale` briefly for hit-stop. Lowest-wins stacking, 500 ms safety cap. |
| 4 | **Screen Flash 2D** | Full-viewport colour flash on a persistent `CanvasLayer`. `MODULATE` or `ADD` blend. |
| 5 | **Audio** | `AudioStreamPlayer2D`/`3D` one-shots with pitch randomisation. `POOL` / `CACHE` / `ONE_TIME` allocation. |
| 6 | **Scale Punch** | Elastic scale pop on any `Node2D`, `Node3D`, or `Control`. Last-starts-wins per target. |
| 7 | **Call** | Calls a method or emits a signal on a target node at its place in the timeline. Bridge to your gameplay code. |

Each feedback is documented in full in the `documentation/` folder (see below).

---

## Documentation

The **[documentation/](documentation/)** folder has:

- **[Getting Started](documentation/getting_started.md)** — the hands-on tutorial.
- **[Authoring in the inspector](documentation/authoring_in_inspector.md)** — how to use the custom UI (preview, copy/paste, drag-reorder, presets).
- **[Runtime API](documentation/runtime_api.md)** — building players and feedbacks from pure code.
- **[Feedback reference](documentation/feedbacks/)** — one page per feedback type with every exported property and the common recipes.
- **[Presets & the autoload](documentation/presets_and_autoload.md)** — using `SparkleLitePresets` to trigger named feedback stacks from anywhere.

---

## Samples

The plugin ships with a runnable sample hub at `addons/sparkle_lite/samples/sparklelite_main.tscn`. Open it in Godot 4.6 and press **F5** — the main menu lists nine scenes, one per feedback plus a combined sequence and a pure-code example.

| Scene | Demonstrates |
|-------|-------------|
| 01 · Camera Shake | `Camera3D` shake on a soldier target |
| 02 · Camera Shake 2D | `Camera2D` shake on a candy grid |
| 03 · Hit Pause | `Engine.time_scale` drop with a spinning rig that freezes |
| 04 · Screen Flash 2D | Colour flashes with `MODULATE` vs `ADD` blend |
| 05 · Audio | Pooled one-shots with pitch randomisation |
| 06 · Scale Punch | Elastic scale pops on sprites and Controls |
| 07 · Call | Bridging a feedback timeline to gameplay methods and signals |
| 08 · Combined Juicy Shot | All six feedback types in one `play()` |
| 09 · Full Runtime API | Building players, feedbacks, and presets in pure code |

Each scene script is commented top-to-bottom and highlights the exact API calls it uses.

---

## Upgrade to the full Sparkle

Sparkle Lite is the free edition. The full **[Sparkle](https://neohex-interactive.itch.io/sparkle)** plugin on itch.io ships with:

- **33 feedback types** — particle bursts, decal bursts, typewriter, floating text, post-processing pulses, curve-driven transforms, and more.
- **Container feedbacks** — group, loop, conditional, random-one-of, weighted-random.
- **Every feature here** plus a richer inspector and a wider preset library.

If Sparkle Lite is saving you work, consider grabbing the full edition — it's the only reason this free version exists.

---

## License

Sparkle Lite is released under the **MIT License** — use, modify, and redistribute freely, in personal or commercial projects. See [LICENSE.md](LICENSE.md) for the full terms.

## Credits

Built by **Neohex Interactive**. Soldier model used in the 3D demos is a placeholder asset shipped with this demo — replace it with your own before exporting.
