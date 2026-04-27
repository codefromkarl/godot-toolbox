extends Resource
class_name CharacterData

@export var id: StringName
@export var display_name: String
@export var base_stats: Resource
@export var level_curve: Resource
@export var starting_level: int = 1
@export var unlocked_skill_ids: Array[StringName] = []


func is_valid() -> bool:
	return not String(id).is_empty() and base_stats != null
