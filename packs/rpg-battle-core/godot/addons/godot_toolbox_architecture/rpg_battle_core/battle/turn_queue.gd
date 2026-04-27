extends Resource
class_name TurnQueue


func order(combatants: Array) -> Array:
	var alive: Array = []
	for combatant in combatants:
		if combatant != null and not combatant.is_defeated():
			alive.append(combatant)
	alive.sort_custom(_compare_combatants)
	return alive


func _compare_combatants(a: Resource, b: Resource) -> bool:
	if a.speed() == b.speed():
		return String(a.combatant_id) < String(b.combatant_id)
	return a.speed() > b.speed()
