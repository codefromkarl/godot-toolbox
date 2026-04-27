extends RefCounted
class_name ExecutionContext

var event: GameEvent
var memory: Dictionary = {}
var results: Array[Dictionary] = []


func read(scope: StringName, key: StringName, default_value: Variant = null) -> Variant:
	var bucket: Dictionary = memory.get(scope, {})
	return bucket.get(key, default_value)


func write(scope: StringName, key: StringName, value: Variant) -> void:
	if not memory.has(scope):
		memory[scope] = {}
	memory[scope][key] = value
