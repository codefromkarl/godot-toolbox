extends RefCounted
class_name EventQueue

var _events: Array[GameEvent] = []
var _conditions: Array[EventCondition] = []
var _effects: Array[EffectCommand] = []


func add_condition(condition: EventCondition) -> void:
	if condition != null:
		_conditions.append(condition)


func add_effect(effect: EffectCommand) -> void:
	if effect != null:
		_effects.append(effect)


func queue_event(event: GameEvent) -> Error:
	if event == null or not event.is_valid():
		return ERR_INVALID_PARAMETER
	_events.append(event)
	return OK


func process_next(context: ExecutionContext = null) -> Dictionary:
	if _events.is_empty():
		return {"ok": false, "reason": "empty_queue"}
	if context == null:
		context = ExecutionContext.new()
	var event := _events.pop_front()
	context.event = event

	for condition in _conditions:
		if not condition.evaluate(context):
			return {
				"ok": false,
				"event": String(event.id),
				"blocked_by": String(condition.condition_id),
				"reason": condition.last_reason,
			}

	var effect_results: Array[Dictionary] = []
	for effect in _effects:
		var result := effect.execute(context)
		effect_results.append(result)
		context.results.append(result)
	return {
		"ok": true,
		"event": String(event.id),
		"effects": effect_results,
	}


func size() -> int:
	return _events.size()
