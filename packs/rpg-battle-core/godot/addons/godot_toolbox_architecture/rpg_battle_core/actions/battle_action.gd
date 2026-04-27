extends Resource
class_name BattleAction

const TargetRuleScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/targeting/target_rule.gd")
const DamageFormulaScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/formula/damage_formula.gd")

@export var action_id: StringName = &"basic_attack"
@export var power: int = 0
@export var target_rule: Resource = TargetRuleScript.single_enemy()
@export var priority: int = 0


func can_pay_cost(_actor: Resource) -> bool:
	return true


func apply(actor: Resource, targets: Array) -> Error:
	if actor == null or targets.is_empty():
		return ERR_INVALID_PARAMETER
	for target in targets:
		if target != null:
			target.apply_damage(DamageFormulaScript.physical_damage(actor, target, power))
	return OK
