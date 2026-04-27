extends Resource
class_name EquipmentSlot

@export var slot_id: StringName
@export var accepts_tags: Array[StringName] = []


func accepts(item: Resource) -> bool:
	if item == null or not item.has_method("is_valid") or not item.is_valid():
		return false
	if item.equipment_slot == slot_id:
		return true
	for tag in accepts_tags:
		if item.has_method("has_tag") and item.has_tag(tag):
			return true
	return false
