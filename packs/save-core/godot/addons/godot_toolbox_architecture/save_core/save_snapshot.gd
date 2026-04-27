extends Resource
class_name SaveSnapshot

@export var schema_version: int = 1
@export var payload: Dictionary = {}


func to_dictionary() -> Dictionary:
	return {
		"schema_version": schema_version,
		"payload": payload.duplicate(true),
	}


static func from_dictionary(data: Dictionary) -> Resource:
	var snapshot: Resource = load("res://addons/godot_toolbox_architecture/save_core/save_snapshot.gd").new()
	snapshot.schema_version = int(data.get("schema_version", 1))
	var raw_payload: Variant = data.get("payload", {})
	if typeof(raw_payload) == TYPE_DICTIONARY:
		snapshot.payload = (raw_payload as Dictionary).duplicate(true)
	else:
		snapshot.payload = {}
	return snapshot
