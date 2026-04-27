extends VBoxContainer
class_name RPGBattleHUD


func _ready() -> void:
	_ensure_label("TurnIndicator")
	_ensure_label("PartyStatus")
	_ensure_label("EnemyStatus")
	_ensure_label("BattleLog")


func update_from_session(session: Resource) -> void:
	_ready()
	$TurnIndicator.text = "Phase: %s" % String(session.phase)
	$PartyStatus.text = "Party: %s" % _combatant_summary(session.party)
	$EnemyStatus.text = "Enemies: %s" % _combatant_summary(session.enemies)
	$BattleLog.text = "Log: %s events" % session.battle_log.size()


func _combatant_summary(combatants: Array) -> String:
	var parts: Array[String] = []
	for combatant in combatants:
		if combatant != null:
			parts.append("%s HP %s/%s MP %s/%s" % [
				String(combatant.combatant_id),
				combatant.current_hp,
				combatant.max_hp(),
				combatant.current_mp,
				combatant.max_mp(),
			])
	return ", ".join(parts)


func _ensure_label(node_name: String) -> void:
	if has_node(node_name):
		return
	var label := Label.new()
	label.name = node_name
	add_child(label)
