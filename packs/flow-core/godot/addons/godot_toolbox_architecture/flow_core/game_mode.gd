extends Resource
class_name GameMode

@export var id: StringName
@export var scene_path: String
@export var pause_policy: PausePolicy
@export var metadata: Dictionary = {}


func is_valid() -> bool:
	return not String(id).is_empty()

