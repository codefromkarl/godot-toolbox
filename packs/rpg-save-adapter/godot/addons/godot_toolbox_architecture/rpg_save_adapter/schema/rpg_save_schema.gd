extends RefCounted
class_name RPGSaveSchema

const CURRENT_VERSION := 1


static func migrate(payload: Dictionary) -> Dictionary:
	var result := payload.duplicate(true)
	var version := int(result.get("schema_version", 0))
	if version < 0 or version > CURRENT_VERSION:
		return {}
	if version == 0:
		result["schema_version"] = CURRENT_VERSION
		_ensure_current_keys(result)
		return result
	_ensure_current_keys(result)
	return result


static func validate(payload: Dictionary) -> Dictionary:
	var errors: Array[String] = []
	if not payload.has("schema_version"):
		errors.append("schema_version is required")
	else:
		var version := int(payload.get("schema_version", -1))
		if version < 0 or version > CURRENT_VERSION:
			errors.append("unsupported schema_version: %s" % version)
	for key in ["party", "inventory", "equipment", "quests"]:
		if not payload.has(key):
			errors.append("%s is required" % key)
	if payload.has("party") and typeof(payload["party"]) != TYPE_DICTIONARY:
		errors.append("party must be a dictionary")
	if payload.has("inventory") and typeof(payload["inventory"]) != TYPE_ARRAY:
		errors.append("inventory must be an array")
	if payload.has("equipment") and typeof(payload["equipment"]) != TYPE_DICTIONARY:
		errors.append("equipment must be a dictionary")
	if payload.has("quests") and typeof(payload["quests"]) != TYPE_DICTIONARY:
		errors.append("quests must be a dictionary")
	return {
		"ok": errors.is_empty(),
		"errors": errors,
	}


static func _ensure_current_keys(payload: Dictionary) -> void:
	if not payload.has("party"):
		payload["party"] = {"members": [], "wallet": {}, "active": [], "reserve": []}
	if not payload.has("inventory"):
		payload["inventory"] = []
	if not payload.has("equipment"):
		payload["equipment"] = {}
	if not payload.has("quests"):
		payload["quests"] = {}
