extends RefCounted
class_name GameSystem

var enabled: bool = true
var priority: int = 0
var pause_domain: StringName = &"world"
var tick_when_paused: bool = false


func tick(_delta: float) -> void:
	pass
