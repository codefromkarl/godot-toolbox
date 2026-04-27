extends Node
class_name RPGCoreService

const PACK_ID := "rpg-core"
const REQUIRED_CONTRACTS: Array[StringName] = [&"data-core", &"save-core"]
const PLANNED_CONTRACTS: Array[StringName] = [
	&"StatBlock",
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


func planned_contracts() -> Array[StringName]:
	return PLANNED_CONTRACTS.duplicate()
