extends RefCounted
class_name EventCondition

var condition_id: StringName = &"condition"
var evaluator: Callable
var last_reason: String = ""


func evaluate(context: ExecutionContext) -> bool:
	if not evaluator.is_valid():
		last_reason = "no evaluator"
		return true
	var result: Variant = evaluator.call(context)
	if typeof(result) == TYPE_DICTIONARY:
		last_reason = str((result as Dictionary).get("reason", ""))
		return bool((result as Dictionary).get("ok", false))
	last_reason = ""
	return bool(result)
