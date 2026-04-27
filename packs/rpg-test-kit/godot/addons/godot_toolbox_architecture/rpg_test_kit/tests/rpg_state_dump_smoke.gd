extends SceneTree

const StateDumpScript := preload("res://addons/godot_toolbox_architecture/rpg_test_kit/dump/rpg_state_dump.gd")
const SaveAdapterScript := preload("res://addons/godot_toolbox_architecture/rpg_save_adapter/rpg_save_adapter.gd")
const StatBlockScript := preload("res://addons/godot_toolbox_architecture/rpg_core/stats/stat_block.gd")
const CharacterDataScript := preload("res://addons/godot_toolbox_architecture/rpg_core/characters/character_data.gd")
const CharacterStateScript := preload("res://addons/godot_toolbox_architecture/rpg_core/characters/character_state.gd")
const PartyStateScript := preload("res://addons/godot_toolbox_architecture/rpg_core/party/party_state.gd")
const CombatantStateScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/combat/combatant_state.gd")
const BattleSessionScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/battle/battle_session.gd")

var _failed := false


func _initialize() -> void:
	var party: Resource = PartyStateScript.new()
	party.add_member(_character_state(&"hero"))
	party.wallet.add(&"gold", 5)
	var session: Resource = BattleSessionScript.new()
	session.party = [CombatantStateScript.from_character_state(party.member(&"hero"), &"party")]
	session.enemies = [CombatantStateScript.from_character_state(_character_state(&"slime"), &"enemy")]
	var adapter: Node = SaveAdapterScript.new()
	var save_payload: Dictionary = adapter.to_payload(party, [], {}, {})
	var dump: Dictionary = StateDumpScript.dump_all(session, party, [], save_payload)
	_assert(dump["battle"]["party"][0]["id"] == "hero", "state dump should expose battle party state")
	_assert(dump["party"]["wallet"]["gold"] == 5, "state dump should expose party wallet")
	_assert(dump["save_payload"]["schema_version"] == 1, "state dump should expose save payload")
	var text := JSON.stringify(dump)
	_assert(JSON.parse_string(text) is Dictionary, "state dump should be JSON serializable")
	adapter.free()
	quit(1 if _failed else 0)


func _character_state(id: StringName) -> Resource:
	var stats: Resource = StatBlockScript.new()
	stats.set_base(&"max_hp", 10)
	stats.set_base(&"max_mp", 4)
	stats.set_base(&"speed", 4)
	stats.set_base(&"attack", 4)
	stats.set_base(&"defense", 1)
	var data: Resource = CharacterDataScript.new()
	data.id = id
	data.display_name = String(id)
	data.base_stats = stats
	return CharacterStateScript.from_data(data)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
