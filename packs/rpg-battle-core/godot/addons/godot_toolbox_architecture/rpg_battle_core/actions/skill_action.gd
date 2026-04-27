extends "res://addons/godot_toolbox_architecture/rpg_battle_core/actions/battle_action.gd"
class_name SkillAction

@export var mp_cost: int = 0


func can_pay_cost(actor: Resource) -> bool:
	return actor != null and actor.current_mp >= max(0, mp_cost)


func apply(actor: Resource, targets: Array) -> Error:
	if not can_pay_cost(actor):
		return ERR_UNAVAILABLE
	var err: int = actor.spend_mp(mp_cost)
	if err != OK:
		return err
	return super.apply(actor, targets)
