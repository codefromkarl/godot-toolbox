extends Resource
class_name CombatantState

@export var combatant_id: StringName
@export var team_id: StringName
@export var character_state: Resource
@export var current_hp: int = 0
@export var current_mp: int = 0
@export var status_ids: Array[StringName] = []


static func from_character_state(state: Resource, team: StringName) -> Resource:
	var combatant := CombatantState.new()
	combatant.character_state = state
	combatant.combatant_id = state.character_id
	combatant.team_id = team
	combatant.current_hp = state.current_hp
	combatant.current_mp = state.current_mp
	combatant.status_ids = state.status_ids.duplicate()
	return combatant


func stat(stat_id: StringName) -> int:
	if character_state == null or character_state.data == null or character_state.data.base_stats == null:
		return 0
	return character_state.data.base_stats.value(stat_id)


func speed() -> int:
	return stat(&"speed")


func attack() -> int:
	return stat(&"attack")


func defense() -> int:
	return stat(&"defense")


func max_hp() -> int:
	return stat(&"max_hp")


func max_mp() -> int:
	return stat(&"max_mp")


func is_defeated() -> bool:
	return current_hp <= 0


func apply_damage(amount: int) -> void:
	current_hp = clampi(current_hp - max(0, amount), 0, max_hp())
	if character_state != null:
		character_state.current_hp = current_hp


func heal(amount: int) -> void:
	current_hp = clampi(current_hp + max(0, amount), 0, max_hp())
	if character_state != null:
		character_state.current_hp = current_hp


func spend_mp(amount: int) -> Error:
	var cost := max(0, amount)
	if current_mp < cost:
		return ERR_UNAVAILABLE
	current_mp -= cost
	if character_state != null:
		character_state.current_mp = current_mp
	return OK
