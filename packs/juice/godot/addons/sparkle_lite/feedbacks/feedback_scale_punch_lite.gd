# feedback_scale_punch.gd
# Elastic scale pop on a Node2D / Node3D / Control. Baseline is cached
# on first play per target; new punches on the same target override
# the running one (last-starts-wins).

@tool
class_name FeedbackScalePunchLite
extends "res://addons/sparkle_lite/feedbacks/feedback_base_lite.gd"

## Briefly scales a target node from its baseline to
## [member punch_scale] and back, with an elastic return controlled by
## [member elasticity]. Works on [Node2D], [Node3D], and [Control].

## Path to the target node. When empty the punch is applied to the
## owning [FeedbackPlayerLite] itself.
@export var target: NodePath = NodePath()

## Peak scale. For [Control]/[Node2D] only the x and y components are
## used.
@export var punch_scale: Vector3 = Vector3(1.2, 1.2, 1.2)

## Elastic overshoot on the return.
@export_range(0.0, 1.0, 0.01) var elasticity: float = 0.4

## Ignore [member Engine.time_scale] so the punch reads correctly
## during [FeedbackHitPauseLite].
@export var use_unscaled_time: bool = true

static var _baselines: Dictionary = {}
static var _active_runners: Dictionary = {}

var _runner: _Runner = null


func _get_default_label() -> String:
	return "Scale Punch"


func _play(intensity_in: float, player: Node) -> void:
	if player == null or not is_instance_valid(player):
		return
	var effective: float = get_effective_intensity(intensity_in)
	if effective <= 0.0 or duration_ms <= 0.0:
		return
	var node: Node = _resolve_target(player)
	if node == null:
		return
	var key: int = node.get_instance_id()
	if _baselines.has(key):
		var entry_ref: WeakRef = _baselines[key].get("ref")
		var cached_target: Object = entry_ref.get_ref() if entry_ref != null else null
		if cached_target != node:
			_baselines[key] = {"baseline": _read_scale(node), "ref": weakref(node)}
	else:
		_baselines[key] = {"baseline": _read_scale(node), "ref": weakref(node)}
	if _active_runners.has(key):
		var prior: _Runner = _active_runners[key]
		if is_instance_valid(prior):
			prior.stop_and_free()
	_runner = _Runner.new()
	_runner.name = "_SparkleLiteScalePunchRunner"
	_runner.configure(
			node, _baselines[key]["baseline"],
			_apply_intensity(punch_scale, effective),
			duration_ms / 1000.0,
			elasticity, use_unscaled_time, key
	)
	_active_runners[key] = _runner
	node.add_child(_runner)


func _stop() -> void:
	if _runner != null and is_instance_valid(_runner):
		_runner.stop_and_restore()
	_runner = null


func _resolve_target(player: Node) -> Node:
	var node: Node
	if target.is_empty():
		node = player
	else:
		node = player.get_node_or_null(target)
		if node == null:
			var tree: SceneTree = player.get_tree()
			if tree != null and tree.current_scene != null:
				node = tree.current_scene.get_node_or_null(target)
	if node == null:
		return null
	if node is Node2D or node is Node3D or node is Control:
		return node
	return null


func _apply_intensity(p: Vector3, intensity: float) -> Vector3:
	return Vector3.ONE.lerp(p, intensity)


static func _read_scale(node: Node) -> Variant:
	if node is Control:
		return (node as Control).scale
	if node is Node2D:
		return (node as Node2D).scale
	if node is Node3D:
		return (node as Node3D).scale
	return Vector3.ONE


static func _write_scale(node: Node, baseline: Variant, v3: Vector3) -> void:
	if not is_instance_valid(node):
		return
	if node is Control:
		var base2c: Vector2 = baseline
		(node as Control).scale = Vector2(
				base2c.x * v3.x, base2c.y * v3.y
		)
		return
	if node is Node2D:
		var base2d: Vector2 = baseline
		(node as Node2D).scale = Vector2(
				base2d.x * v3.x, base2d.y * v3.y
		)
		return
	if node is Node3D:
		var base3: Vector3 = baseline
		(node as Node3D).scale = base3 * v3
		return


static func _restore_scale(node: Node, key: int) -> void:
	if not _baselines.has(key):
		return
	var entry: Dictionary = _baselines[key]
	var entry_ref: WeakRef = entry.get("ref")
	var cached_target: Object = entry_ref.get_ref() if entry_ref != null else null
	if cached_target != node:
		_baselines.erase(key)
		return
	if not is_instance_valid(node):
		_baselines.erase(key)
		return
	var baseline: Variant = entry["baseline"]
	if node is Control:
		(node as Control).scale = baseline
	elif node is Node2D:
		(node as Node2D).scale = baseline
	elif node is Node3D:
		(node as Node3D).scale = baseline
	_baselines.erase(key)


class _Runner extends Node:

	var target: Node = null
	var baseline: Variant = null
	var punch: Vector3 = Vector3.ONE
	var duration_sec: float = 0.0
	var elasticity: float = 0.4
	var use_unscaled: bool = true
	var target_key: int = 0
	var _elapsed: float = 0.0
	var _last_ms: int = 0

	func configure(
			target_in: Node, baseline_in: Variant,
			punch_in: Vector3, duration_in: float,
			elasticity_in: float, unscaled: bool, key: int
	) -> void:
		target = target_in
		baseline = baseline_in
		punch = punch_in
		duration_sec = max(duration_in, 0.0001)
		elasticity = elasticity_in
		use_unscaled = unscaled
		target_key = key

	func _ready() -> void:
		if use_unscaled:
			process_mode = Node.PROCESS_MODE_ALWAYS
		_last_ms = Time.get_ticks_msec()
		if is_instance_valid(target):
			_write_scale_local(target, baseline, _sample(0.0))

	func _process(delta: float) -> void:
		if target == null or not is_instance_valid(target):
			_finish(false)
			return
		var dt: float = delta
		if use_unscaled:
			var now: int = Time.get_ticks_msec()
			dt = (now - _last_ms) / 1000.0
			_last_ms = now
		_elapsed += dt
		var t: float = clampf(_elapsed / duration_sec, 0.0, 1.0)
		var current: Vector3 = _sample(t)
		_write_scale_local(target, baseline, current)
		if _elapsed >= duration_sec:
			_finish(true)

	func _sample(t: float) -> Vector3:
		var peak_t: float = 0.4
		if t <= peak_t:
			var rise: float = t / peak_t
			return Vector3.ONE.lerp(punch, smoothstep(0.0, 1.0, rise))
		var fall: float = (t - peak_t) / (1.0 - peak_t)
		var overshoot: float = sin(fall * PI * 3.0) \
				* (1.0 - fall) * elasticity
		var eased: Vector3 = punch.lerp(Vector3.ONE, fall) \
				+ (punch - Vector3.ONE) * overshoot
		return eased

	func stop_and_free() -> void:
		_finish(false)

	func stop_and_restore() -> void:
		_finish(true)

	func _finish(restore: bool) -> void:
		if restore:
			_restore_scale_local(target, baseline)
		if not is_queued_for_deletion():
			queue_free()

	func _write_scale_local(node: Node, baseline_value: Variant, v3: Vector3) -> void:
		if not is_instance_valid(node):
			return
		if node is Control:
			var base2c: Vector2 = baseline_value
			(node as Control).scale = Vector2(
					base2c.x * v3.x, base2c.y * v3.y
			)
			return
		if node is Node2D:
			var base2d: Vector2 = baseline_value
			(node as Node2D).scale = Vector2(
					base2d.x * v3.x, base2d.y * v3.y
			)
			return
		if node is Node3D:
			var base3: Vector3 = baseline_value
			(node as Node3D).scale = base3 * v3

	func _restore_scale_local(node: Node, baseline_value: Variant) -> void:
		if not is_instance_valid(node):
			return
		if node is Control:
			(node as Control).scale = baseline_value
		elif node is Node2D:
			(node as Node2D).scale = baseline_value
		elif node is Node3D:
			(node as Node3D).scale = baseline_value
