extends RefCounted
class_name RPGInventoryEquipmentSaveAdapter


static func serialize_inventory(items: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in items:
		if item == null:
			continue
		if item is Dictionary:
			result.append((item as Dictionary).duplicate(true))
		elif item.has_method("to_dictionary"):
			result.append(item.to_dictionary())
	return result


static func serialize_equipment(equipment_by_member: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for member_id in equipment_by_member.keys():
		var loadout = equipment_by_member[member_id]
		var slots: Dictionary = {}
		if loadout != null and loadout.get("equipped") is Dictionary:
			for slot_id in loadout.equipped.keys():
				var item = loadout.equipped[slot_id]
				if item != null and item.has_method("to_dictionary"):
					slots[String(slot_id)] = item.to_dictionary()
		result[String(member_id)] = slots
	return result


static func deserialize_inventory(items: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in items:
		if typeof(item) == TYPE_DICTIONARY:
			result.append((item as Dictionary).duplicate(true))
	return result


static func deserialize_equipment(data: Dictionary) -> Dictionary:
	return data.duplicate(true)
