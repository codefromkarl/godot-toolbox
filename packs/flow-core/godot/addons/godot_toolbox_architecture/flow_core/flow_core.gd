extends Node
class_name FlowCoreService

signal mode_pushed(mode: GameMode)
signal mode_popped(mode: GameMode)
signal flow_completed(result: FlowResult)

var _mode_stack: Array[GameMode] = []
var _last_result: FlowResult


func push_mode(mode: GameMode) -> void:
	if mode == null:
		push_error("FlowCore.push_mode requires a GameMode.")
		return
	_mode_stack.append(mode)
	mode_pushed.emit(mode)


func replace_mode(mode: GameMode) -> void:
	if not _mode_stack.is_empty():
		var previous := _mode_stack.pop_back()
		mode_popped.emit(previous)
	push_mode(mode)


func pop_mode() -> GameMode:
	if _mode_stack.is_empty():
		return null
	var mode := _mode_stack.pop_back()
	mode_popped.emit(mode)
	return mode


func current_mode() -> GameMode:
	if _mode_stack.is_empty():
		return null
	return _mode_stack.back()


func stack_size() -> int:
	return _mode_stack.size()


func apply_request(request: FlowRequest) -> FlowResult:
	if request == null:
		return FlowResult.fail(&"invalid_request", {"reason": "request is null"})

	match request.kind:
		FlowRequest.Kind.PUSH:
			return _apply_push_request(request)
		FlowRequest.Kind.REPLACE:
			return _apply_replace_request(request)
		FlowRequest.Kind.POP:
			return _apply_pop_request(request)
		FlowRequest.Kind.COMPLETE:
			return _apply_complete_request(request)
		_:
			return FlowResult.fail(&"invalid_request", {"reason": "unknown request kind"})


func complete_flow(result: FlowResult) -> void:
	_last_result = result
	flow_completed.emit(result)


func last_result() -> FlowResult:
	return _last_result


func clear() -> void:
	_mode_stack.clear()
	_last_result = null


func _apply_push_request(request: FlowRequest) -> FlowResult:
	var validation := _validate_mode(request.mode)
	if validation != null:
		return validation

	push_mode(request.mode)
	var payload := _mode_payload(request.mode)
	payload.merge(request.payload, true)
	return FlowResult.ok(&"mode_pushed", payload)


func _apply_replace_request(request: FlowRequest) -> FlowResult:
	var validation := _validate_mode(request.mode)
	if validation != null:
		return validation

	var previous_mode := current_mode()
	replace_mode(request.mode)
	var payload := _mode_payload(request.mode)
	if previous_mode != null:
		payload["previous_mode"] = String(previous_mode.id)
	payload.merge(request.payload, true)
	return FlowResult.ok(&"mode_replaced", payload)


func _apply_pop_request(request: FlowRequest) -> FlowResult:
	var popped_mode := pop_mode()
	if popped_mode == null:
		return FlowResult.fail(&"empty_stack", request.payload)

	var payload := _mode_payload(popped_mode)
	payload.merge(request.payload, true)
	return FlowResult.ok(&"mode_popped", payload)


func _apply_complete_request(request: FlowRequest) -> FlowResult:
	var result := request.result
	if result == null:
		result = FlowResult.ok(&"flow_completed", request.payload)
	complete_flow(result)
	return result


func _validate_mode(mode: GameMode) -> FlowResult:
	if mode == null:
		return FlowResult.fail(&"invalid_mode", {"reason": "mode is null"})
	if not mode.is_valid():
		return FlowResult.fail(&"invalid_mode", {"reason": "mode id is empty"})
	return null


func _mode_payload(mode: GameMode) -> Dictionary:
	return {
		"mode": String(mode.id),
		"scene_path": mode.scene_path,
	}
