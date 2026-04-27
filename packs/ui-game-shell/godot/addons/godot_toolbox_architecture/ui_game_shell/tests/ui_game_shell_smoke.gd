extends SceneTree

const ShellRootScript := preload("res://addons/godot_toolbox_architecture/ui_game_shell/shell_root.gd")
const ModalLayerScript := preload("res://addons/godot_toolbox_architecture/ui_game_shell/modal_layer.gd")
const PauseOverlayScript := preload("res://addons/godot_toolbox_architecture/ui_game_shell/pause_overlay.gd")
const LoadingOverlayScript := preload("res://addons/godot_toolbox_architecture/ui_game_shell/loading_overlay.gd")
const ShellFlowBridgeScript := preload("res://addons/godot_toolbox_architecture/ui_game_shell/shell_flow_bridge.gd")

var _failed := false
var _pause_seen := false
var _resume_seen := false
var _loading_complete_seen := false


func _initialize() -> void:
	var shell: Control = ShellRootScript.new()
	root.add_child(shell)
	shell._ready()

	_assert(shell.modal_layer is ModalLayer, "shell should create modal layer")
	_assert(shell.pause_overlay is PauseOverlay, "shell should create pause overlay")
	_assert(shell.loading_overlay is LoadingOverlay, "shell should create loading overlay")

	shell.modal_layer.open_modal(&"settings")
	_assert(shell.modal_layer.has_modal(&"settings"), "modal layer should open settings")
	_assert(shell.modal_layer.close_modal(&"settings"), "modal layer should close settings")
	_assert(not shell.modal_layer.has_modal(&"settings"), "modal layer should remove closed settings")

	shell.pause_overlay.pause_requested.connect(func() -> void: _pause_seen = true)
	shell.pause_overlay.resume_requested.connect(func() -> void: _resume_seen = true)
	shell.pause_overlay.request_pause()
	shell.pause_overlay.request_resume()
	_assert(_pause_seen, "pause overlay should emit pause request")
	_assert(_resume_seen, "pause overlay should emit resume request")

	shell.loading_overlay.loading_completed.connect(func() -> void: _loading_complete_seen = true)
	shell.loading_overlay.start_loading("smoke")
	shell.loading_overlay.complete_loading()
	_assert(_loading_complete_seen, "loading overlay should emit completion")

	var bridge: ShellFlowBridge = ShellFlowBridgeScript.new()
	bridge.forward_pause_request(root)
	bridge.forward_resume_request(root)
	_assert(bridge.forwarded_commands == [&"pause", &"resume"], "flow bridge should record shell commands")

	shell.queue_free()
	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true


func _finish() -> void:
	quit(1 if _failed else 0)
