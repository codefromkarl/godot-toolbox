extends Control
class_name PauseOverlay

signal pause_requested()
signal resume_requested()

var paused: bool = false


func request_pause() -> void:
	paused = true
	visible = true
	pause_requested.emit()


func request_resume() -> void:
	paused = false
	visible = false
	resume_requested.emit()
