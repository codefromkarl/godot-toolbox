extends SceneTree

const StatBlockScript := preload("res://addons/godot_toolbox_architecture/rpg_core/stats/stat_block.gd")
const StatModifierScript := preload("res://addons/godot_toolbox_architecture/rpg_core/stats/stat_modifier.gd")
const LevelCurveScript := preload("res://addons/godot_toolbox_architecture/rpg_core/progression/level_curve.gd")
const CharacterDataScript := preload("res://addons/godot_toolbox_architecture/rpg_core/characters/character_data.gd")
const CharacterStateScript := preload("res://addons/godot_toolbox_architecture/rpg_core/characters/character_state.gd")
const PartyStateScript := preload("res://addons/godot_toolbox_architecture/rpg_core/party/party_state.gd")
const WalletScript := preload("res://addons/godot_toolbox_architecture/rpg_core/party/wallet.gd")
const ItemRefScript := preload("res://addons/godot_toolbox_architecture/rpg_core/items/item_ref.gd")
const EquipmentSlotScript := preload("res://addons/godot_toolbox_architecture/rpg_core/equipment/equipment_slot.gd")
const EquipmentLoadoutScript := preload("res://addons/godot_toolbox_architecture/rpg_core/equipment/equipment_loadout.gd")

var _failed := false


func _initialize() -> void:
	_verify_stats()
	_verify_level_curve()
	_verify_character_state_isolation()
	_verify_party_and_wallet()
	_verify_equipment_contracts()
	quit(1 if _failed else 0)


func _verify_stats() -> void:
	var stats: Resource = StatBlockScript.new()
	stats.set_base(&"attack", 10)
	stats.add_modifier(StatModifierScript.add(&"attack", 5, &"sword"))
	stats.add_modifier(StatModifierScript.multiply(&"attack", 1.5, &"stance"))
	_assert(stats.value(&"attack") == 23, "stat block should apply additive before multiplicative modifiers")
	_assert(stats.snapshot()[&"attack"] == 23, "stat block should expose deterministic snapshot")


func _verify_level_curve() -> void:
	var curve: Resource = LevelCurveScript.new()
	curve.thresholds = _int_array([0, 100, 250])
	_assert(curve.level_for_experience(0) == 1, "zero XP should be level 1")
	_assert(curve.level_for_experience(250) == 3, "threshold XP should reach max level")
	var report: Dictionary = curve.add_experience(90, 200)
	_assert(report["level"] == 3, "multi-level XP gain should reach level 3")
	_assert(report["levels_gained"] == 2, "multi-level XP gain should report gained levels")


func _verify_character_state_isolation() -> void:
	var stats: Resource = StatBlockScript.new()
	stats.set_base(&"max_hp", 40)
	stats.set_base(&"max_mp", 12)
	var data: Resource = CharacterDataScript.new()
	data.id = &"hero/lyra"
	data.display_name = "Lyra"
	data.base_stats = stats
	var state: Resource = CharacterStateScript.from_data(data)
	state.apply_damage(15)
	state.spend_mp(5)
	_assert(state.current_hp == 25, "runtime damage should update character state")
	_assert(state.current_mp == 7, "runtime MP spend should update character state")
	_assert(data.base_stats.value(&"max_hp") == 40, "runtime state must not mutate static character data")


func _verify_party_and_wallet() -> void:
	var party: Resource = PartyStateScript.new()
	party.max_active_members = 1
	var first: Resource = _character_state(&"hero/first")
	var second: Resource = _character_state(&"hero/second")
	_assert(party.add_member(first) == OK, "party should add first member")
	_assert(party.add_member(second) == OK, "party should add reserve member")
	_assert(party.active_member_ids == [&"hero/first"], "first member should be active")
	_assert(party.reserve_member_ids == [&"hero/second"], "second member should be reserve")
	_assert(party.remove_member(&"hero/first") == OK, "party should remove active member")
	_assert(party.active_member_ids == [&"hero/second"], "reserve member should promote after active removal")
	var wallet: Resource = WalletScript.new()
	_assert(wallet.add(&"gold", 25) == OK, "wallet should add currency")
	_assert(wallet.spend(&"gold", 10) == OK, "wallet should spend available currency")
	_assert(wallet.spend(&"gold", 99) == ERR_UNAVAILABLE, "wallet should reject overspend")
	_assert(wallet.amount(&"gold") == 15, "wallet should preserve balance after rejected spend")


func _verify_equipment_contracts() -> void:
	var sword: Resource = ItemRefScript.new()
	sword.item_id = &"item/iron_sword"
	sword.equipment_slot = &"weapon"
	sword.tags = _string_name_array([&"weapon", &"blade"])
	sword.stat_modifiers = _resource_array([StatModifierScript.add(&"attack", 3, &"iron_sword")])
	var weapon_slot: Resource = EquipmentSlotScript.new()
	weapon_slot.slot_id = &"weapon"
	weapon_slot.accepts_tags = _string_name_array([&"weapon"])
	var loadout: Resource = EquipmentLoadoutScript.new()
	loadout.define_slot(weapon_slot)
	_assert(sword.is_valid(), "item ref should require a stable item id")
	_assert(loadout.equip(sword) == OK, "equipment loadout should accept compatible item")
	_assert(loadout.equipped_item(&"weapon") == sword, "equipment loadout should expose equipped item")
	_assert(loadout.stat_modifiers().size() == 1, "equipment loadout should expose stat modifiers")


func _character_state(id: StringName) -> Resource:
	var data: Resource = CharacterDataScript.new()
	data.id = id
	data.display_name = String(id)
	data.base_stats = StatBlockScript.new()
	data.base_stats.set_base(&"max_hp", 10)
	data.base_stats.set_base(&"max_mp", 5)
	return CharacterStateScript.from_data(data)


func _int_array(values: Array) -> Array[int]:
	var result: Array[int] = []
	for value in values:
		result.append(int(value))
	return result


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
