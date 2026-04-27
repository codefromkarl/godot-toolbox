extends Node
class_name RPGCoreService

const PACK_ID := "rpg-core"
const REQUIRED_CONTRACTS: Array[StringName] = [&"data-core", &"save-core"]
const IMPLEMENTED_CONTRACTS: Array[StringName] = [
	&"StatBlock",
	&"StatModifier",
	&"LevelCurve",
	&"CharacterData",
	&"CharacterState",
	&"PartyState",
	&"Wallet",
	&"ItemRef",
	&"EquipmentSlot",
	&"EquipmentLoadout",
]


func pack_id() -> String:
	return PACK_ID


func required_contracts() -> Array[StringName]:
	return REQUIRED_CONTRACTS.duplicate()


func implemented_contracts() -> Array[StringName]:
	return IMPLEMENTED_CONTRACTS.duplicate()
