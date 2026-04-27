extends Resource
class_name ItemRef

@export var item_id: StringName
@export var quantity: int = 1
@export var equipment_slot: StringName
@export var tags: Array[StringName] = []
@export var stat_modifiers: Array[Resource] = []
@export var metadata: Dictionary = {}


func is_valid() -> bool:
	return not String(item_id).is_empty() and quantity > 0


func has_tag(tag: StringName) -> bool:
	return tags.has(tag)


func to_dictionary() -> Dictionary:
	var tag_text: Array[String] = []
	for tag in tags:
		tag_text.append(String(tag))
	return {
		"id": String(item_id),
		"quantity": quantity,
		"equipment_slot": String(equipment_slot),
		"tags": tag_text,
		"metadata": metadata.duplicate(true),
	}
