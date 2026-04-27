extends Node
class_name RPGBattleCoreService

const PACK_ID := "rpg-battle-core"
const REQUIRED_CONTRACTS: Array[StringName] = [&"rpg-core", &"flow-core", &"rules-events-core"]
const PLANNED_CONTRACTS: Array[StringName] = [
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
]


func pack_id() -> String:
	return PACK_ID


func required_contracts() -> Array[StringName]:
	return REQUIRED_CONTRACTS.duplicate()


func planned_contracts() -> Array[StringName]:
	return PLANNED_CONTRACTS.duplicate()
