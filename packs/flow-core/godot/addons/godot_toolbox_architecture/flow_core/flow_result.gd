extends Resource
class_name FlowResult

@export var code: StringName
@export var payload: Dictionary = {}
@export var success: bool = true


static func ok(result_code: StringName = &"ok", result_payload: Dictionary = {}) -> FlowResult:
	var result := FlowResult.new()
	result.code = result_code
	result.payload = result_payload
	result.success = true
	return result


static func fail(result_code: StringName, result_payload: Dictionary = {}) -> FlowResult:
	var result := FlowResult.new()
	result.code = result_code
	result.payload = result_payload
	result.success = false
	return result

