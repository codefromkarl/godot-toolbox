extends Node
class_name RPGSaveAdapterService

const PACK_ID := "rpg-save-adapter"
const REQUIRED_CONTRACTS: Array[StringName] = [&"rpg-core", &"save-core", &"rules-events-core"]
const RPGSaveSchemaScript := preload("res://addons/godot_toolbox_architecture/rpg_save_adapter/schema/rpg_save_schema.gd")
const InventoryEquipmentAdapterScript := preload("res://addons/godot_toolbox_architecture/rpg_save_adapter/adapters/inventory_equipment_save_adapter.gd")
const QuestAdapterScript := preload("res://addons/godot_toolbox_architecture/rpg_save_adapter/adapters/quest_save_adapter.gd")


func pack_id() -> String:
	return PACK_ID


func required_contracts() -> Array[StringName]:
	return REQUIRED_CONTRACTS.duplicate()


func schema_version() -> int:
	return RPGSaveSchemaScript.CURRENT_VERSION


func to_payload(
	party: Resource,
	inventory: Array = [],
	equipment_by_member: Dictionary = {},
	quest_state: Dictionary = {}
) -> Dictionary:
	return {
		"schema_version": schema_version(),
		"party": _serialize_party(party),
		"inventory": InventoryEquipmentAdapterScript.serialize_inventory(inventory),
		"equipment": InventoryEquipmentAdapterScript.serialize_equipment(equipment_by_member),
		"quests": QuestAdapterScript.serialize(quest_state),
	}


func from_payload(payload: Dictionary) -> Dictionary:
	var migrated: Dictionary = RPGSaveSchemaScript.migrate(payload)
	var report: Dictionary = RPGSaveSchemaScript.validate(migrated)
	if not bool(report["ok"]):
		return {
			"schema_version": -1,
			"errors": report["errors"],
			"party": {},
			"inventory": [],
			"equipment": {},
			"quests": {},
		}
	return {
		"schema_version": int(migrated["schema_version"]),
		"party": (migrated["party"] as Dictionary).duplicate(true),
		"inventory": InventoryEquipmentAdapterScript.deserialize_inventory(migrated["inventory"]),
		"equipment": InventoryEquipmentAdapterScript.deserialize_equipment(migrated["equipment"]),
		"quests": QuestAdapterScript.deserialize(migrated["quests"]),
	}


func validate_payload(payload: Dictionary) -> Dictionary:
	var migrated: Dictionary = RPGSaveSchemaScript.migrate(payload)
	if migrated.is_empty():
		return {
			"ok": false,
			"errors": ["unsupported schema_version"],
		}
	return RPGSaveSchemaScript.validate(migrated)


func _serialize_party(party: Resource) -> Dictionary:
	if party == null:
		return {
			"members": [],
			"active": [],
			"reserve": [],
			"wallet": {},
		}
	var members: Array[Dictionary] = []
	for member in party.members:
		if member == null:
			continue
		members.append({
			"id": String(member.character_id),
			"level": member.level,
			"experience": member.experience,
			"current_hp": member.current_hp,
			"current_mp": member.current_mp,
			"statuses": _string_names_to_strings(member.status_ids),
		})
	return {
		"members": members,
		"active": _string_names_to_strings(party.active_member_ids),
		"reserve": _string_names_to_strings(party.reserve_member_ids),
		"wallet": party.wallet.to_dictionary(),
	}


func _string_names_to_strings(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(String(value))
	return result
