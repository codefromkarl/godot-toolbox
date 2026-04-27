extends Resource
class_name CombatEventStream

@export var events: Array[Dictionary] = []


func emit_event(event_type: StringName, payload: Dictionary = {}) -> void:
	events.append({
		"type": String(event_type),
		"payload": payload.duplicate(true),
		"index": events.size(),
	})


func clear() -> void:
	events.clear()


func to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for event in events:
		result.append(event.duplicate(true))
	return result
