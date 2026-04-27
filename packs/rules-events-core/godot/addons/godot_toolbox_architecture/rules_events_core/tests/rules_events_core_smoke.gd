extends SceneTree

const GameEventScript := preload("res://addons/godot_toolbox_architecture/rules_events_core/game_event.gd")
const ExecutionContextScript := preload("res://addons/godot_toolbox_architecture/rules_events_core/execution_context.gd")
const EventConditionScript := preload("res://addons/godot_toolbox_architecture/rules_events_core/event_condition.gd")
const EffectCommandScript := preload("res://addons/godot_toolbox_architecture/rules_events_core/effect_command.gd")
const EventQueueScript := preload("res://addons/godot_toolbox_architecture/rules_events_core/event_queue.gd")

var _failed := false


func _initialize() -> void:
	var queue: EventQueue = EventQueueScript.new()
	var context: ExecutionContext = ExecutionContextScript.new()
	context.write(&"global", &"allowed", true)

	var pass_condition: EventCondition = EventConditionScript.new()
	pass_condition.condition_id = &"allowed"
	pass_condition.evaluator = func(ctx: ExecutionContext) -> bool:
		return bool(ctx.read(&"global", &"allowed", false))

	var effect: EffectCommand = EffectCommandScript.new()
	effect.effect_id = &"mark_seen"
	effect.executor = func(ctx: ExecutionContext) -> Dictionary:
		ctx.write(&"global", &"seen", ctx.event.id)
		return {"ok": true, "value": String(ctx.event.id)}

	queue.add_condition(pass_condition)
	queue.add_effect(effect)

	var event: GameEvent = GameEventScript.new()
	event.id = &"quest/started"
	event.payload = {"quest": "intro"}
	_assert(queue.queue_event(event) == OK, "valid event should queue")

	var result := queue.process_next(context)
	_assert(result["ok"], "passing condition should allow event")
	_assert(result["effects"].size() == 1, "effect should execute once")
	_assert(String(context.read(&"global", &"seen")) == "quest/started", "effect should write context memory")

	context.write(&"global", &"allowed", false)
	_assert(queue.queue_event(event) == OK, "second event should queue")
	var rejected := queue.process_next(context)
	_assert(not rejected["ok"], "failing condition should reject event")
	_assert(String(rejected["blocked_by"]) == "allowed", "rejection should report blocking condition")

	_finish()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true


func _finish() -> void:
	quit(1 if _failed else 0)
