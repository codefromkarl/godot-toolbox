extends Resource
class_name EquipmentLoadout

@export var slots: Dictionary = {}
@export var equipped: Dictionary = {}


func define_slot(slot: Resource) -> Error:
	if slot == null or String(slot.slot_id).is_empty():
		return ERR_INVALID_PARAMETER
	slots[slot.slot_id] = slot
	return OK


func can_equip(item: Resource) -> bool:
	var slot_id := _slot_for_item(item)
	return not String(slot_id).is_empty()


func equip(item: Resource) -> Error:
	var slot_id := _slot_for_item(item)
	if String(slot_id).is_empty():
		return ERR_INVALID_PARAMETER
	equipped[slot_id] = item
	return OK


func unequip(slot_id: StringName) -> Resource:
	var previous: Resource = equipped.get(slot_id)
	equipped.erase(slot_id)
	return previous


func equipped_item(slot_id: StringName) -> Resource:
	return equipped.get(slot_id)


func stat_modifiers() -> Array[Resource]:
	var result: Array[Resource] = []
	for item in equipped.values():
		if item == null:
			continue
		for modifier in item.stat_modifiers:
			if modifier != null:
				result.append(modifier)
	return result


func _slot_for_item(item: Resource) -> StringName:
	if item == null:
		return &""
	if not String(item.equipment_slot).is_empty() and slots.has(item.equipment_slot):
		var direct_slot: Resource = slots[item.equipment_slot]
		if direct_slot.accepts(item):
			return item.equipment_slot
	for slot_id in slots.keys():
		var slot: Resource = slots[slot_id]
		if slot.accepts(item):
			return slot_id
	return &""
