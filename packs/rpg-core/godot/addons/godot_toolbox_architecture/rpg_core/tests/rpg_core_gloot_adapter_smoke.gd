extends SceneTree

const ItemRefScript := preload("res://addons/godot_toolbox_architecture/rpg_core/items/item_ref.gd")
const GLootAdapterScript := preload("res://addons/godot_toolbox_architecture/rpg_core/adapters/gloot_adapter.gd")

var _failed := false


func _initialize() -> void:
	var item: Resource = ItemRefScript.new()
	item.item_id = &"item/potion"
	item.quantity = 3
	item.tags = _string_name_array([&"consumable"])
	var payload: Dictionary = GLootAdapterScript.item_ref_to_dictionary(item)
	_assert(payload["id"] == "item/potion", "GLoot adapter should export stable item id")
	_assert(payload["quantity"] == 3, "GLoot adapter should export quantity")
	var restored: Resource = GLootAdapterScript.item_ref_from_dictionary(payload)
	_assert(restored.item_id == &"item/potion", "GLoot adapter should restore stable item id")
	_assert(restored.quantity == 3, "GLoot adapter should restore quantity")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true


func _string_name_array(values: Array) -> Array[StringName]:
	var result: Array[StringName] = []
	for value in values:
		result.append(StringName(str(value)))
	return result
