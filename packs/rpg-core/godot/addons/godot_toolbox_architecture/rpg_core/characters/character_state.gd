extends Resource
class_name CharacterState

@export var data: Resource
@export var character_id: StringName
@export var level: int = 1
@export var experience: int = 0
@export var current_hp: int = 0
@export var current_mp: int = 0
@export var status_ids: Array[StringName] = []


static func from_data(character_data: Resource) -> Resource:
	var state := CharacterState.new()
	state.data = character_data
	state.character_id = character_data.id
	state.level = max(1, int(character_data.starting_level))
	if character_data.level_curve != null:
		state.experience = character_data.level_curve.experience_for_level(state.level)
	state.current_hp = state.max_hp()
	state.current_mp = state.max_mp()
	return state


func max_hp() -> int:
	if data == null or data.base_stats == null:
		return 0
	return data.base_stats.value(&"max_hp")


func max_mp() -> int:
	if data == null or data.base_stats == null:
		return 0
	return data.base_stats.value(&"max_mp")


func apply_damage(amount: int) -> void:
	current_hp = clampi(current_hp - max(0, amount), 0, max_hp())


func heal(amount: int) -> void:
	current_hp = clampi(current_hp + max(0, amount), 0, max_hp())


func spend_mp(amount: int) -> Error:
	var cost := max(0, amount)
	if current_mp < cost:
		return ERR_UNAVAILABLE
	current_mp -= cost
	return OK


func restore_mp(amount: int) -> void:
	current_mp = clampi(current_mp + max(0, amount), 0, max_mp())


func is_defeated() -> bool:
	return current_hp <= 0


func grant_experience(amount: int) -> Dictionary:
	if data == null or data.level_curve == null:
		experience += max(0, amount)
		return {
			"experience": experience,
			"old_level": level,
			"level": level,
			"levels_gained": 0,
			"max_level_reached": false,
		}
	var report: Dictionary = data.level_curve.add_experience(experience, amount)
	experience = int(report["experience"])
	level = int(report["level"])
	current_hp = max_hp()
	current_mp = max_mp()
	return report
