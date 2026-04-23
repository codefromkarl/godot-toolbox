# camera_shake_2d_runtime.gd
# Internal runtime for FeedbackCameraShake2DLite. 2D sibling of
# CameraShakeRuntimeLite: holds the per-shake Runner and the
# process-wide Coordinator keyed per Camera2D. Not a public API — only
# FeedbackCameraShake2DLite imports this.

@tool
class_name CameraShake2DRuntimeLite
extends RefCounted

## Internal runtime for [FeedbackCameraShake2DLite].


## Per-shake Node. Lives on the target [Camera2D] until duration is
## exhausted or [method stop_and_free] is called.
class Runner extends Node:

	var camera: Camera2D = null
	var coordinator: RefCounted = null
	var pos_flags: Vector2 = Vector2.ONE
	var pos_amp: Vector2 = Vector2.ZERO
	var pos_rand: Vector2 = Vector2.ZERO
	var pos_curve: Curve = null
	var rot_amp_rad: float = 0.0
	var rot_rand: float = 0.0
	var rot_curve: Curve = null
	var duration_sec: float = 0.0
	var use_unscaled_time: bool = true
	var _elapsed: float = 0.0
	var _last_ms: int = 0
	var _noise_smooth: FastNoiseLite = null
	var _noise_chaotic: FastNoiseLite = null

	func configure(c: Dictionary) -> void:
		camera = c["camera"]
		coordinator = c["coordinator"]
		pos_flags = c["pos_flags"]; pos_amp = c["pos_amp"]
		pos_rand = c["pos_rand"]; pos_curve = c["pos_curve"]
		rot_amp_rad = c["rot_amp_rad"]; rot_rand = c["rot_rand"]
		rot_curve = c["rot_curve"]
		duration_sec = max(float(c["duration"]), 0.0001)
		use_unscaled_time = c["use_unscaled_time"]
		var s: int = randi()
		_noise_smooth = FastNoiseLite.new()
		_noise_smooth.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
		_noise_smooth.frequency = 1.2
		_noise_smooth.seed = s
		_noise_chaotic = FastNoiseLite.new()
		_noise_chaotic.noise_type = FastNoiseLite.TYPE_SIMPLEX
		_noise_chaotic.frequency = 8.0
		_noise_chaotic.seed = s + 1

	func _ready() -> void:
		if use_unscaled_time:
			process_mode = Node.PROCESS_MODE_ALWAYS
		_last_ms = Time.get_ticks_msec()
		if coordinator != null:
			coordinator.register(self)

	func _process(delta: float) -> void:
		if camera == null or not is_instance_valid(camera):
			_finish()
			return
		var dt: float = delta
		if use_unscaled_time:
			var now: int = Time.get_ticks_msec()
			dt = (now - _last_ms) / 1000.0
			_last_ms = now
		_elapsed += dt
		if coordinator != null:
			coordinator.apply(camera)
		if _elapsed >= duration_sec:
			_finish()

	func get_offsets() -> Array:
		var t: float = clampf(_elapsed / duration_sec, 0.0, 1.0)
		var pos_env: float = _sample_curve(pos_curve, t)
		var rot_env: float = _sample_curve(rot_curve, t)
		var time: float = _elapsed
		var pos := Vector2(
				_axis_sample(time, 0.0, pos_rand.x) * pos_flags.x,
				_axis_sample(time, 100.0, pos_rand.y) * pos_flags.y,
		) * pos_amp * pos_env
		var rot: float = _axis_sample(time, 500.0, rot_rand) \
				* rot_amp_rad * rot_env
		var single_amp: float = max(
				pos_amp.length() * pos_env,
				abs(rot_amp_rad) * rot_env,
		)
		return [pos, rot, single_amp]

	func stop_and_free() -> void:
		_finish()

	func _axis_sample(time: float, off: float, rand: float) -> float:
		var r: float = clampf(rand, 0.0, 1.0)
		var smooth: float = _noise_smooth.get_noise_2d(time, off)
		if r <= 0.0:
			return smooth
		var chaotic: float = _noise_chaotic.get_noise_2d(time, off)
		return lerp(smooth, chaotic, r)

	func _sample_curve(curve: Curve, t: float) -> float:
		if curve == null:
			return 1.0 - t
		return clampf(curve.sample(t), 0.0, 1.0)

	func _finish() -> void:
		if coordinator != null:
			coordinator.unregister(self)
			coordinator = null
		if not is_queued_for_deletion():
			queue_free()


## Shared by every [FeedbackCameraShake2DLite]. Keyed per-camera.
## Captures a Camera2D's baseline offset + rotation on first register
## and restores it when the last runner for that camera finishes.
class Coordinator extends RefCounted:

	var _entries: Dictionary = {}

	func register(runner: Runner) -> void:
		if runner == null or runner.camera == null:
			return
		var cam: Camera2D = runner.camera
		var key: int = cam.get_instance_id()
		if not _entries.has(key):
			_entries[key] = {
				"camera": weakref(cam),
				"offset": cam.offset,
				"rotation": cam.rotation,
				"runners": [],
			}
		_entries[key]["runners"].append(runner)

	func unregister(runner: Runner) -> void:
		if runner == null:
			return
		for key in _entries.keys().duplicate():
			var entry: Dictionary = _entries[key]
			var runners: Array = entry["runners"]
			if runners.has(runner):
				runners.erase(runner)
			if runners.is_empty():
				_restore(entry)
				_entries.erase(key)

	func apply(camera: Camera2D) -> void:
		if camera == null or not is_instance_valid(camera):
			return
		var key: int = camera.get_instance_id()
		if not _entries.has(key):
			return
		var entry: Dictionary = _entries[key]
		var total_pos: Vector2 = Vector2.ZERO
		var total_rot: float = 0.0
		var max_amp: float = 0.0
		var live: Array = []
		for runner in entry["runners"]:
			if not is_instance_valid(runner):
				continue
			live.append(runner)
			var data: Array = runner.get_offsets()
			total_pos += data[0]
			total_rot += float(data[1])
			max_amp = max(max_amp, float(data[2]))
		entry["runners"] = live
		if live.is_empty():
			_restore(entry)
			_entries.erase(key)
			return
		var cap: float = max_amp * 2.0
		if cap > 0.0:
			var pl: float = total_pos.length()
			if pl > cap:
				total_pos *= cap / pl
			if absf(total_rot) > cap:
				total_rot = sign(total_rot) * cap
		camera.offset = entry["offset"] + total_pos
		camera.rotation = entry["rotation"] + total_rot

	func _restore(entry: Dictionary) -> void:
		var cam: Camera2D = entry["camera"].get_ref()
		if is_instance_valid(cam):
			cam.offset = entry["offset"]
			cam.rotation = entry["rotation"]
