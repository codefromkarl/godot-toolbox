extends Node
class_name DataCoreService

signal resource_registered(id: StringName, resource: Resource)
signal resource_replaced(id: StringName, previous_resource: Resource, resource: Resource)
signal registry_cleared()

enum DuplicateIdPolicy {
	REJECT,
	REPLACE,
	KEEP_EXISTING,
}

const GameIdScript := preload("res://addons/godot_toolbox_architecture/data_core/game_id.gd")

var _resources: Dictionary = {}
var duplicate_id_policy: DuplicateIdPolicy = DuplicateIdPolicy.REJECT


func register_resource(id: StringName, resource: Resource) -> Error:
	if not GameIdScript.is_valid_id(id):
		push_error("DataCore.register_resource requires a stable id.")
		return ERR_INVALID_PARAMETER
	if resource == null:
		push_error("DataCore.register_resource requires a resource.")
		return ERR_INVALID_PARAMETER
	if _resources.has(id):
		match duplicate_id_policy:
			DuplicateIdPolicy.REJECT:
				return ERR_ALREADY_EXISTS
			DuplicateIdPolicy.KEEP_EXISTING:
				return OK
			DuplicateIdPolicy.REPLACE:
				var previous_resource: Resource = _resources[id]
				_resources[id] = resource
				resource_replaced.emit(id, previous_resource, resource)
				return OK
	_resources[id] = resource
	resource_registered.emit(id, resource)
	return OK


func get_resource(id: StringName) -> Resource:
	return _resources.get(id)


func has_resource(id: StringName) -> bool:
	return _resources.has(id)


func list_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for id in _resources.keys():
		result.append(id)
	result.sort()
	return result


func ids() -> Array[StringName]:
	return list_ids()


func clear() -> void:
	if _resources.is_empty():
		return
	_resources.clear()
	registry_cleared.emit()
