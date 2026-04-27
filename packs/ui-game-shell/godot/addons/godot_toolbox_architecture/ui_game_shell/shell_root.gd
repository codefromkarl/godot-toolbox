extends Control
class_name ShellRoot

signal command_requested(command: StringName, payload: Dictionary)

var modal_layer: ModalLayer
var pause_overlay: PauseOverlay
var loading_overlay: LoadingOverlay


func _ready() -> void:
	if modal_layer == null:
		modal_layer = ModalLayer.new()
		modal_layer.name = "ModalLayer"
		add_child(modal_layer)
	if pause_overlay == null:
		pause_overlay = PauseOverlay.new()
		pause_overlay.name = "PauseOverlay"
		add_child(pause_overlay)
	if loading_overlay == null:
		loading_overlay = LoadingOverlay.new()
		loading_overlay.name = "LoadingOverlay"
		add_child(loading_overlay)


func request_command(command: StringName, payload: Dictionary = {}) -> void:
	command_requested.emit(command, payload)
