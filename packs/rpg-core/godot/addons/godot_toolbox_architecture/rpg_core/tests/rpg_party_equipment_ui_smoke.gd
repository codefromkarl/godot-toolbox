extends SceneTree

const PartyEquipmentScene := preload("res://scenes/rpg_party/party_equipment.tscn")
const StatBlockScript := preload("res://addons/godot_toolbox_architecture/rpg_core/stats/stat_block.gd")
const StatModifierScript := preload("res://addons/godot_toolbox_architecture/rpg_core/stats/stat_modifier.gd")
const ItemRefScript := preload("res://addons/godot_toolbox_architecture/rpg_core/items/item_ref.gd")
const EquipmentSlotScript := preload("res://addons/godot_toolbox_architecture/rpg_core/equipment/equipment_slot.gd")
const EquipmentLoadoutScript := preload("res://addons/godot_toolbox_architecture/rpg_core/equipment/equipment_loadout.gd")

var _failed := false


func _initialize() -> void:
	var ui: Control = PartyEquipmentScene.instantiate()
	get_root().add_child(ui)
	var stats: Resource = StatBlockScript.new()
	stats.set_base(&"attack", 5)
	var item: Resource = ItemRefScript.new()
	item.item_id = &"item/iron_sword"
	item.equipment_slot = &"weapon"
	item.tags = _string_name_array([&"weapon"])
	item.stat_modifiers = _resource_array([StatModifierScript.add(&"attack", 3, &"iron_sword")])
	var slot: Resource = EquipmentSlotScript.new()
	slot.slot_id = &"weapon"
	slot.accepts_tags = _string_name_array([&"weapon"])
	var loadout: Resource = EquipmentLoadoutScript.new()
	loadout.define_slot(slot)
	ui.configure(stats, loadout, item)
	_assert(ui.get_node("StatOutput").text.contains("Attack: 5"), "Party equipment UI should show base stat")
	ui.equip_candidate()
	_assert(ui.get_node("StatOutput").text.contains("Attack: 8"), "Party equipment UI should show equipment stat contribution")
	ui.queue_free()
	quit(1 if _failed else 0)


func _string_name_array(values: Array) -> Array[StringName]:
	var result: Array[StringName] = []
	for value in values:
		result.append(StringName(str(value)))
	return result


func _resource_array(values: Array) -> Array[Resource]:
	var result: Array[Resource] = []
	for value in values:
		result.append(value)
	return result


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
