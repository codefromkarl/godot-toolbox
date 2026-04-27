extends RefCounted
class_name RPGGLootAdapter

const ItemRefScript := preload("res://addons/godot_toolbox_architecture/rpg_core/items/item_ref.gd")


static func item_ref_to_dictionary(item: Resource) -> Dictionary:
	if item == null:
		return {}
	return item.to_dictionary()


static func item_ref_from_dictionary(data: Dictionary) -> Resource:
	var item: Resource = ItemRefScript.new()
	item.item_id = StringName(str(data.get("id", "")))
	item.quantity = max(1, int(data.get("quantity", 1)))
	item.equipment_slot = StringName(str(data.get("equipment_slot", "")))
	var tags: Array[StringName] = []
	var raw_tags: Variant = data.get("tags", [])
	if typeof(raw_tags) == TYPE_ARRAY:
		for tag in raw_tags:
			tags.append(StringName(str(tag)))
	item.tags = tags
	var raw_metadata: Variant = data.get("metadata", {})
	if typeof(raw_metadata) == TYPE_DICTIONARY:
		item.metadata = (raw_metadata as Dictionary).duplicate(true)
	return item


static func has_gloot_runtime() -> bool:
	return ClassDB.class_exists("Inventory") or ClassDB.class_exists("InventoryItem")
