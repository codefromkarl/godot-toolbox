# feedback_player.gd
# The orchestrator. Holds an ordered list of FeedbackBaseLite entries
# and fires each one (after its delay) on play(). Supports looping,
# per-call intensity, rapid-fire debounce, and overlapping parallel
# instances. Safe to call under any frequency; stops cleanly on free.

@tool
@icon("res://addons/sparkle_lite/icon.svg")
class_name FeedbackPlayerLite
extends Node

## Orchestrates a sequence of [FeedbackBaseLite] entries.
##
## Each [method play] call creates an independent sequence instance —
## multiple instances can overlap, and each fires its own
## [signal started]/[signal completed] pair. Calling [method stop]
## cancels every active instance.
##
## [codeblock]
## # Typical usage:
## $FeedbackPlayer.play()
## $FeedbackPlayer.play(0.5)  # at half intensity
## [/codeblock]

## Ordered list of feedbacks this player fires. Each entry's own
## delay_ms staggers it relative to the play() call; entries run in
## parallel to each other. Authored via the "+ Add Feedback" dropdown
## on this inspector.
@export var feedbacks: Array[FeedbackBaseLite] = []

## When true, play() is called automatically from _ready() at runtime.
@export var auto_play_on_ready: bool = false

## When true, a completed sequence restarts automatically from
## loop_from_index after loop_delay_ms.
@export var loop: bool = false

## Pause between the end of one loop iteration and the start of the
## next, in milliseconds.
@export_range(0.0, 60000.0, 1.0, "or_greater", "suffix:ms") \
var loop_delay_ms: float = 0.0

## Index into feedbacks to restart from when looping.
@export_range(0, 256, 1, "or_greater") var loop_from_index: int = 0

## Global intensity multiplier applied on top of every feedback's own
## intensity_multiplier and the per-call intensity argument to play().
@export_range(0.0, 4.0, 0.01) var default_intensity: float = 1.0

## Debounce window for play(). Calls that arrive less than this many
## milliseconds after the previous successful play() are ignored.
@export_range(0.0, 10000.0, 1.0, "or_greater", "suffix:ms") \
var minimum_interval_ms: float = 0.0

## Emitted when a [method play] call starts a new sequence instance.
signal started

## Emitted when a sequence instance's feedbacks have all completed.
signal completed

## Emitted when an individual feedback at [param index] begins.
signal feedback_started(index: int)

## Emitted when an individual feedback at [param index] finishes.
signal feedback_completed(index: int)

var _active_instances: Dictionary = {}
var _next_instance_id: int = 0
var _last_play_ms: int = -1
var _loop_generation: int = 0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	var tree: SceneTree = get_tree()
	for fb in feedbacks:
		if fb != null:
			fb.pre_warm.call_deferred(tree)
	if auto_play_on_ready:
		call_deferred("play")


func _notification(what: int) -> void:
	if what == NOTIFICATION_EXIT_TREE or what == NOTIFICATION_PREDELETE:
		stop()
		if what == NOTIFICATION_EXIT_TREE:
			var tree: SceneTree = get_tree()
			if tree != null:
				for fb in feedbacks:
					if fb != null:
						fb.release_pool(tree)


## Plays every enabled feedback in [member feedbacks] in parallel,
## honouring each entry's per-delay.
func play(intensity: float = 1.0) -> void:
	var now: int = Time.get_ticks_msec()
	if minimum_interval_ms > 0.0 and _last_play_ms >= 0:
		if float(now - _last_play_ms) < minimum_interval_ms:
			return
	_last_play_ms = now
	_start_instance(intensity, 0)


## Stops every active sequence instance immediately.
func stop() -> void:
	_loop_generation += 1
	for id in _active_instances.keys().duplicate():
		var instance: Dictionary = _active_instances[id]
		instance["cancelled"] = true
		for fb in instance["active_feedbacks"]:
			if fb != null:
				fb._stop()
		_active_instances.erase(id)


## Plays a single feedback at [param index], useful for testing and
## for triggering individual entries from code.
func play_feedback_at_index(index: int, intensity: float = 1.0) -> void:
	if index < 0 or index >= feedbacks.size():
		return
	var fb: FeedbackBaseLite = feedbacks[index]
	if fb == null or not fb.enabled:
		return
	var combined: float = intensity * default_intensity
	var id: int = _next_instance_id
	_next_instance_id += 1
	_active_instances[id] = {
		"id": id,
		"intensity": combined,
		"active_feedbacks": [],
		"completed_count": 0,
		"pending_count": 1,
		"cancelled": false,
		"caller_intensity": intensity,
		"allow_loop": false
	}
	started.emit()
	_schedule_start(id, index, fb.delay_ms / 1000.0, combined)


## Appends [param feedback] to [member feedbacks].
func add_feedback(feedback: FeedbackBaseLite) -> FeedbackBaseLite:
	if feedback != null:
		feedbacks.append(feedback)
	return feedback


## Removes every feedback.
func clear_feedbacks() -> void:
	feedbacks.clear()


## Adopts [param preset]'s feedbacks (deep-duplicated so per-player
## edits don't mutate the source preset).
func apply_preset(preset: FeedbackPresetLite) -> void:
	if preset == null:
		return
	feedbacks = preset.feedbacks.duplicate(true)


## Returns the time, in seconds, from a [method play] call until the
## last feedback in the list completes.
func get_total_duration() -> float:
	var total_end: float = 0.0
	for fb in feedbacks:
		if fb == null or not fb.enabled:
			continue
		var end_at: float = fb.get_total_duration_sec()
		total_end = max(total_end, end_at)
	return total_end


## Returns true if any sequence instance is currently running.
func is_playing() -> bool:
	return not _active_instances.is_empty()


func _start_instance(intensity: float, start_index: int) -> void:
	var combined: float = intensity * default_intensity
	started.emit()
	var plan: Array[Dictionary] = []
	for i in range(start_index, feedbacks.size()):
		var fb: FeedbackBaseLite = feedbacks[i]
		if fb == null or not fb.enabled:
			continue
		var fire_at: float = fb.delay_ms / 1000.0
		plan.append({"index": i, "fire_at": fire_at})
	if plan.is_empty():
		completed.emit()
		if loop:
			_schedule_loop(intensity)
		return
	var id: int = _next_instance_id
	_next_instance_id += 1
	_active_instances[id] = {
		"id": id,
		"intensity": combined,
		"active_feedbacks": [],
		"completed_count": 0,
		"pending_count": plan.size(),
		"cancelled": false,
		"caller_intensity": intensity,
		"allow_loop": true
	}
	for step in plan:
		_schedule_start(id, step["index"], step["fire_at"], combined)


func _schedule_start(
		instance_id: int,
		index: int,
		delay_sec: float,
		intensity: float
) -> void:
	if delay_sec <= 0.0:
		_on_feedback_start(instance_id, index, intensity)
		return
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var timer: SceneTreeTimer = tree.create_timer(
			delay_sec, true, false, true
	)
	timer.timeout.connect(
			_on_feedback_start.bind(instance_id, index, intensity)
	)


func _on_feedback_start(
		instance_id: int, index: int, intensity: float
) -> void:
	if not _active_instances.has(instance_id):
		return
	var instance: Dictionary = _active_instances[instance_id]
	if instance["cancelled"]:
		return
	if index < 0 or index >= feedbacks.size():
		_finish_feedback(instance_id, index)
		return
	var fb: FeedbackBaseLite = feedbacks[index]
	if fb == null or not fb.enabled:
		_finish_feedback(instance_id, index)
		return
	instance["active_feedbacks"].append(fb)
	feedback_started.emit(index)
	fb._play(intensity, self)
	_schedule_complete(instance_id, index, fb)


func _schedule_complete(
		instance_id: int, index: int, fb: FeedbackBaseLite
) -> void:
	var total_sec: float = fb.get_total_duration_sec()
	var delay_sec: float = fb.delay_ms / 1000.0
	var duration_sec: float = max(total_sec - delay_sec, 0.0)
	if duration_sec <= 0.0:
		_on_feedback_complete(instance_id, index, fb)
		return
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var timer: SceneTreeTimer = tree.create_timer(
			duration_sec, true, false, true
	)
	timer.timeout.connect(
			_on_feedback_complete.bind(instance_id, index, fb)
	)


func _on_feedback_complete(
		instance_id: int, index: int, fb: FeedbackBaseLite
) -> void:
	if not _active_instances.has(instance_id):
		return
	var instance: Dictionary = _active_instances[instance_id]
	if instance["cancelled"]:
		return
	if fb != null:
		instance["active_feedbacks"].erase(fb)
	_finish_feedback(instance_id, index)


func _finish_feedback(instance_id: int, index: int) -> void:
	if not _active_instances.has(instance_id):
		return
	var instance: Dictionary = _active_instances[instance_id]
	feedback_completed.emit(index)
	instance["completed_count"] += 1
	if instance["completed_count"] < instance["pending_count"]:
		return
	var caller_intensity: float = instance["caller_intensity"]
	var allow_loop: bool = instance["allow_loop"]
	var was_cancelled: bool = instance["cancelled"]
	_active_instances.erase(instance_id)
	if was_cancelled:
		return
	completed.emit()
	if loop and allow_loop:
		_schedule_loop(caller_intensity)


func _schedule_loop(intensity: float) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var delay_sec: float = loop_delay_ms / 1000.0
	if delay_sec <= 0.0:
		_start_instance(intensity, loop_from_index)
		return
	var gen: int = _loop_generation
	var timer: SceneTreeTimer = tree.create_timer(
			delay_sec, true, false, true
	)
	timer.timeout.connect(func() -> void:
		if gen != _loop_generation:
			return
		_start_instance(intensity, loop_from_index)
	)
