extends Control
class_name LoadingOverlay

signal loading_started(label: String)
signal loading_completed()

var loading: bool = false


func start_loading(label: String = "") -> void:
	loading = true
	visible = true
	loading_started.emit(label)


func complete_loading() -> void:
	loading = false
	visible = false
	loading_completed.emit()
