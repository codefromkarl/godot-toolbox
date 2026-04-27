extends RefCounted
class_name FlowSmokeFixture


func run_minimal_flow(flow: FlowCoreService) -> Dictionary:
	if flow == null:
		return {
			"success": false,
			"error": "flow service is null",
		}

	var mode := GameMode.new()
	mode.id = &"smoke"
	mode.scene_path = "res://scenes/main.tscn"
	flow.clear()
	var push_result := flow.apply_request(FlowRequest.push(mode))
	var complete_result := flow.apply_request(FlowRequest.complete(
		FlowResult.ok(&"smoke_complete", {"mode": "smoke"})
	))
	return {
		"success": push_result.success and complete_result.success,
		"current_mode": String(flow.current_mode().id),
		"stack_size": flow.stack_size(),
		"result_code": String(complete_result.code),
		"payload": complete_result.payload,
	}
