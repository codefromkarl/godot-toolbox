# feedback_call.gd
# Bridge feedback — calls a method or emits a signal on a target node
# at its place in the timeline. Lets designers hook gameplay code
# into a feel sequence without scripting around the player.

@tool
class_name FeedbackCallLite
extends FeedbackBaseLite

## Calls a method or emits a signal on [member target] during the
## sequence. Fires exactly once at [method _play].

enum CallMode { CALL_METHOD = 0, EMIT_SIGNAL = 1 }

## Selects between [code]CALL_METHOD[/code] and [code]EMIT_SIGNAL[/code].
@export var mode: CallMode = CallMode.CALL_METHOD

## Target node path. When empty the call is dispatched on the owning
## [FeedbackPlayerLite] itself.
@export var target: NodePath = NodePath()

## Method or signal name (depending on [member mode]).
@export var method_or_signal: StringName = &""

## Positional arguments passed to the method / signal.
@export var arguments: Array = []

static var _warned: Dictionary = {}


func _get_default_label() -> String:
	return "Call"


func _play(_intensity: float, player: Node) -> void:
	if player == null or not is_instance_valid(player):
		return
	if Engine.is_editor_hint():
		return
	if String(method_or_signal).is_empty():
		_warn_once("empty", "has no method_or_signal set")
		return
	var node: Node = _resolve_target(player)
	if node == null:
		_warn_once(
				"missing_target:" + String(target),
				"target '%s' did not resolve" % String(target)
		)
		return
	match mode:
		CallMode.CALL_METHOD:
			if not node.has_method(method_or_signal):
				_warn_once(
						"no_method:%d|%s" % [
							node.get_instance_id(),
							String(method_or_signal)
						],
						"%s has no method '%s'"
								% [node.name, String(method_or_signal)]
				)
				return
			node.callv(method_or_signal, arguments)
		CallMode.EMIT_SIGNAL:
			if not node.has_signal(method_or_signal):
				_warn_once(
						"no_signal:%d|%s" % [
							node.get_instance_id(),
							String(method_or_signal)
						],
						"%s has no signal '%s'"
								% [node.name, String(method_or_signal)]
				)
				return
			node.callv(
					"emit_signal",
					[method_or_signal] + arguments
			)


func _warn_once(key: String, message: String) -> void:
	if _warned.has(key):
		return
	_warned[key] = true
	push_warning(
			"Sparkle Lite: FeedbackCallLite — %s. Skipping." % message
	)


func _stop() -> void:
	pass


func _resolve_target(player: Node) -> Node:
	if target.is_empty():
		return player
	var node: Node = player.get_node_or_null(target)
	if node != null:
		return node
	var tree: SceneTree = player.get_tree()
	if tree != null and tree.current_scene != null:
		return tree.current_scene.get_node_or_null(target)
	return null


func get_preview_diagnostic(_player: Node) -> String:
	return "calls and signals are skipped during editor preview"
