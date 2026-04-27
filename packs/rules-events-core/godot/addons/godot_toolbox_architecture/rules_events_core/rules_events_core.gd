extends Node
class_name RulesEventsCoreService

signal event_processed(result: Dictionary)

const EventQueueScript := preload("res://addons/godot_toolbox_architecture/rules_events_core/event_queue.gd")

var _queue: EventQueue = EventQueueScript.new()


func queue() -> EventQueue:
	return _queue


func reset() -> void:
	_queue = EventQueueScript.new()


func process_next(context: ExecutionContext = null) -> Dictionary:
	var result := _queue.process_next(context)
	event_processed.emit(result)
	return result
