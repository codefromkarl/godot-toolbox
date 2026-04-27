extends RefCounted
class_name DamageFormula


static func physical_damage(attacker: Resource, target: Resource, power: int = 0) -> int:
	return max(1, attacker.attack() + max(0, power) - target.defense())


static func magical_damage(attacker: Resource, target: Resource, power: int = 0) -> int:
	var magic_attack: int = attacker.stat(&"magic_attack")
	var magic_defense: int = target.stat(&"magic_defense")
	return max(1, magic_attack + max(0, power) - magic_defense)


static func healing_amount(_source: Resource, power: int = 0) -> int:
	return max(0, power)
