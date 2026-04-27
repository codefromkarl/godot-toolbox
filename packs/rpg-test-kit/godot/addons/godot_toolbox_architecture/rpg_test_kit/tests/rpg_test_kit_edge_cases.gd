extends SceneTree

const ReplayRunnerScript := preload("res://addons/godot_toolbox_architecture/rpg_test_kit/replay/battle_replay_runner.gd")
const StateDumpScript := preload("res://addons/godot_toolbox_architecture/rpg_test_kit/dump/rpg_state_dump.gd")
const BattleSessionScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/battle/battle_session.gd")
const PartyStateScript := preload("res://addons/godot_toolbox_architecture/rpg_core/party/party_state.gd")

var _failed := false


func _initialize() -> void:
	var replay_events := _verify_minimal_fixture_replay_determinism()
	var dump_counts := _verify_empty_state_dump_schema()
	if not _failed:
		print("RPG_EDGE_TEST_KIT_OK replay_events=%s dump_inventory=%s dump_events=%s" % [
			replay_events,
			dump_counts["inventory"],
			dump_counts["events"],
		])
	quit(1 if _failed else 0)


func _verify_minimal_fixture_replay_determinism() -> int:
	var fixture := {
		"party": [{
			"id": "hero/edge",
			"stats": {"max_hp": 9, "max_mp": 0, "speed": 1, "attack": 1, "defense": 0},
		}],
		"enemies": [{
			"id": "enemy/wall",
			"stats": {"max_hp": 9, "max_mp": 0, "speed": 1, "attack": 1, "defense": 0},
		}],
		"max_turns": 1,
	}
	var runner: RefCounted = ReplayRunnerScript.new()
	var first: Dictionary = runner.run_fixture(fixture)
	var second: Dictionary = runner.run_fixture(fixture)
	_assert(first == second, "minimal replay fixture should be deterministic")
	_assert(first.has("outcome"), "replay result should expose outcome")
	_assert(first.has("action_sequence"), "replay result should expose action_sequence")
	_assert(first.has("events"), "replay result should expose events")
	_assert((first["events"] as Array).size() >= 2, "replay should expose battle lifecycle events")
	for i in range((first["events"] as Array).size()):
		var event: Dictionary = first["events"][i]
		_assert(event.has("type"), "replay event should expose type")
		_assert(event.has("payload"), "replay event should expose payload")
		_assert(event.get("index", -1) == i, "replay event index should be stable")
	return (first["events"] as Array).size()


func _verify_empty_state_dump_schema() -> Dictionary:
	var session: Resource = BattleSessionScript.new()
	session.phase = &"edge_empty"
	session.event_stream = null
	var dump: Dictionary = StateDumpScript.dump_all(session, PartyStateScript.new(), [null, {"id": "item/edge", "quantity": 1}], {"schema_version": 1})
	_assert(dump.has("battle"), "state dump should include battle")
	_assert(dump.has("party"), "state dump should include party")
	_assert(dump.has("inventory"), "state dump should include inventory")
	_assert(dump.has("save_payload"), "state dump should include save_payload")
	_assert(dump["battle"]["phase"] == "edge_empty", "state dump should preserve empty-state battle phase")
	_assert((dump["battle"]["events"] as Array).is_empty(), "state dump should tolerate missing event stream")
	_assert((dump["party"]["members"] as Array).is_empty(), "state dump should expose empty party members")
	_assert((dump["inventory"] as Array).size() == 1, "state dump should skip null inventory entries")
	_assert(dump["inventory"][0]["id"] == "item/edge", "state dump should preserve dictionary inventory rows")
	_assert(JSON.parse_string(JSON.stringify(dump)) is Dictionary, "state dump should remain JSON serializable")
	return {
		"inventory": (dump["inventory"] as Array).size(),
		"events": (dump["battle"]["events"] as Array).size(),
	}


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
