# feedback_screen_flash_2d.gd
# Full-viewport colour flash overlay for 2D games. One shared ColorRect
# per canvas layer is lazy-spawned under the SparkleLitePresets autoload,
# so the flash survives scene changes and auto-cleans when the plugin
# disables.

@tool
class_name FeedbackScreenFlash2DLite
extends FeedbackBaseLite

## Full-screen colour flash. Drops a [ColorRect] over the game on a
## dedicated [CanvasLayer] and animates its alpha through a
## fade-in → hold → fade-out envelope.
##
## A single [ColorRect] is shared across every [FeedbackScreenFlash2DLite]
## instance at the same [member canvas_layer] — multiple flashes
## compose onto the same overlay instead of stacking layers.
##
## The overlay lives under the [code]SparkleLitePresets[/code] autoload,
## which means it persists across scene changes.

## Blend mode used by the overlay [ColorRect].
enum BlendMode {
	MODULATE = 0,
	ADD = 1,
}

## Flash colour at peak intensity.
@export var flash_color: Color = Color.WHITE

## Time to fade in from transparent to [member flash_intensity].
@export_range(0.0, 10000.0, 1.0, "or_greater", "suffix:ms") \
var fade_in_duration_ms: float = 40.0

## Time to hold at peak before starting the fade-out.
@export_range(0.0, 10000.0, 1.0, "or_greater", "suffix:ms") \
var hold_duration_ms: float = 0.0

## Time to fade out back to transparent.
@export_range(0.0, 10000.0, 1.0, "or_greater", "suffix:ms") \
var fade_out_duration_ms: float = 120.0

## Peak opacity of the flash.
@export_range(0.0, 1.0, 0.01) var flash_intensity: float = 0.3

## Canvas layer index for the overlay.
@export_range(-128, 128, 1, "or_greater") var canvas_layer: int = 100

## Blend mode. [code]ADD[/code] brightens the underlying image;
## [code]MODULATE[/code] tints it.
@export var blend_mode: BlendMode = BlendMode.ADD

const _LAYER_NODE_PREFIX: String = "SparkleLiteScreenFlash2DLayer_"

static var _coordinator: _Coordinator = null

var _runner: _Runner = null


func _get_default_label() -> String:
	return "Screen Flash 2D"


## Called by [code]plugin.gd[/code] when the addon is disabled so the
## shared overlay does not leak under the autoload.
static func _reset() -> void:
	if _coordinator == null:
		return
	_coordinator.cleanup()
	_coordinator = null


func _play(intensity_in: float, player: Node) -> void:
	var effective: float = get_effective_intensity(intensity_in)
	var peak: float = effective * flash_intensity
	if peak <= 0.0:
		return
	if player == null or not is_instance_valid(player):
		return
	var tree: SceneTree = player.get_tree()
	if tree == null:
		return
	if _coordinator == null:
		_coordinator = _Coordinator.new()
	var rect: ColorRect = _coordinator.ensure_overlay(tree, canvas_layer)
	if rect == null:
		return
	var total_ms: float = (
			fade_in_duration_ms + hold_duration_ms + fade_out_duration_ms
	)
	if total_ms <= 0.0:
		return
	_runner = _Runner.new()
	_runner.name = "_SparkleLiteScreenFlash2DRunner"
	_runner.configure(
			rect, flash_color, peak,
			fade_in_duration_ms / 1000.0,
			hold_duration_ms / 1000.0,
			fade_out_duration_ms / 1000.0,
			canvas_layer, int(blend_mode), _coordinator
	)
	rect.add_child(_runner)


func _stop() -> void:
	if _runner != null and is_instance_valid(_runner):
		_runner.stop_and_free()
	_runner = null


class _Runner extends Node:

	var rect: ColorRect = null
	var coordinator: RefCounted = null
	var color: Color = Color.WHITE
	var peak: float = 0.0
	var blend: int = 0
	var layer_id: int = 100
	var fade_in_sec: float = 0.0
	var hold_sec: float = 0.0
	var fade_out_sec: float = 0.0
	var _tween: Tween = null
	var _current: float = 0.0

	func configure(
			rect_in: ColorRect, color_in: Color, peak_in: float,
			fade_in: float, hold: float, fade_out: float,
			layer_in: int, blend_in: int, coord: RefCounted
	) -> void:
		rect = rect_in
		color = color_in
		peak = peak_in
		fade_in_sec = fade_in
		hold_sec = hold
		fade_out_sec = fade_out
		layer_id = layer_in
		blend = blend_in
		coordinator = coord

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		if coordinator != null:
			coordinator.register(self, layer_id)
		_tween = create_tween()
		_tween.set_ignore_time_scale(true)
		if fade_in_sec > 0.0:
			_tween.tween_method(
					_set_value, 0.0, peak, fade_in_sec
			)
		else:
			_set_value(peak)
		if hold_sec > 0.0:
			_tween.tween_interval(hold_sec)
		if fade_out_sec > 0.0:
			_tween.tween_method(
					_set_value, peak, 0.0, fade_out_sec
			)
		else:
			_tween.tween_callback(_set_value.bind(0.0))
		_tween.finished.connect(_finish, CONNECT_ONE_SHOT)

	func _process(_delta: float) -> void:
		if coordinator != null:
			coordinator.apply(layer_id)

	func _set_value(v: float) -> void:
		_current = v

	func get_current() -> float:
		return _current

	func get_color() -> Color:
		return color

	func get_blend() -> int:
		return blend

	func stop_and_free() -> void:
		_finish()

	func _finish() -> void:
		if _tween != null and _tween.is_valid():
			_tween.kill()
			_tween = null
		if coordinator != null:
			coordinator.unregister(self, layer_id)
			coordinator = null
		if not is_queued_for_deletion():
			queue_free()


class _Coordinator extends RefCounted:

	var _layers: Dictionary = {}

	func ensure_overlay(tree: SceneTree, layer_id: int) -> ColorRect:
		var root: Node = tree.root
		if root == null:
			return null
		if _layers.has(layer_id):
			var rect_cached: ColorRect = _layers[layer_id]["rect"].get_ref()
			if is_instance_valid(rect_cached):
				return rect_cached
			_layers.erase(layer_id)
		var host: Node = _find_host(tree)
		if host == null:
			host = root
		var node_name: String = "%s%d" % [
				FeedbackScreenFlash2DLite._LAYER_NODE_PREFIX, layer_id
		]
		var stale: Node = host.get_node_or_null(node_name)
		if stale != null:
			host.remove_child(stale)
			stale.queue_free()
		var layer: CanvasLayer = CanvasLayer.new()
		layer.name = node_name
		layer.layer = layer_id
		host.add_child(layer)
		var rect: ColorRect = ColorRect.new()
		rect.name = &"Flash"
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.color = Color(0.0, 0.0, 0.0, 0.0)
		layer.add_child(rect)
		if not tree.root.size_changed.is_connected(_on_viewport_resized):
			tree.root.size_changed.connect(_on_viewport_resized)
		_layers[layer_id] = {
			"layer": weakref(layer),
			"rect": weakref(rect),
			"runners": [],
		}
		return rect

	func register(runner: _Runner, layer_id: int) -> void:
		if not _layers.has(layer_id):
			return
		_layers[layer_id]["runners"].append(runner)

	func unregister(runner: _Runner, layer_id: int) -> void:
		if not _layers.has(layer_id):
			return
		var runners: Array = _layers[layer_id]["runners"]
		runners.erase(runner)
		if runners.is_empty():
			var rect: ColorRect = _layers[layer_id]["rect"].get_ref()
			if is_instance_valid(rect):
				rect.color = Color(0.0, 0.0, 0.0, 0.0)

	func apply(layer_id: int) -> void:
		if not _layers.has(layer_id):
			return
		var entry: Dictionary = _layers[layer_id]
		var rect: ColorRect = entry["rect"].get_ref()
		if not is_instance_valid(rect):
			return
		var live: Array = []
		var max_intensity: float = 0.0
		var weighted_color: Color = Color(0.0, 0.0, 0.0, 0.0)
		var total_weight: float = 0.0
		var has_add: bool = false
		for runner in entry["runners"]:
			if not is_instance_valid(runner):
				continue
			live.append(runner)
			var v: float = runner.get_current()
			if v <= 0.0:
				continue
			max_intensity = max(max_intensity, v)
			var c: Color = runner.get_color()
			weighted_color = Color(
					weighted_color.r + c.r * v,
					weighted_color.g + c.g * v,
					weighted_color.b + c.b * v,
					1.0
			)
			total_weight += v
			if runner.get_blend() == 1:
				has_add = true
		entry["runners"] = live
		if max_intensity <= 0.0 or total_weight <= 0.0:
			rect.color = Color(0.0, 0.0, 0.0, 0.0)
			return
		var composite: Color = Color(
				weighted_color.r / total_weight,
				weighted_color.g / total_weight,
				weighted_color.b / total_weight,
				max_intensity
		)
		rect.color = composite
		_apply_blend(rect, has_add)

	func cleanup() -> void:
		for layer_id in _layers.keys():
			var entry: Dictionary = _layers[layer_id]
			var layer: CanvasLayer = entry["layer"].get_ref()
			if is_instance_valid(layer):
				layer.queue_free()
		_layers.clear()

	func _find_host(tree: SceneTree) -> Node:
		var autoload: Node = tree.root.get_node_or_null(
				"SparkleLitePresets"
		)
		if autoload != null:
			return autoload
		return tree.root

	func _on_viewport_resized() -> void:
		for layer_id in _layers.keys():
			var rect: ColorRect = _layers[layer_id]["rect"].get_ref()
			if is_instance_valid(rect):
				rect.set_anchors_preset(Control.PRESET_FULL_RECT)

	func _apply_blend(rect: ColorRect, additive: bool) -> void:
		if additive:
			if rect.material == null:
				var mat: CanvasItemMaterial = CanvasItemMaterial.new()
				mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
				rect.material = mat
		else:
			rect.material = null
