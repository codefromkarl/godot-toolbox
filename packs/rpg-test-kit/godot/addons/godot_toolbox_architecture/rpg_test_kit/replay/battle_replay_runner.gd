extends RefCounted
class_name RPGBattleReplayRunner

const StatBlockScript := preload("res://addons/godot_toolbox_architecture/rpg_core/stats/stat_block.gd")
const CharacterDataScript := preload("res://addons/godot_toolbox_architecture/rpg_core/characters/character_data.gd")
const CharacterStateScript := preload("res://addons/godot_toolbox_architecture/rpg_core/characters/character_state.gd")
const CombatantStateScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/combat/combatant_state.gd")
const BattleSessionScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/battle/battle_session.gd")
const RewardGrantScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/results/reward_grant.gd")


func run_fixture(fixture: Dictionary) -> Dictionary:
	var session: Resource = BattleSessionScript.new()
	session.party = _combatants(fixture.get("party", []), &"party")
	session.enemies = _combatants(fixture.get("enemies", []), &"enemy")
	var reward: Resource = RewardGrantScript.new()
	var reward_data: Dictionary = fixture.get("reward", {})
	reward.experience = int(reward_data.get("experience", 0))
	reward.gold = int(reward_data.get("gold", 0))
	session.reward = reward
	var result: Resource = session.run_to_completion(int(fixture.get("max_turns", 20)))
	return {
		"outcome": String(result.outcome),
		"action_sequence": _string_names_to_strings(session.action_sequence),
		"events": session.event_stream.to_array(),
	}


func _combatants(rows: Array, fallback_team: StringName) -> Array:
	var result: Array = []
	for row in rows:
		if typeof(row) == TYPE_DICTIONARY:
			result.append(_combatant(row, fallback_team))
	return result


func _combatant(row: Dictionary, fallback_team: StringName) -> Resource:
	var stats: Resource = StatBlockScript.new()
	for stat_id in (row.get("stats", {}) as Dictionary).keys():
		stats.set_base(StringName(str(stat_id)), int(row["stats"][stat_id]))
	var data: Resource = CharacterDataScript.new()
	data.id = StringName(str(row.get("id", "")))
	data.display_name = str(row.get("name", row.get("id", "")))
	data.base_stats = stats
	var state: Resource = CharacterStateScript.from_data(data)
	return CombatantStateScript.from_character_state(state, StringName(str(row.get("team", fallback_team))))


func _string_names_to_strings(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(String(value))
	return result
