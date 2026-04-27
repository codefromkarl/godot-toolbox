extends Resource
class_name DeterministicEnemyAI

const BattleActionScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/actions/battle_action.gd")


func choose_action(_session: Resource, _actor: Resource) -> Resource:
	var action: Resource = BattleActionScript.new()
	action.action_id = &"basic_attack"
	return action


func replay_sequence(enemies: Array, party: Array, turns: int) -> Array[String]:
	var result: Array[String] = []
	if enemies.is_empty() or party.is_empty():
		return result
	var actor = enemies[0]
	for _i in range(max(0, turns)):
		result.append("%s:basic_attack" % String(actor.combatant_id))
	return result
