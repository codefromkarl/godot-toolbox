extends Resource
class_name GameEvent

@export var id: StringName
@export var payload: Dictionary = {}


func is_valid() -> bool:
	return not String(id).is_empty()
