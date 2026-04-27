extends SceneTree

const ReplayRunnerScript := preload("res://addons/godot_toolbox_architecture/rpg_test_kit/replay/battle_replay_runner.gd")
const CombatEventStreamScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/events/combat_event_stream.gd")

var _failed := false


func _initialize() -> void:
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://addons/godot_toolbox_architecture/rpg_test_kit/replay/fixed_battle_replay.json"))
	var runner: RefCounted = ReplayRunnerScript.new()
	var first: Dictionary = runner.run_fixture(fixture)
	var second: Dictionary = runner.run_fixture(fixture)
	_assert(first["action_sequence"] == second["action_sequence"], "replay should produce identical action sequence")
	_assert(first["events"] == second["events"], "replay should produce identical event stream")
	_assert(first["action_sequence"] == fixture["expected_action_sequence"], "replay should match expected action sequence")
	_assert(first["outcome"] == "victory", "replay should end in victory")
	var event_stream: Resource = CombatEventStreamScript.new()
	event_stream.emit_event(&"save", {"slot": "test"})
	_assert(event_stream.events[0]["type"] == "save", "combat event stream should serialize save event")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
