extends SceneTree

## Cross-pack integration smoke for dialogue adapters.
## Tests three Promotion Gate boundaries:
## 1. Dialogue events -> rules-events-core (GameEvent + EventQueue)
## 2. Dialogue content IDs -> data-core (GameId validation)
## 3. Dialogue state -> save-core / rpg-save-adapter (serialize/deserialize roundtrip)

const DialogueEventAdapterScript := preload("res://addons/godot_toolbox_dialogue/adapters/dialogue_event_adapter.gd")
const DialogueContentAdapterScript := preload("res://addons/godot_toolbox_dialogue/adapters/dialogue_content_adapter.gd")
const DialogueSaveAdapterScript := preload("res://addons/godot_toolbox_dialogue/adapters/dialogue_save_adapter.gd")
const EventQueueScript := preload("res://addons/godot_toolbox_architecture/rules_events_core/event_queue.gd")
const GameEventScript := preload("res://addons/godot_toolbox_architecture/rules_events_core/game_event.gd")

var _failed := false


func _initialize() -> void:
	_test_event_adapter()
	_test_event_queue_integration()
	_test_content_adapter()
	_test_save_adapter()
	quit(1 if _failed else 0)


func _test_event_adapter() -> void:
	## Boundary 1a: Dialogue events produce valid GameEvent resources
	var event: Resource = DialogueEventAdapterScript.make_dialogue_started_event(
		"res://dialogue/elder_greeting.tres", "Elder Greeting"
	)
	_assert(event != null, "dialogue_started event should not be null")
	_assert(event.id == &"dialogue/started", "event id should be dialogue/started")
	_assert(event.payload["resource_path"] == "res://dialogue/elder_greeting.tres",
		"event payload should contain resource_path")
	_assert(event.is_valid(), "dialogue_started event should be valid")

	var ended: Resource = DialogueEventAdapterScript.make_dialogue_ended_event(
		"res://dialogue/elder_greeting.tres", "accepted"
	)
	_assert(ended != null, "dialogue_ended event should not be null")
	_assert(ended.id == &"dialogue/ended", "ended event id should be dialogue/ended")
	_assert(ended.payload["outcome"] == "accepted", "ended event should preserve outcome")

	var line: Resource = DialogueEventAdapterScript.make_line_shown_event(
		"res://dialogue/elder_greeting.tres", "Elder", "Welcome, traveler."
	)
	_assert(line != null, "line_shown event should not be null")
	_assert(line.payload["speaker"] == "Elder", "line event should preserve speaker")
	_assert(line.payload["text"] == "Welcome, traveler.", "line event should preserve text")

	var choice: Resource = DialogueEventAdapterScript.make_choice_made_event(
		"res://dialogue/quest_accept.tres", 0, "I accept the quest."
	)
	_assert(choice != null, "choice_made event should not be null")
	_assert(choice.payload["choice_index"] == 0, "choice event should preserve index")

	## Generic factory test
	var generic: Resource = DialogueEventAdapterScript.event_from_dialogue_signal(
		&"dialogue_started", {"resource_path": "res://test.tres", "title": "Test"}
	)
	_assert(generic != null, "generic factory should produce event for known signal")
	_assert(generic.id == &"dialogue/started", "generic factory should map correct id")

	var unknown: Resource = DialogueEventAdapterScript.event_from_dialogue_signal(
		&"unknown_signal", {}
	)
	_assert(unknown == null, "generic factory should return null for unknown signal")


func _test_event_queue_integration() -> void:
	## Boundary 1b: Dialogue events can be queued and processed via rules-events-core
	var queue: RefCounted = EventQueueScript.new()
	var event: Resource = DialogueEventAdapterScript.make_line_shown_event(
		"res://dialogue/test.tres", "NPC", "Hello."
	)
	var result: Error = queue.queue_event(event)
	_assert(result == OK, "queue_event should accept dialogue event")
	_assert(queue.size() == 1, "queue should have 1 event after enqueue")

	var process_result: Dictionary = queue.process_next()
	_assert(bool(process_result["ok"]), "process_next should succeed")
	_assert(str(process_result["event"]) == "dialogue/line_shown",
		"processed event should be dialogue/line_shown")

	## Empty queue should report empty
	var empty_result: Dictionary = queue.process_next()
	_assert(not bool(empty_result["ok"]), "empty queue should not report ok")


func _test_content_adapter() -> void:
	## Boundary 2: Dialogue content IDs are valid data-core GameIds
	var speaker_id: StringName = DialogueContentAdapterScript.speaker_to_game_id("Elder")
	_assert(speaker_id == &"speaker/elder", "speaker Elder -> speaker/elder")
	_assert(DialogueContentAdapterScript.validate_speaker_id("Elder"),
		"Elder should be a valid speaker")

	var empty_speaker: StringName = DialogueContentAdapterScript.speaker_to_game_id("")
	_assert(String(empty_speaker).is_empty(), "empty speaker should produce empty id")

	var dialogue_id: StringName = DialogueContentAdapterScript.resource_path_to_dialogue_id(
		"res://dialogue/elder_quest.tres"
	)
	_assert(dialogue_id == &"dialogue/elder_quest", "resource path -> dialogue/elder_quest")
	_assert(DialogueContentAdapterScript.validate_dialogue_id("res://dialogue/elder_quest.tres"),
		"valid resource path should validate")

	var bad_path: StringName = DialogueContentAdapterScript.resource_path_to_dialogue_id("")
	_assert(String(bad_path).is_empty(), "empty path should produce empty id")


func _test_save_adapter() -> void:
	## Boundary 3: Dialogue state roundtrips through serialize/deserialize
	var original := {
		"active_dialogue": "res://dialogue/elder_greeting.tres",
		"variables": {"met_elder": true, "quest_count": 3},
		"visited": ["res://dialogue/intro.tres", "res://dialogue/elder_greeting.tres"],
	}
	var serialized: Dictionary = DialogueSaveAdapterScript.serialize(original)
	_assert(not serialized.is_empty(), "serialized state should not be empty")
	_assert(serialized["active_dialogue"] == "res://dialogue/elder_greeting.tres",
		"serialized state should preserve active_dialogue")
	_assert(serialized["variables"]["met_elder"] == true,
		"serialized state should preserve variables")
	_assert(serialized["visited"].size() == 2,
		"serialized state should preserve visited count")

	var deserialized: Dictionary = DialogueSaveAdapterScript.deserialize(serialized)
	_assert(deserialized["active_dialogue"] == "res://dialogue/elder_greeting.tres",
		"roundtrip should preserve active_dialogue")
	_assert(deserialized["variables"]["quest_count"] == 3,
		"roundtrip should preserve variable values")
	_assert(deserialized["visited"][0] == "res://dialogue/intro.tres",
		"roundtrip should preserve visited order")

	## Empty state handling
	var empty_serialized: Dictionary = DialogueSaveAdapterScript.serialize({})
	_assert(empty_serialized.is_empty(), "empty input should produce empty output")

	var empty_deserialized: Dictionary = DialogueSaveAdapterScript.deserialize({})
	_assert(empty_deserialized["active_dialogue"] == "",
		"empty deserialize should produce empty active_dialogue")
	_assert(empty_deserialized["variables"] is Dictionary,
		"empty deserialize should produce empty variables dict")
	_assert(empty_deserialized["visited"] is Array,
		"empty deserialize should produce empty visited array")

	## make_empty_state
	var empty_state: Dictionary = DialogueSaveAdapterScript.make_empty_state()
	_assert(empty_state["active_dialogue"] == "", "make_empty_state active_dialogue")
	_assert(empty_state["variables"] is Dictionary, "make_empty_state variables")
	_assert(empty_state["visited"] is Array, "make_empty_state visited")


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
