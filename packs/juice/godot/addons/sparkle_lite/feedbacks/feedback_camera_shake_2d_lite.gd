# feedback_camera_shake_2d.gd
# Layered-noise positional + rotational camera shake on one or more
# Camera2D nodes. Per-axis toggles + Vector2 amplitudes + per-axis
# smooth/chaotic noise blend, envelope Curves, AUTO / ACTIVE /
# BY_PATH / BY_GROUP camera selection, and optional distance-based
# intensity falloff sampled once at play time.

@tool
class_name FeedbackCameraShake2DLite
extends FeedbackBaseLite

## Layered-noise camera shake on a [Camera2D]. Position (X / Y) and
## a single rotation axis each have independent toggles, amplitudes,
## and noise blend. Shakes stack additively; combined output is
## capped at 2× the strongest single contributor.

## How this feedback locates its [Camera2D](s).
enum CameraSelectionMode {
	AUTO = 0,
	ACTIVE = 1,
	BY_PATH = 2,
	BY_GROUP = 3,
}

@export_group("Positional Shake")
@export var shake_position_x: bool = true
@export var shake_position_y: bool = true
@export var position_amplitude: Vector2 = Vector2(12.0, 12.0)
@export var position_randomness: Vector2 = Vector2(0.5, 0.5)
@export var position_curve: Curve = null

@export_group("Rotational Shake")
@export var shake_rotation: bool = true
## Rotation amplitude in degrees.
@export var rotation_amplitude: float = 2.0
@export var rotation_randomness: float = 0.5
@export var rotation_curve: Curve = null

@export_group("Camera Target")
@export var camera_selection_mode: CameraSelectionMode = \
		CameraSelectionMode.AUTO:
	set(value):
		if camera_selection_mode == value:
			return
		camera_selection_mode = value
		notify_property_list_changed()
@export var camera_path: NodePath = NodePath()
@export var camera_group_name: String = ""

@export_group("Distance Falloff")
@export var use_distance_falloff: bool = false:
	set(value):
		if use_distance_falloff == value:
			return
		use_distance_falloff = value
		notify_property_list_changed()
@export var shake_source_path: NodePath = NodePath()
@export_range(0.0, 100000.0, 1.0, "or_greater", "suffix:px") \
var falloff_start_distance: float = 200.0
@export_range(0.0, 100000.0, 1.0, "or_greater", "suffix:px") \
var falloff_end_distance: float = 800.0
@export var falloff_curve: Curve = null

@export_group("Timing")
@export var use_unscaled_time: bool = true


static var _coordinator: CameraShake2DRuntimeLite.Coordinator = null

var _runners: Array[Node] = []


func _get_default_label() -> String:
	return "Camera Shake 2D"


func _play(intensity: float, player: Node) -> void:
	var effective: float = get_effective_intensity(intensity)
	if effective <= 0.0 or duration_ms <= 0.0:
		return
	if player == null or not is_instance_valid(player):
		return
	var cameras: Array[Camera2D] = _resolve_cameras(player)
	if cameras.is_empty():
		push_warning(("Sparkle Lite: FeedbackCameraShake2DLite found no "
				+ "active Camera2D on player '%s'. Assign or enable a "
				+ "Camera2D and retry.") % player.name)
		return
	if _coordinator == null:
		_coordinator = CameraShake2DRuntimeLite.Coordinator.new()
	_runners.clear()
	for camera in cameras:
		var falloff: float = _distance_falloff(player, camera)
		if falloff <= 0.0:
			continue
		var runner := CameraShake2DRuntimeLite.Runner.new()
		runner.name = "_SparkleLiteShake2DRunner"
		runner.configure({
			"camera": camera,
			"coordinator": _coordinator,
			"pos_flags": Vector2(
					float(shake_position_x), float(shake_position_y)),
			"pos_amp": position_amplitude * effective * falloff,
			"pos_rand": position_randomness,
			"pos_curve": position_curve,
			"rot_amp_rad": (deg_to_rad(rotation_amplitude)
					* (1.0 if shake_rotation else 0.0)
					* effective * falloff),
			"rot_rand": rotation_randomness,
			"rot_curve": rotation_curve,
			"duration": duration_ms / 1000.0,
			"use_unscaled_time": use_unscaled_time,
		})
		camera.add_child(runner)
		_runners.append(runner)


func _stop() -> void:
	for runner in _runners:
		if is_instance_valid(runner):
			(runner as CameraShake2DRuntimeLite.Runner).stop_and_free()
	_runners.clear()


func _validate_property(property: Dictionary) -> void:
	super(property)
	var n: StringName = property.name
	if n == &"camera_path" \
			and camera_selection_mode != CameraSelectionMode.BY_PATH:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif n == &"camera_group_name" \
			and camera_selection_mode != CameraSelectionMode.BY_GROUP:
		property.usage = PROPERTY_USAGE_NO_EDITOR
	elif n in [&"shake_source_path", &"falloff_start_distance",
			&"falloff_end_distance", &"falloff_curve"] \
			and not use_distance_falloff:
		property.usage = PROPERTY_USAGE_NO_EDITOR


func _resolve_cameras(player: Node) -> Array[Camera2D]:
	var out: Array[Camera2D] = []
	match camera_selection_mode:
		CameraSelectionMode.BY_PATH:
			var by_path: Camera2D = _lookup_camera_by_path(player)
			if by_path != null:
				out.append(by_path)
				return out
			push_warning(("Sparkle Lite: FeedbackCameraShake2DLite "
					+ "camera_path '%s' did not resolve to a Camera2D; "
					+ "falling back to AUTO.") % String(camera_path))
		CameraSelectionMode.BY_GROUP:
			out = _lookup_cameras_in_group(player)
			if not out.is_empty():
				return out
			push_warning(("Sparkle Lite: FeedbackCameraShake2DLite "
					+ "camera_group_name '%s' matched no Camera2D; "
					+ "falling back to AUTO.") % camera_group_name)
	var fallback: Camera2D = _find_active_camera(player)
	if fallback != null:
		out.append(fallback)
	return out


func _lookup_camera_by_path(player: Node) -> Camera2D:
	if camera_path.is_empty():
		return null
	var n: Node = player.get_node_or_null(camera_path)
	if n == null:
		var tree: SceneTree = player.get_tree()
		if tree != null and tree.current_scene != null:
			n = tree.current_scene.get_node_or_null(camera_path)
	if n is Camera2D:
		return n
	return null


func _lookup_cameras_in_group(player: Node) -> Array[Camera2D]:
	var out: Array[Camera2D] = []
	if camera_group_name.is_empty():
		return out
	var tree: SceneTree = player.get_tree()
	if tree == null:
		return out
	for node in tree.get_nodes_in_group(camera_group_name):
		if node is Camera2D and is_instance_valid(node):
			out.append(node)
	return out


func _find_active_camera(player: Node) -> Camera2D:
	var viewport: Viewport = player.get_viewport()
	if viewport != null:
		var cam: Camera2D = viewport.get_camera_2d()
		if cam != null and is_instance_valid(cam):
			return cam
	var tree: SceneTree = player.get_tree()
	if tree == null or tree.current_scene == null:
		return null
	return _search_current_camera(tree.current_scene)


func _search_current_camera(node: Node) -> Camera2D:
	# Camera2D doesn't expose a static .current flag like Camera3D;
	# we match on the "enabled" property, which is the 2D equivalent
	# of "this camera is participating in viewport canvas transform".
	if node is Camera2D and (node as Camera2D).enabled:
		return node
	for child in node.get_children():
		var found: Camera2D = _search_current_camera(child)
		if found != null:
			return found
	return null


func _distance_falloff(player: Node, camera: Camera2D) -> float:
	if not use_distance_falloff:
		return 1.0
	if falloff_end_distance <= falloff_start_distance:
		push_warning(("Sparkle Lite: FeedbackCameraShake2DLite "
				+ "falloff_end_distance (%s) must exceed "
				+ "falloff_start_distance (%s); distance falloff "
				+ "disabled for this play.")
				% [falloff_end_distance, falloff_start_distance])
		return 1.0
	var source_pos: Vector2 = _resolve_source_position(player)
	var dist: float = source_pos.distance_to(camera.global_position)
	if dist <= falloff_start_distance:
		return 1.0
	if dist >= falloff_end_distance:
		return 0.0
	var t: float = (dist - falloff_start_distance) \
			/ (falloff_end_distance - falloff_start_distance)
	if falloff_curve == null:
		return clampf(1.0 - t, 0.0, 1.0)
	return clampf(falloff_curve.sample(t), 0.0, 1.0)


func _resolve_source_position(player: Node) -> Vector2:
	if not shake_source_path.is_empty():
		var n: Node = player.get_node_or_null(shake_source_path)
		if n is Node2D:
			return (n as Node2D).global_position
	if player is Node2D:
		return (player as Node2D).global_position
	return Vector2.ZERO


func get_preview_diagnostic(player: Node) -> String:
	if player == null or not is_instance_valid(player):
		return ""
	match camera_selection_mode:
		CameraSelectionMode.BY_PATH:
			if camera_path.is_empty():
				return "camera_path is empty"
			if _lookup_camera_by_path(player) != null:
				return ""
			return ("camera_path '%s' did not resolve to a Camera2D"
					% String(camera_path))
		CameraSelectionMode.BY_GROUP:
			if camera_group_name.is_empty():
				return "camera_group_name is empty"
			if not _lookup_cameras_in_group(player).is_empty():
				return ""
			return ("no Camera2D found in group '%s'"
					% camera_group_name)
	if _find_active_camera(player) == null:
		return "needs an enabled Camera2D in the scene"
	return ""
