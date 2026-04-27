extends Node
class_name RPGBattleCoreService

const PACK_ID := "rpg-battle-core"
const REQUIRED_CONTRACTS: Array[StringName] = [&"rpg-core", &"flow-core", &"rules-events-core"]
const IMPLEMENTED_CONTRACTS: Array[StringName] = [
	&"CombatantState",
	&"BattleSession",
	&"TurnQueue",
	&"BattleAction",
	&"SkillAction",
	&"ItemAction",
	&"TargetRule",
	&"DamageFormula",
	&"BattleResult",
	&"RewardGrant",
	&"DeterministicEnemyAI",
	&"RPGBeehaveAIAdapter",
]


func pack_id() -> String:
	return PACK_ID


func required_contracts() -> Array[StringName]:
	return REQUIRED_CONTRACTS.duplicate()


func implemented_contracts() -> Array[StringName]:
	return IMPLEMENTED_CONTRACTS.duplicate()
