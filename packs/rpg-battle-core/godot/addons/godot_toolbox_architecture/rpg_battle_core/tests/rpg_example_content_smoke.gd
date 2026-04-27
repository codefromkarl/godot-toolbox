extends SceneTree

const StatBlockScript := preload("res://addons/godot_toolbox_architecture/rpg_core/stats/stat_block.gd")
const CharacterDataScript := preload("res://addons/godot_toolbox_architecture/rpg_core/characters/character_data.gd")
const CharacterStateScript := preload("res://addons/godot_toolbox_architecture/rpg_core/characters/character_state.gd")
const CombatantStateScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/combat/combatant_state.gd")
const BattleSessionScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/battle/battle_session.gd")
const RewardGrantScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/results/reward_grant.gd")

var _failed := false


func _initialize() -> void:
	var content: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://content/rpg_example/rpg_example_content.json"))
	_assert(content["heroes"].size() >= 2, "example content should include at least two heroes")
	_assert(content["enemies"].size() >= 3, "example content should include at least three enemies")
	_assert(content["skills"].size() >= 5, "example content should include at least five skills")
	_assert(content["items"].size() >= 5, "example content should include at least five items")
	_assert(content["equipment"].size() >= 3, "example content should include at least three equipment pieces")
	var session: Resource = BattleSessionScript.new()
	session.party = [_combatant(content["heroes"][0], &"party")]
	session.enemies = [_combatant(content["enemies"][0], &"enemy")]
	session.reward = RewardGrantScript.new()
	session.reward.experience = int(content["enemies"][0]["reward_xp"])
	session.reward.gold = int(content["enemies"][0]["reward_gold"])
	var result: Resource = session.run_to_completion(10)
	_assert(result.outcome == &"victory", "example content should drive fixed battle victory")
	quit(1 if _failed else 0)


func _combatant(data: Dictionary, team: StringName) -> Resource:
	var stats: Resource = StatBlockScript.new()
	for stat_id in data["stats"].keys():
		stats.set_base(StringName(str(stat_id)), int(data["stats"][stat_id]))
	var character_data: Resource = CharacterDataScript.new()
	character_data.id = StringName(str(data["id"]))
	character_data.display_name = str(data["name"])
	character_data.base_stats = stats
	var state: Resource = CharacterStateScript.from_data(character_data)
	return CombatantStateScript.from_character_state(state, team)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
