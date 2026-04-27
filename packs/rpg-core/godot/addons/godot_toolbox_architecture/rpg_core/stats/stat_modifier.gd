extends Resource
class_name StatModifier

enum Operation {
	ADD,
	MULTIPLY,
}

@export var stat_id: StringName
@export var operation: Operation = Operation.ADD
@export var value: float = 0.0
@export var source_id: StringName


static func add(target_stat: StringName, amount: float, source: StringName = &"") -> Resource:
	var modifier := StatModifier.new()
	modifier.stat_id = target_stat
	modifier.operation = Operation.ADD
	modifier.value = amount
	modifier.source_id = source
	return modifier


static func multiply(target_stat: StringName, factor: float, source: StringName = &"") -> Resource:
	var modifier := StatModifier.new()
	modifier.stat_id = target_stat
	modifier.operation = Operation.MULTIPLY
	modifier.value = factor
	modifier.source_id = source
	return modifier


func applies_to(target_stat: StringName) -> bool:
	return stat_id == target_stat
