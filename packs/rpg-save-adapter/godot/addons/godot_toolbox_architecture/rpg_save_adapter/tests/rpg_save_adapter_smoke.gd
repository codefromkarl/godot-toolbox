extends SceneTree

const SaveCoreScript := preload("res://addons/godot_toolbox_architecture/save_core/save_core.gd")
const StatBlockScript := preload("res://addons/godot_toolbox_architecture/rpg_core/stats/stat_block.gd")
const CharacterDataScript := preload("res://addons/godot_toolbox_architecture/rpg_core/characters/character_data.gd")
const CharacterStateScript := preload("res://addons/godot_toolbox_architecture/rpg_core/characters/character_state.gd")
const PartyStateScript := preload("res://addons/godot_toolbox_architecture/rpg_core/party/party_state.gd")
const ItemRefScript := preload("res://addons/godot_toolbox_architecture/rpg_core/items/item_ref.gd")
const EquipmentSlotScript := preload("res://addons/godot_toolbox_architecture/rpg_core/equipment/equipment_slot.gd")
const EquipmentLoadoutScript := preload("res://addons/godot_toolbox_architecture/rpg_core/equipment/equipment_loadout.gd")
const RPGSaveAdapterScript := preload("res://addons/godot_toolbox_architecture/rpg_save_adapter/rpg_save_adapter.gd")
const RPGSaveSchemaScript := preload("res://addons/godot_toolbox_architecture/rpg_save_adapter/schema/rpg_save_schema.gd")

var _failed := false


func _initialize() -> void:
	_verify_roundtrip()
	_verify_migration_and_rejection()
	quit(1 if _failed else 0)


func _verify_roundtrip() -> void:
	var party := _party()
	var inventory: Array[Resource] = [_item(&"item/potion", 2)]
	var loadout: Resource = _loadout(_item(&"item/iron_sword", 1))
	var adapter: Node = RPGSaveAdapterScript.new()
	var payload: Dictionary = adapter.to_payload(party, inventory, {"hero/lyra": loadout}, {"quest/tutorial": {"state": "completed"}})
	var save_core: Node = SaveCoreScript.new()
	var snapshot: Resource = save_core.create_snapshot(payload)
	var restored: Dictionary = adapter.from_payload(snapshot.payload)
	_assert(restored["schema_version"] == RPGSaveSchemaScript.CURRENT_VERSION, "save payload should keep RPG schema version")
	_assert(restored["party"]["wallet"]["gold"] == 42, "roundtrip should preserve wallet")
	_assert(restored["party"]["members"][0]["id"] == "hero/lyra", "roundtrip should preserve party member id")
	_assert(restored["inventory"][0]["id"] == "item/potion", "roundtrip should preserve inventory refs")
	_assert(restored["equipment"]["hero/lyra"]["weapon"]["id"] == "item/iron_sword", "roundtrip should preserve equipment refs")
	_assert(restored["quests"]["quest/tutorial"]["state"] == "completed", "roundtrip should preserve quest state")
	adapter.free()
	save_core.free()


func _verify_migration_and_rejection() -> void:
	var adapter: Node = RPGSaveAdapterScript.new()
	var migrated: Dictionary = adapter.from_payload({"schema_version": 0, "party": {"members": [], "wallet": {}}, "inventory": [], "equipment": {}, "quests": {}})
	_assert(migrated["schema_version"] == RPGSaveSchemaScript.CURRENT_VERSION, "old save payload should migrate to current schema")
	_assert(adapter.validate_payload({"schema_version": 999})["ok"] == false, "malformed payload should be rejected")
	adapter.free()


func _party() -> Resource:
	var party: Resource = PartyStateScript.new()
	party.add_member(_character_state(&"hero/lyra"))
	party.wallet.add(&"gold", 42)
	return party


func _character_state(id: StringName) -> Resource:
	var stats: Resource = StatBlockScript.new()
	stats.set_base(&"max_hp", 30)
	stats.set_base(&"max_mp", 10)
	var data: Resource = CharacterDataScript.new()
	data.id = id
	data.display_name = "Lyra"
	data.base_stats = stats
	var state: Resource = CharacterStateScript.from_data(data)
	state.experience = 15
	state.level = 2
	state.current_hp = 21
	state.current_mp = 7
	return state


func _item(id: StringName, quantity: int) -> Resource:
	var item: Resource = ItemRefScript.new()
	item.item_id = id
	item.quantity = quantity
	item.equipment_slot = &"weapon"
	item.tags = _string_name_array([&"weapon"])
	return item


func _loadout(item: Resource) -> Resource:
	var slot: Resource = EquipmentSlotScript.new()
	slot.slot_id = &"weapon"
	slot.accepts_tags = _string_name_array([&"weapon"])
	var loadout: Resource = EquipmentLoadoutScript.new()
	loadout.define_slot(slot)
	loadout.equip(item)
	return loadout


func _string_name_array(values: Array) -> Array[StringName]:
	var result: Array[StringName] = []
	for value in values:
		result.append(StringName(str(value)))
	return result


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
