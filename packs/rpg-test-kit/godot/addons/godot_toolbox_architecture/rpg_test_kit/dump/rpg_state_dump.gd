extends RefCounted
class_name RPGStateDump


static func dump_all(session: Resource, party: Resource, inventory: Array, save_payload: Dictionary) -> Dictionary:
	return {
		"battle": dump_battle(session),
		"party": dump_party(party),
		"inventory": dump_inventory(inventory),
		"save_payload": save_payload.duplicate(true),
	}


static func dump_battle(session: Resource) -> Dictionary:
	return {
		"phase": String(session.phase),
		"party": _dump_combatants(session.party),
		"enemies": _dump_combatants(session.enemies),
		"action_sequence": _string_names_to_strings(session.action_sequence),
		"events": session.event_stream.to_array() if session.event_stream != null else [],
	}


static func dump_party(party: Resource) -> Dictionary:
	var members: Array[Dictionary] = []
	for member in party.members:
		if member != null:
			members.append({
				"id": String(member.character_id),
				"level": member.level,
				"experience": member.experience,
				"current_hp": member.current_hp,
				"current_mp": member.current_mp,
			})
	return {
		"members": members,
		"active": _string_names_to_strings(party.active_member_ids),
		"reserve": _string_names_to_strings(party.reserve_member_ids),
		"wallet": party.wallet.to_dictionary(),
	}


static func dump_inventory(inventory: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in inventory:
		if item == null:
			continue
		if item is Dictionary:
			result.append((item as Dictionary).duplicate(true))
		elif item.has_method("to_dictionary"):
			result.append(item.to_dictionary())
	return result


static func _dump_combatants(combatants: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for combatant in combatants:
		if combatant != null:
			result.append({
				"id": String(combatant.combatant_id),
				"team": String(combatant.team_id),
				"current_hp": combatant.current_hp,
				"current_mp": combatant.current_mp,
				"defeated": combatant.is_defeated(),
			})
	return result


static func _string_names_to_strings(values: Array) -> Array[String]:
	var result: Array[String] = []
	for value in values:
		result.append(String(value))
	return result
