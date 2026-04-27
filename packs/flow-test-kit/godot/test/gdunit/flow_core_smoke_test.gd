extends GdUnitTestSuite


func before_test() -> void:
	var flow := _flow()
	flow.clear()


func after_test() -> void:
	var flow := _flow()
	flow.clear()


func test_push_request_sets_current_mode() -> void:
	var flow := _flow()
	var request := FlowRequest.new()
	request.kind = FlowRequest.Kind.PUSH
	request.mode = _mode(&"menu")

	var result: FlowResult = flow.apply_request(request)

	assert_bool(result.success).is_true()
	assert_str(String(result.code)).is_equal("mode_pushed")
	assert_str(String(flow.current_mode().id)).is_equal("menu")
	assert_int(flow.stack_size()).is_equal(1)


func test_replace_and_pop_request_updates_stack() -> void:
	var flow := _flow()
	flow.push_mode(_mode(&"menu"))

	var replace_request := FlowRequest.new()
	replace_request.kind = FlowRequest.Kind.REPLACE
	replace_request.mode = _mode(&"run")
	var replace_result: FlowResult = flow.apply_request(replace_request)

	assert_bool(replace_result.success).is_true()
	assert_str(String(replace_result.code)).is_equal("mode_replaced")
	assert_str(String(flow.current_mode().id)).is_equal("run")
	assert_int(flow.stack_size()).is_equal(1)

	var pop_request := FlowRequest.new()
	pop_request.kind = FlowRequest.Kind.POP
	var pop_result: FlowResult = flow.apply_request(pop_request)

	assert_bool(pop_result.success).is_true()
	assert_str(String(pop_result.payload["mode"])).is_equal("run")
	assert_object(flow.current_mode()).is_null()
	assert_int(flow.stack_size()).is_equal(0)


func test_complete_flow_preserves_result_payload() -> void:
	var flow := _flow()
	var payload := {
		"winner": "player",
		"score": 42,
	}

	flow.complete_flow(FlowResult.ok(&"battle_won", payload))

	assert_bool(flow.last_result().success).is_true()
	assert_str(String(flow.last_result().code)).is_equal("battle_won")
	assert_dict(flow.last_result().payload).contains_key_value("winner", "player")
	assert_dict(flow.last_result().payload).contains_key_value("score", 42)


func test_flow_smoke_fixture_runs_minimal_flow() -> void:
	var flow := _flow()
	var fixture := FlowSmokeFixture.new()

	var report := fixture.run_minimal_flow(flow)

	assert_bool(report["success"]).is_true()
	assert_str(String(report["current_mode"])).is_equal("smoke")
	assert_str(String(report["result_code"])).is_equal("smoke_complete")
	assert_dict(report["payload"]).contains_key_value("mode", "smoke")


func _flow() -> FlowCoreService:
	return FlowCore as FlowCoreService


func _mode(mode_id: StringName) -> GameMode:
	var mode := GameMode.new()
	mode.id = mode_id
	mode.scene_path = "res://scenes/%s.tscn" % String(mode_id)
	return mode
