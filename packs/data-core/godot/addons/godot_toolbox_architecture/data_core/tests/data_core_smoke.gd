extends SceneTree

const DataCoreScript := preload("res://addons/godot_toolbox_architecture/data_core/data_core.gd")
const GameIdScript := preload("res://addons/godot_toolbox_architecture/data_core/game_id.gd")

var _failed := false


func _initialize() -> void:
	var data_core: Node = DataCoreScript.new()
	var first := Resource.new()
	var second := Resource.new()

	_assert(GameIdScript.is_valid_id(&"content/player"), "slash-separated stable ids should be valid")
	_assert(not GameIdScript.is_valid_id(&""), "empty ids should be invalid")
	_assert(not GameIdScript.is_valid_id(&" content/player"), "ids with surrounding whitespace should be invalid")

	_assert(data_core.register_resource(&"content/player", first) == OK, "first registration should succeed")
	_assert(data_core.register_resource(&"content/player", second) == ERR_ALREADY_EXISTS, "duplicates should reject by default")
	_assert(data_core.get_resource(&"content/player") == first, "rejected duplicate should keep the original resource")

	data_core.duplicate_id_policy = DataCoreScript.DuplicateIdPolicy.REPLACE
	_assert(data_core.register_resource(&"content/player", second) == OK, "replace policy should accept duplicate ids")
	_assert(data_core.get_resource(&"content/player") == second, "replace policy should update the registered resource")

	var ids: Array[StringName] = data_core.list_ids()
	_assert(ids.size() == 1, "list_ids should expose registered ids")
	_assert(ids[0] == &"content/player", "list_ids should preserve the registered id")

	data_core.clear()
	_assert(data_core.list_ids().is_empty(), "clear should remove all ids")
	_assert(not data_core.has_resource(&"content/player"), "clear should remove registered resources")

	data_core.free()
	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true


func _finish() -> void:
	quit(1 if _failed else 0)
