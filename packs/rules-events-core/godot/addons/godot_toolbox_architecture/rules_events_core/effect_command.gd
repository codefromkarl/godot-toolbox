extends RefCounted
class_name EffectCommand

var effect_id: StringName = &"effect"
var executor: Callable


func execute(context: ExecutionContext) -> Dictionary:
	if not executor.is_valid():
		return {
			"effect": String(effect_id),
			"ok": false,
			"reason": "no executor",
		}
	var result: Variant = executor.call(context)
	if typeof(result) == TYPE_DICTIONARY:
		var dict := (result as Dictionary).duplicate(true)
		if not dict.has("effect"):
			dict["effect"] = String(effect_id)
		if not dict.has("ok"):
			dict["ok"] = true
		return dict
	return {
		"effect": String(effect_id),
		"ok": bool(result),
	}
