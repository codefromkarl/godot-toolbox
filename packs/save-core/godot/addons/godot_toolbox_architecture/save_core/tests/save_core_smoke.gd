extends SceneTree

const SaveCoreScript := preload("res://addons/godot_toolbox_architecture/save_core/save_core.gd")
const SaveSnapshotScript := preload("res://addons/godot_toolbox_architecture/save_core/save_snapshot.gd")

var _failed := false


func _initialize() -> void:
	var save_core: Node = SaveCoreScript.new()
	var payload := {
		"player": {
			"id": "content/player",
			"level": 3,
		},
		"flags": ["intro_complete"],
	}
	var snapshot: Resource = save_core.create_snapshot(payload)
	var roundtrip: Resource = SaveSnapshotScript.from_dictionary(snapshot.to_dictionary())

	_assert(roundtrip.schema_version == SaveCoreScript.CURRENT_SCHEMA_VERSION, "roundtrip should preserve schema version")
	_assert(roundtrip.payload == payload, "roundtrip should preserve payload")

	payload["player"]["level"] = 4
	_assert(snapshot.payload["player"]["level"] == 3, "create_snapshot should deep-copy payload")

	var save_path := "user://save_core_smoke.json"
	var err: Error = save_core.save_json(save_path, snapshot)
	_assert(err == OK, "save_json should write an atomic JSON snapshot")

	var loaded: Resource = save_core.load_json(save_path)
	_assert(loaded != null, "load_json should load a saved snapshot")
	_assert(loaded.schema_version == snapshot.schema_version, "loaded snapshot should preserve schema version")
	_assert(loaded.payload["player"]["id"] == snapshot.payload["player"]["id"], "loaded snapshot should preserve nested payload ids")
	_assert(int(loaded.payload["player"]["level"]) == int(snapshot.payload["player"]["level"]), "loaded snapshot should preserve nested numeric payload values")
	_assert(loaded.payload["flags"][0] == snapshot.payload["flags"][0], "loaded snapshot should preserve array payload values")

	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	save_core.free()
	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true


func _finish() -> void:
	quit(1 if _failed else 0)
