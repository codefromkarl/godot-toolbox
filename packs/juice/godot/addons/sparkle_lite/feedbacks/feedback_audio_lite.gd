# feedback_audio.gd
# Audio playback with three allocation strategies (POOL / CACHE /
# ONE_TIME), bus fallback, pitch randomisation, and a max-simultaneous
# eviction policy for POOL.

@tool
class_name FeedbackAudioLite
extends FeedbackBaseLite

## Plays an [AudioStream] via a pooled [AudioStreamPlayer2D] or
## [AudioStreamPlayer3D]. Pool nodes live under the
## [code]SparkleLitePresets[/code] autoload so scene changes never cut
## audio mid-play. See [enum LoadingMode] for the three allocation
## strategies.

## Audio stream to play. Null means the feedback silently does nothing.
@export var stream: AudioStream = null

## Playback volume in decibels.
@export_range(-40.0, 6.0, 0.1, "suffix:dB") var volume_db: float = 0.0

## Lower bound of randomised pitch scale.
@export_range(0.1, 4.0, 0.01) var pitch_min: float = 0.9

## Upper bound of randomised pitch scale.
@export_range(0.1, 4.0, 0.01) var pitch_max: float = 1.1

## Audio bus name. Invalid bus falls back to Master with a warning.
@export var bus: String = "Master"

## When true, uses [AudioStreamPlayer3D] positioned at the owning
## [FeedbackPlayerLite]'s global origin at play time. When false, uses
## [AudioStreamPlayer2D] (screen-space, non-attenuated).
@export var use_3d: bool = false

## Allocation strategy for player nodes. POOL pre-warms a fixed set and
## evicts oldest at cap. CACHE grows on demand and never evicts.
## ONE_TIME creates a fresh player per play and frees it when finished.
enum LoadingMode { POOL = 0, CACHE = 1, ONE_TIME = 2 }

@export var loading_mode: LoadingMode = LoadingMode.POOL:
	set(value):
		if loading_mode == value:
			return
		loading_mode = value
		notify_property_list_changed()

## [b]POOL mode only.[/b] Hard cap on concurrent playbacks.
@export_range(1, 32, 1) var max_simultaneous: int = 4

## [b]POOL mode only.[/b] Number of players pre-warmed at
## [method FeedbackPlayerLite] ready time.
@export_range(1, 32, 1) var pool_size: int = 4

const _AUDIO_POOL_NODE_PATH: String = "SparkleLitePresets/SparkleLiteAudioPool"
const _CACHE_SAFETY_CAP: int = 64

var _pool: Array[Node] = []
var _active: Array[Dictionary] = []
var _bus_resolved: String = ""
var _bus_validated: bool = false


func _get_default_label() -> String:
	return "Audio"


func pre_warm(tree: SceneTree) -> void:
	if tree == null:
		return
	if loading_mode == LoadingMode.POOL:
		_ensure_pool(tree)


func _play(intensity_in: float, player: Node) -> void:
	if stream == null:
		return
	if player == null or not is_instance_valid(player):
		return
	var tree: SceneTree = player.get_tree()
	if tree == null:
		return
	_validate_bus()
	var node: Node = null
	match loading_mode:
		LoadingMode.POOL:
			_ensure_pool(tree)
			node = _acquire_pool_player(tree)
		LoadingMode.CACHE:
			node = _acquire_cache_player(tree)
		LoadingMode.ONE_TIME:
			node = _acquire_one_time_player(tree)
	if node == null:
		return
	_configure(node, stream, player, intensity_in)
	_start_playback(node)


func _validate_property(property: Dictionary) -> void:
	super(property)
	var pool_only: Array[StringName] = [&"pool_size", &"max_simultaneous"]
	if property.name in pool_only:
		if loading_mode != LoadingMode.POOL:
			property.usage = PROPERTY_USAGE_NO_EDITOR


func _stop() -> void:
	for entry in _active:
		var node: Node = entry.get("player")
		if not is_instance_valid(node):
			continue
		_stop_playback(node)
		if node.has_meta(&"sparkle_lite_one_time"):
			node.queue_free()
	_active.clear()


func release_pool(_tree: SceneTree) -> void:
	for entry in _active:
		var node: Node = entry.get("player")
		if is_instance_valid(node):
			_stop_playback(node)
	_active.clear()
	for node in _pool:
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			_stop_playback(node)
			node.queue_free()
	_pool.clear()
	_bus_validated = false


func _ensure_pool(tree: SceneTree) -> void:
	_prune_invalid()
	var target: int = max(pool_size, max_simultaneous)
	if _pool.size() >= target:
		return
	var parent: Node = _find_pool_parent(tree)
	if parent == null:
		return
	while _pool.size() < target:
		var node: Node = _create_player_node()
		parent.add_child(node)
		_pool.append(node)
		node.finished.connect(_on_finished.bind(node))


func _prune_invalid() -> void:
	var live_pool: Array[Node] = []
	for node in _pool:
		if is_instance_valid(node) and node.is_inside_tree():
			live_pool.append(node)
	_pool = live_pool
	var live_active: Array[Dictionary] = []
	for entry in _active:
		if is_instance_valid(entry.get("player")):
			live_active.append(entry)
	_active = live_active


func _find_pool_parent(tree: SceneTree) -> Node:
	var autoload_pool: Node = tree.root.get_node_or_null(
			_AUDIO_POOL_NODE_PATH
	)
	if autoload_pool != null:
		return autoload_pool
	return tree.current_scene


func _create_player_node() -> Node:
	if use_3d:
		var n3: AudioStreamPlayer3D = AudioStreamPlayer3D.new()
		n3.name = "_SparkleLiteAudio3D"
		return n3
	var n2: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
	n2.name = "_SparkleLiteAudio2D"
	return n2


func _acquire_pool_player(tree: SceneTree) -> Node:
	for node in _pool:
		if not _is_active(node):
			return node
	if _active.size() < max_simultaneous:
		var parent: Node = _find_pool_parent(tree)
		if parent == null:
			return null
		var temp: Node = _create_player_node()
		parent.add_child(temp)
		_pool.append(temp)
		temp.finished.connect(_on_finished.bind(temp))
		return temp
	if _active.is_empty():
		return null
	var oldest: Dictionary = _active[0]
	var oldest_node: Node = oldest.get("player")
	if is_instance_valid(oldest_node):
		_stop_playback(oldest_node)
	_active.remove_at(0)
	return oldest_node


func _acquire_cache_player(tree: SceneTree) -> Node:
	_prune_invalid()
	for node in _pool:
		if not _is_active(node):
			return node
	if _pool.size() >= _CACHE_SAFETY_CAP:
		return null
	var parent: Node = _find_pool_parent(tree)
	if parent == null:
		return null
	var fresh: Node = _create_player_node()
	parent.add_child(fresh)
	_pool.append(fresh)
	fresh.finished.connect(_on_finished.bind(fresh))
	return fresh


func _acquire_one_time_player(tree: SceneTree) -> Node:
	var parent: Node = _find_pool_parent(tree)
	if parent == null:
		return null
	var node: Node = _create_player_node()
	node.set_meta(&"sparkle_lite_one_time", true)
	parent.add_child(node)
	node.finished.connect(_on_finished.bind(node))
	return node


func _is_active(node: Node) -> bool:
	for entry in _active:
		if entry.get("player") == node:
			return true
	return false


func _configure(
		node: Node, stream_in: AudioStream,
		player: Node, intensity_in: float
) -> void:
	var effective: float = get_effective_intensity(intensity_in)
	var volume: float = volume_db + linear_to_db(max(effective, 0.0001))
	var pitch: float = randf_range(pitch_min, pitch_max)
	node.set(&"stream", stream_in)
	node.set(&"volume_db", volume)
	node.set(&"pitch_scale", pitch)
	node.set(&"bus", _bus_resolved)
	if node is AudioStreamPlayer3D and player is Node3D:
		(node as AudioStreamPlayer3D).global_position = \
				(player as Node3D).global_position


func _start_playback(node: Node) -> void:
	node.call(&"play")
	_active.append({
		"player": node,
		"started_at": Time.get_ticks_msec()
	})


func _stop_playback(node: Node) -> void:
	node.call(&"stop")


func _on_finished(node: Node) -> void:
	for i in range(_active.size() - 1, -1, -1):
		if _active[i].get("player") == node:
			_active.remove_at(i)
			break
	if (
			is_instance_valid(node)
			and node.has_meta(&"sparkle_lite_one_time")
	):
		node.queue_free()


func _validate_bus() -> void:
	if _bus_validated:
		return
	_bus_validated = true
	if AudioServer.get_bus_index(bus) == -1:
		push_warning(
			("Sparkle Lite: FeedbackAudioLite bus '%s' does not exist. "
			+ "Falling back to Master.") % bus
		)
		_bus_resolved = "Master"
	else:
		_bus_resolved = bus
