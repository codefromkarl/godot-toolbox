extends Resource
class_name StatBlock

const StatModifierScript := preload("res://addons/godot_toolbox_architecture/rpg_core/stats/stat_modifier.gd")

@export var base_stats: Dictionary = {}
@export var modifiers: Array[Resource] = []


func set_base(stat_id: StringName, amount: int) -> void:
	base_stats[stat_id] = amount


func base_value(stat_id: StringName) -> int:
	return int(base_stats.get(stat_id, 0))


func add_modifier(modifier: Resource) -> Error:
	if modifier == null or not modifier.has_method("applies_to"):
		return ERR_INVALID_PARAMETER
	modifiers.append(modifier)
	return OK


func value(stat_id: StringName, extra_modifiers: Array[Resource] = []) -> int:
	var total := float(base_value(stat_id))
	var multiplier := 1.0
	for modifier in _modifiers_for(stat_id, extra_modifiers):
		match modifier.operation:
			StatModifierScript.Operation.ADD:
				total += float(modifier.value)
			StatModifierScript.Operation.MULTIPLY:
				multiplier *= float(modifier.value)
	return int(round(total * multiplier))


func snapshot(extra_modifiers: Array[Resource] = []) -> Dictionary:
	var result: Dictionary = {}
	var ids := _stat_ids(extra_modifiers)
	for stat_id in ids:
		result[stat_id] = value(stat_id, extra_modifiers)
	return result


func duplicate_block() -> Resource:
	var copy := StatBlock.new()
	copy.base_stats = base_stats.duplicate(true)
	copy.modifiers = modifiers.duplicate()
	return copy


func _stat_ids(extra_modifiers: Array[Resource]) -> Array[StringName]:
	var seen: Dictionary = {}
	for stat_id in base_stats.keys():
		seen[StringName(str(stat_id))] = true
	for modifier in modifiers:
		if modifier != null:
			seen[StringName(str(modifier.stat_id))] = true
	for modifier in extra_modifiers:
		if modifier != null:
			seen[StringName(str(modifier.stat_id))] = true
	var result: Array[StringName] = []
	for stat_id in seen.keys():
		result.append(stat_id)
	result.sort()
	return result


func _modifiers_for(stat_id: StringName, extra_modifiers: Array[Resource]) -> Array[Resource]:
	var result: Array[Resource] = []
	for modifier in modifiers:
		if modifier != null and modifier.applies_to(stat_id):
			result.append(modifier)
	for modifier in extra_modifiers:
		if modifier != null and modifier.applies_to(stat_id):
			result.append(modifier)
	return result
