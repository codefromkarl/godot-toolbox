extends Resource
class_name SaveSlot

@export var id: StringName
@export var display_name: String
@export var path: String
@export var updated_at_unix: int = 0
@export var schema_version: int = 1


func to_dictionary() -> Dictionary:
	return {
		"id": String(id),
		"display_name": display_name,
		"path": path,
		"updated_at_unix": updated_at_unix,
		"schema_version": schema_version,
	}
