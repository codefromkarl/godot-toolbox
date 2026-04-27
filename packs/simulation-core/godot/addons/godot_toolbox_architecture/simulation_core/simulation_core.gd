extends Node
class_name SimulationCoreService

signal tick_started(delta: float)
signal tick_finished(delta: float)

@export var time_scale: float = 1.0
@export var paused: bool = false
@export var active_pause_domain: StringName = &"world"

var _systems: Array[GameSystem] = []


func register_system(system: GameSystem) -> void:
	if system == null or _systems.has(system):
		return
	_systems.append(system)
	_sort_systems()


func unregister_system(system: GameSystem) -> void:
	_systems.erase(system)


func tick(delta: float) -> void:
	var scaled_delta := delta * time_scale
	tick_started.emit(scaled_delta)
	for system in _systems:
		if _should_tick_system(system):
			system.tick(scaled_delta)
	tick_finished.emit(scaled_delta)


func system_count() -> int:
	return _systems.size()


func clear_systems() -> void:
	_systems.clear()


func _sort_systems() -> void:
	_systems.sort_custom(func(a: GameSystem, b: GameSystem) -> bool:
		return a.priority < b.priority
	)


func _should_tick_system(system: GameSystem) -> bool:
	if not system.enabled:
		return false
	if paused and not system.tick_when_paused:
		return false
	if paused and system.pause_domain != active_pause_domain:
		return false
	return true
