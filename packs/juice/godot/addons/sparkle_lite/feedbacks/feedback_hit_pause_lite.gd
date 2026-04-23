# feedback_hit_pause.gd
# Brief Engine.time_scale drop ("hit-stop"). Enforces a half-second max
# duration, uses unscaled timers, and stacks via a shared coordinator
# that picks the lowest time_scale among all active pauses.

@tool
class_name FeedbackHitPauseLite
extends "res://addons/sparkle_lite/feedbacks/feedback_base_lite.gd"

## Hit-stop feedback. Drops [member Engine.time_scale] for a short,
## cap-enforced window, then restores it.
##
## Multiple hit pauses fire simultaneously correctly: the coordinator
## keeps the [b]lowest[/b] active [member time_scale_during_pause]
## (they do not stack multiplicatively) and restores the original
## [member Engine.time_scale] only after the last active pause ends.
## Duration is clamped to 500 ms regardless of the authored value.

const _MAX_DURATION_MS: float = 500.0

## Engine time scale applied while this hit pause is active.
## 0.05 is a heavy hit-stop feel. 1.0 disables the effect.
@export_range(0.0, 1.0, 0.01) \
var time_scale_during_pause: float = 0.05

## When false, audio continues at normal speed during the hit pause.
@export var affect_audio: bool = false

static var _coordinator: _Coordinator = null

var _active_id: int = -1


func _get_default_label() -> String:
	return "Hit Pause"


func _play(intensity: float, player: Node) -> void:
	var effective: float = get_effective_intensity(intensity)
	if effective <= 0.0:
		return
	var duration: float = duration_ms
	if duration > _MAX_DURATION_MS:
		push_warning(
			("Sparkle Lite: FeedbackHitPauseLite duration_ms (%s) "
			+ "exceeds the 500 ms safety cap — clamping. Hit pauses "
			+ "longer than half a second feel like bugs.") % duration
		)
		duration = _MAX_DURATION_MS
	var tree: SceneTree = _get_tree(player)
	if tree == null:
		return
	if _coordinator == null:
		_coordinator = _Coordinator.new()
	_active_id = _coordinator.enter(
		tree,
		time_scale_during_pause,
		duration / 1000.0,
		affect_audio
	)


func _stop() -> void:
	if _coordinator != null and _active_id >= 0:
		_coordinator.leave(_active_id)
	_active_id = -1


func _get_tree(player: Node) -> SceneTree:
	if player == null or not is_instance_valid(player):
		return null
	return player.get_tree()


class _Coordinator extends RefCounted:

	var _active: Dictionary = {}  # id -> time_scale (float)
	var _next_id: int = 0
	var _baseline_scale: float = 1.0
	var _baseline_audio_scale: float = 1.0

	func enter(
			tree: SceneTree,
			time_scale: float,
			duration_sec: float,
			affect_audio: bool
	) -> int:
		var id: int = _next_id
		_next_id += 1
		if _active.is_empty():
			_baseline_scale = Engine.time_scale
			_baseline_audio_scale = AudioServer.playback_speed_scale
		_active[id] = time_scale
		_apply(affect_audio)
		var timer: SceneTreeTimer = tree.create_timer(
			duration_sec,
			true,
			false,
			true
		)
		timer.timeout.connect(_on_timeout.bind(id, affect_audio))
		return id

	func leave(id: int) -> void:
		if not _active.has(id):
			return
		_active.erase(id)
		if _active.is_empty():
			Engine.time_scale = _baseline_scale
			AudioServer.playback_speed_scale = _baseline_audio_scale
		else:
			_apply(false)

	func _on_timeout(id: int, affect_audio: bool) -> void:
		leave(id)

	func _apply(affect_audio: bool) -> void:
		var lowest: float = INF
		for v in _active.values():
			if v < lowest:
				lowest = v
		if lowest == INF:
			return
		Engine.time_scale = lowest
		if affect_audio:
			AudioServer.playback_speed_scale = lowest
