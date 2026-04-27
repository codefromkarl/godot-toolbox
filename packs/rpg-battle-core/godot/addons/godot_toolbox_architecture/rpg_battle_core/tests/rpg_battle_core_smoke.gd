extends SceneTree

const StatBlockScript := preload("res://addons/godot_toolbox_architecture/rpg_core/stats/stat_block.gd")
const CharacterDataScript := preload("res://addons/godot_toolbox_architecture/rpg_core/characters/character_data.gd")
const CharacterStateScript := preload("res://addons/godot_toolbox_architecture/rpg_core/characters/character_state.gd")
const PartyStateScript := preload("res://addons/godot_toolbox_architecture/rpg_core/party/party_state.gd")
const CombatantStateScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/combat/combatant_state.gd")
const BattleSessionScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/battle/battle_session.gd")
const TurnQueueScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/battle/turn_queue.gd")
const BattleActionScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/actions/battle_action.gd")
const SkillActionScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/actions/skill_action.gd")
const ItemActionScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/actions/item_action.gd")
const TargetRuleScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/targeting/target_rule.gd")
const DamageFormulaScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/formula/damage_formula.gd")
const RewardGrantScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/results/reward_grant.gd")
const DeterministicEnemyAIScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/ai/deterministic_enemy_ai.gd")

var _failed := false


func _initialize() -> void:
	_verify_combatant_state()
	_verify_turn_queue()
	_verify_target_rules()
	_verify_actions_and_formula()
	_verify_rewards()
	_verify_deterministic_battle()
	quit(1 if _failed else 0)


func _verify_combatant_state() -> void:
	var hero := _combatant(&"hero", &"party", 30, 8, 7, 4, 3)
	_assert(hero.current_hp == 30, "combatant should initialize HP")
	_assert(hero.current_mp == 8, "combatant should initialize MP")
	hero.apply_damage(30)
	_assert(hero.is_defeated(), "combatant should detect defeat")


func _verify_turn_queue() -> void:
	var slow := _combatant(&"slow", &"party", 10, 0, 5, 1, 1)
	var fast := _combatant(&"fast", &"party", 10, 0, 10, 1, 1)
	var tied := _combatant(&"alpha", &"party", 10, 0, 10, 1, 1)
	var queue: Resource = TurnQueueScript.new()
	var ordered: Array = queue.order([slow, fast, tied])
	_assert(ordered[0].combatant_id == &"alpha", "turn queue should tie-break by id")
	_assert(ordered[1].combatant_id == &"fast", "turn queue should preserve deterministic speed order")
	_assert(ordered[2].combatant_id == &"slow", "turn queue should put slow combatants last")


func _verify_target_rules() -> void:
	var session: Resource = BattleSessionScript.new()
	session.party = [_combatant(&"hero", &"party", 20, 5, 5, 4, 2)]
	session.enemies = [_combatant(&"slime_a", &"enemy", 8, 0, 2, 1, 0), _combatant(&"slime_b", &"enemy", 8, 0, 2, 1, 0)]
	var rule: Resource = TargetRuleScript.single_enemy()
	_assert(rule.legal_targets(session, session.party[0]).size() == 2, "single enemy rule should expose enemy targets")
	_assert(TargetRuleScript.all_enemies().legal_targets(session, session.party[0]).size() == 2, "all enemies rule should expose all enemies")
	_assert(TargetRuleScript.self_target().legal_targets(session, session.party[0])[0].combatant_id == &"hero", "self rule should target actor")


func _verify_actions_and_formula() -> void:
	var hero := _combatant(&"hero", &"party", 20, 5, 5, 7, 2)
	var slime := _combatant(&"slime", &"enemy", 12, 0, 2, 3, 1)
	_assert(DamageFormulaScript.physical_damage(hero, slime, 4) == 10, "physical damage should use attack, power, and defense")
	_assert(DamageFormulaScript.healing_amount(hero, 6) == 6, "healing should clamp to positive amount")
	var skill: Resource = SkillActionScript.new()
	skill.action_id = &"skill/power_strike"
	skill.mp_cost = 3
	skill.power = 4
	_assert(skill.can_pay_cost(hero), "skill action should allow available MP")
	_assert(skill.apply(hero, [slime]) == OK, "skill action should apply damage")
	_assert(hero.current_mp == 2, "skill action should spend MP")
	_assert(slime.current_hp == 2, "skill action should reduce target HP")
	var item: Resource = ItemActionScript.new()
	item.action_id = &"item/potion"
	item.heal_amount = 5
	hero.apply_damage(6)
	_assert(item.apply(hero, [hero]) == OK, "item action should apply healing")
	_assert(hero.current_hp == 19, "item action should heal target")


func _verify_rewards() -> void:
	var party: Resource = PartyStateScript.new()
	party.add_member(_character_state(&"hero"))
	var grant: Resource = RewardGrantScript.new()
	grant.experience = 25
	grant.gold = 9
	grant.item_ids = _string_name_array([&"item/slime_gel"])
	_assert(grant.apply_to_party(party) == OK, "reward grant should apply to party")
	_assert(party.wallet.amount(&"gold") == 9, "reward grant should add gold")
	_assert(party.member(&"hero").experience == 25, "reward grant should add member XP")


func _verify_deterministic_battle() -> void:
	var session: Resource = BattleSessionScript.new()
	session.party = [_combatant(&"hero", &"party", 28, 4, 8, 8, 2)]
	session.enemies = [_combatant(&"slime", &"enemy", 10, 0, 4, 3, 1)]
	session.reward = RewardGrantScript.new()
	session.reward.experience = 12
	session.reward.gold = 3
	var result: Resource = session.run_to_completion(10)
	_assert(result.outcome == &"victory", "fixed battle should reach victory")
	_assert(session.action_sequence == [&"hero:basic_attack", &"slime:basic_attack", &"hero:basic_attack"], "battle should produce deterministic action sequence")
	var ai: Resource = DeterministicEnemyAIScript.new()
	var replay_a: Array[String] = ai.replay_sequence(session.enemies, session.party, 3)
	var replay_b: Array[String] = ai.replay_sequence(session.enemies, session.party, 3)
	_assert(replay_a == replay_b, "enemy AI replay should be deterministic")


func _combatant(id: StringName, team: StringName, hp: int, mp: int, speed: int, attack: int, defense: int) -> Resource:
	var state := _character_state(id)
	state.data.base_stats.set_base(&"max_hp", hp)
	state.data.base_stats.set_base(&"max_mp", mp)
	state.data.base_stats.set_base(&"speed", speed)
	state.data.base_stats.set_base(&"attack", attack)
	state.data.base_stats.set_base(&"defense", defense)
	state.current_hp = hp
	state.current_mp = mp
	return CombatantStateScript.from_character_state(state, team)


func _character_state(id: StringName) -> Resource:
	var stats: Resource = StatBlockScript.new()
	stats.set_base(&"max_hp", 10)
	stats.set_base(&"max_mp", 5)
	stats.set_base(&"speed", 1)
	stats.set_base(&"attack", 1)
	stats.set_base(&"defense", 0)
	var data: Resource = CharacterDataScript.new()
	data.id = id
	data.display_name = String(id)
	data.base_stats = stats
	return CharacterStateScript.from_data(data)


func _string_name_array(values: Array) -> Array[StringName]:
	var result: Array[StringName] = []
	for value in values:
		result.append(StringName(str(value)))
	return result


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
