extends SceneTree

const BattleRootScene := preload("res://scenes/rpg_battle/battle_root.tscn")
const BattleHUDScript := preload("res://scenes/rpg_battle/battle_hud.gd")
const SkillMenuScript := preload("res://scenes/rpg_battle/skill_menu.gd")
const ItemMenuScript := preload("res://scenes/rpg_battle/item_menu.gd")
const StatBlockScript := preload("res://addons/godot_toolbox_architecture/rpg_core/stats/stat_block.gd")
const CharacterDataScript := preload("res://addons/godot_toolbox_architecture/rpg_core/characters/character_data.gd")
const CharacterStateScript := preload("res://addons/godot_toolbox_architecture/rpg_core/characters/character_state.gd")
const CombatantStateScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/combat/combatant_state.gd")
const BattleSessionScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/battle/battle_session.gd")
const ItemActionScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/actions/item_action.gd")

var _failed := false


func _initialize() -> void:
	var root: Control = BattleRootScene.instantiate()
	root.name = "BattleRoot"
	get_root().add_child(root)
	_assert(root.has_node("PartyPanel"), "BattleRoot should expose PartyPanel")
	_assert(root.has_node("EnemyPanel"), "BattleRoot should expose EnemyPanel")
	_assert(root.has_node("CommandArea"), "BattleRoot should expose CommandArea")
	_assert(root.has_node("BattleHUD"), "BattleRoot should expose BattleHUD")
	_verify_hud(root.get_node("BattleHUD"))
	_verify_skill_menu(root.get_node("SkillMenu"))
	_verify_item_menu(root.get_node("ItemMenu"))
	root.queue_free()
	quit(1 if _failed else 0)


func _verify_hud(hud: Node) -> void:
	var session := _session()
	hud.update_from_session(session)
	_assert(hud.get_node("TurnIndicator").text.contains("ready"), "HUD should show battle phase")
	_assert(hud.get_node("PartyStatus").text.contains("hero"), "HUD should show party state")
	_assert(hud.get_node("EnemyStatus").text.contains("slime"), "HUD should show enemy state")


func _verify_skill_menu(menu: Node) -> void:
	var actor := _combatant(&"hero", &"party", 20, 2, 5, 5, 1)
	menu.configure([
		{"id": "skill/slash", "name": "Slash", "mp_cost": 1},
		{"id": "skill/flare", "name": "Flare", "mp_cost": 5},
	], actor)
	_assert(menu.get_node("Skills/skill_slash").disabled == false, "Skill menu should enable affordable skill")
	_assert(menu.get_node("Skills/skill_flare").disabled == true, "Skill menu should disable unaffordable skill")
	_assert(menu.select_skill(0)["id"] == "skill/slash", "Skill menu should return selected skill")


func _verify_item_menu(menu: Node) -> void:
	var target := _combatant(&"hero", &"party", 20, 0, 5, 5, 1)
	target.apply_damage(8)
	menu.configure([
		{"id": "item/potion", "name": "Potion", "quantity": 2, "heal": 5},
	], target)
	var action: Resource = menu.use_item(0)
	_assert(action is ItemActionScript, "Item menu should produce ItemAction")
	_assert(target.current_hp == 17, "Item menu should heal target")
	_assert(menu.items[0]["quantity"] == 1, "Item menu should consume quantity")


func _session() -> Resource:
	var session: Resource = BattleSessionScript.new()
	session.party = [_combatant(&"hero", &"party", 20, 3, 5, 5, 1)]
	session.enemies = [_combatant(&"slime", &"enemy", 10, 0, 3, 3, 0)]
	return session


func _combatant(id: StringName, team: StringName, hp: int, mp: int, speed: int, attack: int, defense: int) -> Resource:
	var stats: Resource = StatBlockScript.new()
	stats.set_base(&"max_hp", hp)
	stats.set_base(&"max_mp", mp)
	stats.set_base(&"speed", speed)
	stats.set_base(&"attack", attack)
	stats.set_base(&"defense", defense)
	var data: Resource = CharacterDataScript.new()
	data.id = id
	data.display_name = String(id)
	data.base_stats = stats
	var state: Resource = CharacterStateScript.from_data(data)
	return CombatantStateScript.from_character_state(state, team)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
