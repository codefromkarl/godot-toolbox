extends Resource
class_name ItemAction

@export var action_id: StringName
@export var heal_amount: int = 0
@export var quantity_cost: int = 1


func can_pay_cost(_actor: Resource) -> bool:
	return quantity_cost > 0


func apply(_actor: Resource, targets: Array) -> Error:
	if targets.is_empty():
		return ERR_INVALID_PARAMETER
	for target in targets:
		if target != null:
			target.heal(heal_amount)
	return OK
