extends Node
class_name SimulationCoreService

signal tick_started(delta: float)
signal tick_finished(delta: float)

@export var time_scale: float = 1.0
@export var paused: bool = false

var _systems: Array[GameSystem] = []


func register_system(system: GameSystem) -> void:
	if system == null or _systems.has(system):
		return
	_systems.append(system)


func unregister_system(system: GameSystem) -> void:
	_systems.erase(system)


func tick(delta: float) -> void:
	if paused:
		return
	var scaled_delta := delta * time_scale
	tick_started.emit(scaled_delta)
	for system in _systems:
		if system.enabled:
			system.tick(scaled_delta)
	tick_finished.emit(scaled_delta)

