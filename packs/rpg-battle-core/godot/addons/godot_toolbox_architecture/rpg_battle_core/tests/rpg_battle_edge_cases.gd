extends SceneTree

const StatBlockScript := preload("res://addons/godot_toolbox_architecture/rpg_core/stats/stat_block.gd")
const CharacterDataScript := preload("res://addons/godot_toolbox_architecture/rpg_core/characters/character_data.gd")
const CharacterStateScript := preload("res://addons/godot_toolbox_architecture/rpg_core/characters/character_state.gd")
const CombatantStateScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/combat/combatant_state.gd")
const TurnQueueScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/battle/turn_queue.gd")
const DamageFormulaScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/formula/damage_formula.gd")
const DeterministicEnemyAIScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/ai/deterministic_enemy_ai.gd")

var _failed := false


func _initialize() -> void:
	_verify_formula_clamps()
	_verify_turn_queue_filters_and_ties()
	_verify_deterministic_ai_boundaries()
	if not _failed:
		print("RPG_EDGE_BATTLE_OK formula_min=1 heal_negative=0 queue=alpha,beta,slow ai_empty=0")
	quit(1 if _failed else 0)


func _verify_formula_clamps() -> void:
	var attacker := _combatant(&"attacker", &"party", 12, 2, 3, 0, 0)
	var defender := _combatant(&"defender", &"enemy", 12, 0, 3, 0, 99)
	_assert(DamageFormulaScript.physical_damage(attacker, defender, -50) == 1, "physical damage should clamp negative power and keep minimum damage")
	_assert(DamageFormulaScript.magical_damage(attacker, defender, -50) == 1, "magical damage should clamp negative power and keep minimum damage")
	_assert(DamageFormulaScript.healing_amount(attacker, -9) == 0, "healing should clamp negative power to zero")
	var hp_before: int = attacker.current_hp
	var mp_before: int = attacker.current_mp
	attacker.apply_damage(-99)
	_assert(attacker.current_hp == hp_before, "negative damage should not heal or damage")
	_assert(attacker.spend_mp(-7) == OK, "negative MP cost should be treated as zero")
	_assert(attacker.current_mp == mp_before, "negative MP cost should not change MP")


func _verify_turn_queue_filters_and_ties() -> void:
	var dead_fast := _combatant(&"dead_fast", &"party", 10, 0, 99, 1, 0)
	dead_fast.apply_damage(99)
	var alpha := _combatant(&"alpha", &"party", 10, 0, 5, 1, 0)
	var beta := _combatant(&"beta", &"party", 10, 0, 5, 1, 0)
	var slow := _combatant(&"slow", &"party", 10, 0, -2, 1, 0)
	var queue: Resource = TurnQueueScript.new()
	var ordered: Array = queue.order([dead_fast, null, slow, beta, alpha])
	_assert(ordered.size() == 3, "turn queue should filter null and defeated combatants")
	_assert(ordered[0].combatant_id == &"alpha", "turn queue should tie-break equal speed by id")
	_assert(ordered[1].combatant_id == &"beta", "turn queue should keep deterministic id order for ties")
	_assert(ordered[2].combatant_id == &"slow", "turn queue should keep negative speed combatants last")


func _verify_deterministic_ai_boundaries() -> void:
	var ai: Resource = DeterministicEnemyAIScript.new()
	var enemy := _combatant(&"enemy", &"enemy", 10, 0, 1, 1, 0)
	var hero := _combatant(&"hero", &"party", 10, 0, 1, 1, 0)
	_assert(ai.replay_sequence([], [hero], 3).is_empty(), "AI replay should return no actions without enemies")
	_assert(ai.replay_sequence([enemy], [], 3).is_empty(), "AI replay should return no actions without party")
	_assert(ai.replay_sequence([enemy], [hero], -4).is_empty(), "AI replay should clamp negative turns to zero")
	_assert(ai.replay_sequence([enemy], [hero], 2) == ["enemy:basic_attack", "enemy:basic_attack"], "AI replay should remain deterministic")


func _combatant(id: StringName, team: StringName, hp: int, mp: int, speed: int, attack: int, defense: int) -> Resource:
	var stats: Resource = StatBlockScript.new()
	stats.set_base(&"max_hp", hp)
	stats.set_base(&"max_mp", mp)
	stats.set_base(&"speed", speed)
	stats.set_base(&"attack", attack)
	stats.set_base(&"defense", defense)
	var data: Resource = CharacterDataScript.new()
	data.id = id
	data.display_name = String(id)
	data.base_stats = stats
	var state: Resource = CharacterStateScript.from_data(data)
	return CombatantStateScript.from_character_state(state, team)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
