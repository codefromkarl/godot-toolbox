extends Resource
class_name BattleSession

const TurnQueueScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/battle/turn_queue.gd")
const BattleActionScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/actions/battle_action.gd")
const BattleResultScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/results/battle_result.gd")
const DeterministicEnemyAIScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/ai/deterministic_enemy_ai.gd")

@export var party: Array = []
@export var enemies: Array = []
@export var reward: Resource
@export var phase: StringName = &"ready"
@export var turn_index: int = 0
@export var battle_log: Array[Dictionary] = []
@export var action_sequence: Array[StringName] = []
@export var result: Resource

var enemy_ai: Resource = DeterministicEnemyAIScript.new()


func all_combatants() -> Array:
	var result_list: Array = []
	result_list.append_array(party)
	result_list.append_array(enemies)
	return result_list


func alive_team(team_id: StringName) -> Array:
	var result_list: Array = []
	for combatant in all_combatants():
		if combatant != null and combatant.team_id == team_id and not combatant.is_defeated():
			result_list.append(combatant)
	return result_list


func alive_opponents(team_id: StringName) -> Array:
	var result_list: Array = []
	for combatant in all_combatants():
		if combatant != null and combatant.team_id != team_id and not combatant.is_defeated():
			result_list.append(combatant)
	return result_list


func is_finished() -> bool:
	return alive_team(&"party").is_empty() or alive_team(&"enemy").is_empty()


func run_to_completion(max_turns: int = 20) -> Resource:
	phase = &"running"
	var queue: Resource = TurnQueueScript.new()
	for _round_index in range(max(1, max_turns)):
		for actor in queue.order(all_combatants()):
			if actor.is_defeated() or is_finished():
				continue
			var action: Resource = _action_for(actor)
			var targets := _targets_for(actor)
			if targets.is_empty():
				continue
			action.apply(actor, [targets[0]])
			action_sequence.append(StringName("%s:%s" % [String(actor.combatant_id), String(action.action_id)]))
			battle_log.append({
				"actor": String(actor.combatant_id),
				"action": String(action.action_id),
				"target": String(targets[0].combatant_id),
			})
			if is_finished():
				return _finish_result()
	return _finish_result()


func _action_for(actor: Resource) -> Resource:
	if actor.team_id == &"enemy":
		return enemy_ai.choose_action(self, actor)
	var action: Resource = BattleActionScript.new()
	action.action_id = &"basic_attack"
	return action


func _targets_for(actor: Resource) -> Array:
	if actor.team_id == &"party":
		return alive_opponents(&"party")
	return alive_opponents(&"enemy")


func _finish_result() -> Resource:
	result = BattleResultScript.new()
	if alive_team(&"enemy").is_empty() and not alive_team(&"party").is_empty():
		result.outcome = &"victory"
		result.winner_team = &"party"
		result.reward = reward
	elif alive_team(&"party").is_empty():
		result.outcome = &"defeat"
		result.winner_team = &"enemy"
	else:
		result.outcome = &"draw"
	phase = &"finished"
	return result
