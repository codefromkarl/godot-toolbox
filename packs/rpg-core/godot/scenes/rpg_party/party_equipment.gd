extends VBoxContainer
class_name RPGPartyEquipmentUI

var stat_block: Resource
var loadout: Resource
var candidate_item: Resource


func _ready() -> void:
	_ensure_nodes()
	$EquipButton.pressed.connect(equip_candidate)
	_update_stat_output()


func configure(next_stat_block: Resource, next_loadout: Resource, next_candidate_item: Resource) -> void:
	_ensure_nodes()
	stat_block = next_stat_block
	loadout = next_loadout
	candidate_item = next_candidate_item
	_update_stat_output()


func equip_candidate() -> void:
	if loadout != null and candidate_item != null:
		loadout.equip(candidate_item)
	_update_stat_output()


func _update_stat_output() -> void:
	_ensure_nodes()
	var attack := 0
	if stat_block != null:
		var modifiers: Array[Resource] = []
		if loadout != null:
			modifiers = loadout.stat_modifiers()
		attack = stat_block.value(&"attack", modifiers)
	$StatOutput.text = "Attack: %s" % attack


func _ensure_nodes() -> void:
	if not has_node("StatOutput"):
		var stat_output := Label.new()
		stat_output.name = "StatOutput"
		add_child(stat_output)
	if not has_node("EquipButton"):
		var button := Button.new()
		button.name = "EquipButton"
		button.text = "Equip Candidate"
		add_child(button)
