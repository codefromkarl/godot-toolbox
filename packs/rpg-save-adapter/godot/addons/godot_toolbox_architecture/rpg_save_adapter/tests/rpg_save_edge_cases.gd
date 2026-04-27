extends SceneTree

const RPGSaveAdapterScript := preload("res://addons/godot_toolbox_architecture/rpg_save_adapter/rpg_save_adapter.gd")
const RPGSaveSchemaScript := preload("res://addons/godot_toolbox_architecture/rpg_save_adapter/schema/rpg_save_schema.gd")

var _failed := false


func _initialize() -> void:
	_verify_legacy_missing_fields_migrate()
	var malformed_errors := _verify_malformed_current_payload_rejects()
	var unsupported_schema := _verify_unsupported_schema_returns_error_payload()
	if not _failed:
		print("RPG_EDGE_SAVE_OK migrated_schema=%s malformed_errors=%s unsupported_schema=%s" % [
			RPGSaveSchemaScript.CURRENT_VERSION,
			malformed_errors,
			unsupported_schema,
		])
	quit(1 if _failed else 0)


func _verify_legacy_missing_fields_migrate() -> void:
	var adapter: Node = RPGSaveAdapterScript.new()
	var restored: Dictionary = adapter.from_payload({
		"schema_version": 0,
		"party": {"members": [], "wallet": {"gold": 0}, "active": [], "reserve": []},
	})
	_assert(restored["schema_version"] == RPGSaveSchemaScript.CURRENT_VERSION, "legacy payload should migrate to current schema")
	_assert(restored["inventory"] == [], "legacy payload should default missing inventory")
	_assert(restored["equipment"] == {}, "legacy payload should default missing equipment")
	_assert(restored["quests"] == {}, "legacy payload should default missing quests")
	adapter.free()


func _verify_malformed_current_payload_rejects() -> int:
	var adapter: Node = RPGSaveAdapterScript.new()
	var report: Dictionary = adapter.validate_payload({
		"schema_version": RPGSaveSchemaScript.CURRENT_VERSION,
		"party": [],
		"inventory": {},
		"equipment": [],
		"quests": [],
	})
	_assert(report["ok"] == false, "malformed current payload should be rejected")
	var errors: Array = report["errors"]
	_assert(errors.has("party must be a dictionary"), "malformed payload should report party type")
	_assert(errors.has("inventory must be an array"), "malformed payload should report inventory type")
	_assert(errors.has("equipment must be a dictionary"), "malformed payload should report equipment type")
	_assert(errors.has("quests must be a dictionary"), "malformed payload should report quests type")
	adapter.free()
	return errors.size()


func _verify_unsupported_schema_returns_error_payload() -> int:
	var adapter: Node = RPGSaveAdapterScript.new()
	var unsupported := {
		"schema_version": RPGSaveSchemaScript.CURRENT_VERSION + 100,
		"party": {},
		"inventory": [],
		"equipment": {},
		"quests": {},
	}
	var report: Dictionary = adapter.validate_payload(unsupported)
	_assert(report["ok"] == false, "unsupported schema should fail validation")
	_assert((report["errors"] as Array).has("unsupported schema_version"), "unsupported schema should report schema validation error")
	var restored: Dictionary = adapter.from_payload(unsupported)
	_assert(restored["schema_version"] == -1, "unsupported schema should return error payload")
	_assert(not (restored["errors"] as Array).is_empty(), "unsupported schema error payload should include errors")
	_assert(restored["party"] == {}, "unsupported schema should not leak malformed party state")
	_assert(restored["inventory"] == [], "unsupported schema should not leak malformed inventory")
	_assert(restored["equipment"] == {}, "unsupported schema should not leak malformed equipment")
	var restored_schema: int = int(restored.get("schema_version", 0))
	adapter.free()
	return restored_schema


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
