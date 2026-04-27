extends Resource
class_name TargetRule

enum Kind {
	SELF,
	SINGLE_ENEMY,
	ALL_ENEMIES,
	ALL_ALLIES,
	RANDOM_ENEMY,
}

@export var kind: Kind = Kind.SINGLE_ENEMY


static func self_target() -> Resource:
	return _with_kind(Kind.SELF)


static func single_enemy() -> Resource:
	return _with_kind(Kind.SINGLE_ENEMY)


static func all_enemies() -> Resource:
	return _with_kind(Kind.ALL_ENEMIES)


static func all_allies() -> Resource:
	return _with_kind(Kind.ALL_ALLIES)


static func random_enemy() -> Resource:
	return _with_kind(Kind.RANDOM_ENEMY)


static func _with_kind(next_kind: Kind) -> Resource:
	var rule := TargetRule.new()
	rule.kind = next_kind
	return rule


func legal_targets(session: Resource, actor: Resource, seed: int = 0) -> Array:
	match kind:
		Kind.SELF:
			return [actor]
		Kind.SINGLE_ENEMY, Kind.ALL_ENEMIES:
			return session.alive_opponents(actor.team_id)
		Kind.ALL_ALLIES:
			return session.alive_team(actor.team_id)
		Kind.RANDOM_ENEMY:
			var enemies: Array = session.alive_opponents(actor.team_id)
			if enemies.is_empty():
				return []
			return [enemies[abs(seed) % enemies.size()]]
	return []
