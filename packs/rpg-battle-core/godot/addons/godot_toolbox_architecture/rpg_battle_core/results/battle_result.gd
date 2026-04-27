extends Resource
class_name BattleResult

@export var outcome: StringName = &"undecided"
@export var winner_team: StringName
@export var reward: Resource


func is_finished() -> bool:
	return outcome != &"undecided"


func is_victory() -> bool:
	return outcome == &"victory"
