extends RefCounted
class_name DialogueEventAdapter

## Bridges Dialogue Manager events to rules-events-core GameEvent payloads.
## Dialogue Manager emits signals like dialogue_started, dialogue_ended, line_shown,
## and choice_made. This adapter converts those into typed GameEvent resources
## that rules-events-core can queue and process.

const GameEventScript := preload("res://addons/godot_toolbox_architecture/rules_events_core/game_event.gd")


static func make_dialogue_started_event(resource_path: String, title: String = "") -> Resource:
	var event: Resource = GameEventScript.new()
	event.id = &"dialogue/started"
	event.payload = {
		"resource_path": resource_path,
		"title": title,
	}
	return event


static func make_dialogue_ended_event(resource_path: String, outcome: String = "") -> Resource:
	var event: Resource = GameEventScript.new()
	event.id = &"dialogue/ended"
	event.payload = {
		"resource_path": resource_path,
		"outcome": outcome,
	}
	return event


static func make_line_shown_event(resource_path: String, speaker: String, text: String) -> Resource:
	var event: Resource = GameEventScript.new()
	event.id = &"dialogue/line_shown"
	event.payload = {
		"resource_path": resource_path,
		"speaker": speaker,
		"text": text,
	}
	return event


static func make_choice_made_event(resource_path: String, choice_index: int, choice_text: String) -> Resource:
	var event: Resource = GameEventScript.new()
	event.id = &"dialogue/choice_made"
	event.payload = {
		"resource_path": resource_path,
		"choice_index": choice_index,
		"choice_text": choice_text,
	}
	return event


static func event_from_dialogue_signal(signal_name: StringName, args: Dictionary = {}) -> Resource:
	## Generic factory: maps a dialogue signal name to the appropriate GameEvent.
	match signal_name:
		&"dialogue_started":
			return make_dialogue_started_event(
				str(args.get("resource_path", "")),
				str(args.get("title", ""))
			)
		&"dialogue_ended":
			return make_dialogue_ended_event(
				str(args.get("resource_path", "")),
				str(args.get("outcome", ""))
			)
		&"line_shown":
			return make_line_shown_event(
				str(args.get("resource_path", "")),
				str(args.get("speaker", "")),
				str(args.get("text", ""))
			)
		&"choice_made":
			return make_choice_made_event(
				str(args.get("resource_path", "")),
				int(args.get("choice_index", -1)),
				str(args.get("choice_text", ""))
			)
		_:
			return null
