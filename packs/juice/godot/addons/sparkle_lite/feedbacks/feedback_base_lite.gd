# feedback_base.gd
# Abstract base class for every Sparkle Lite feedback type.
# Defines the shared timing/identity contract and the lifecycle hooks
# (_play, _stop, _get_default_label) that subclasses must implement.

@tool
class_name FeedbackBaseLite
extends Resource

## Abstract base resource for all Sparkle Lite feedback types.
##
## A [FeedbackBaseLite] is a pure data container plus three virtual
## hooks. Concrete subclasses (camera shake, hit pause, screen flash,
## audio, scale punch, call) carry their own parameters and provide the
## actual effect implementation. The owning [FeedbackPlayerLite] fires
## each entry in its [member FeedbackPlayerLite.feedbacks] array after
## the entry's [member delay_ms] elapses.
##
## Subclasses [b]must[/b] override [method _play], [method _stop], and
## [method _get_default_label]. They must never depend on other
## feedback types; all orchestration is the player's job.

## Developer-facing name shown in the inspector list. Defaults to the
## feedback type's display name when left blank.
@export var label: String = "":
	set(value):
		label = value

## When false, this feedback is skipped entirely — the player does not
## schedule it and emits no per-entry signal for it.
@export var enabled: bool = true

## Time in milliseconds after [method FeedbackPlayerLite.play] is called
## before this feedback starts. Stacking multiple feedbacks with
## different delays is the primary way to sequence effects.
@export_range(0.0, 10000.0, 1.0, "or_greater", "suffix:ms") \
var delay_ms: float = 0.0

## How long this feedback runs, in milliseconds. Interpretation is
## feedback-specific (shake length, pause length, flash fade-out, etc.).
@export_range(0.0, 10000.0, 1.0, "or_greater", "suffix:ms") \
var duration_ms: float = 100.0

## Per-feedback intensity multiplier. Applied on top of the player's
## default_intensity and the play-call intensity argument.
## 1.0 is the authored level; 0.0 silences this feedback.
@export_range(0.0, 4.0, 0.01) var intensity_multiplier: float = 1.0


## Starts the feedback. Called by [FeedbackPlayerLite] after
## [member delay_ms] has elapsed. Must return immediately — the effect
## unwinds on its own timer.
## [param intensity] is the combined intensity from the player
## ([code]player_intensity * player.default_intensity[/code]).
## [param player] is the owning [FeedbackPlayerLite]; subclasses use it
## to locate the scene tree, camera, or global position.
func _play(intensity: float, player: Node) -> void:
	push_warning(
		"Sparkle Lite: FeedbackBaseLite._play() must be overridden by subclass %s"
		% get_class()
	)


## Stops the feedback immediately and restores any state it mutated
## (camera transform, time scale, node scale, etc.). Must be safe to
## call at any time, including before [method _play] is ever invoked.
func _stop() -> void:
	pass


## Optional pre-warm hook. Called by [FeedbackPlayerLite] during its
## [method Node._ready] for every attached feedback, so a feedback can
## pre-allocate pools or other state before the first trigger fires.
func pre_warm(tree: SceneTree) -> void:
	pass


## Mirror of [method pre_warm] at the end of a feedback's useful life.
## Called by [FeedbackPlayerLite] on [constant Node.NOTIFICATION_EXIT_TREE]
## so pool-owning feedbacks can free nodes they parented to long-lived
## hosts (the [code]SparkleLitePresets[/code] autoload, a cached
## [CanvasLayer] under the current scene, etc.) instead of leaking them
## when the owning player leaves the tree.
func release_pool(tree: SceneTree) -> void:
	pass


## Hides fields that the custom inspector already exposes through its
## own row header ([code]label[/code], [code]enabled[/code]) or that
## belong to [Resource] scaffolding from the embedded inspector.
func _validate_property(property: Dictionary) -> void:
	if property.name in [
			&"resource_local_to_scene",
			&"resource_name",
			&"resource_path",
			&"label",
			&"enabled",
	]:
		property.usage = PROPERTY_USAGE_NO_EDITOR


## Returns the display name shown in the inspector when [member label]
## is empty. Each subclass overrides to return its own name.
func _get_default_label() -> String:
	return "Feedback"


## Returns [member label] if set, otherwise the class default.
func get_display_label() -> String:
	if label.is_empty():
		return _get_default_label()
	return label


## Returns the effective intensity for this feedback given the owning
## player's intensity.
func get_effective_intensity(player_intensity: float) -> float:
	return player_intensity * intensity_multiplier


## Returns the total time in seconds from play-call until this feedback
## completes, i.e. [code](delay_ms + duration_ms) / 1000.0[/code].
func get_total_duration_sec() -> float:
	return (delay_ms + duration_ms) / 1000.0


## Pre-flight check used by the editor's [b]Preview[/b] button. Returns
## an empty string when the feedback can run with the current scene
## state, or a short human-readable reason when it can't.
func get_preview_diagnostic(player: Node) -> String:
	return ""
