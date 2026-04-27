extends SceneTree

const FlowCoreScript := preload("res://addons/godot_toolbox_architecture/flow_core/flow_core.gd")
const FlowRequestScript := preload("res://addons/godot_toolbox_architecture/flow_core/flow_request.gd")
const FlowResultScript := preload("res://addons/godot_toolbox_architecture/flow_core/flow_result.gd")
const GameModeScript := preload("res://addons/godot_toolbox_architecture/flow_core/game_mode.gd")
const SimulationCoreScript := preload("res://addons/godot_toolbox_architecture/simulation_core/simulation_core.gd")
const GameSystemScript := preload("res://addons/godot_toolbox_architecture/simulation_core/game_system.gd")
const DataCoreScript := preload("res://addons/godot_toolbox_architecture/data_core/data_core.gd")
const SaveCoreScript := preload("res://addons/godot_toolbox_architecture/save_core/save_core.gd")

var _failed := false
var _tick_order: Array[String] = []


class RecordingSystem:
	extends GameSystem

	var system_id: String
	var sink: Array[String]

	func _init(next_id: String, next_priority: int, next_sink: Array[String]) -> void:
		system_id = next_id
		priority = next_priority
		sink = next_sink

	func tick(_delta: float) -> void:
		sink.append(system_id)


func _initialize() -> void:
	_verify_flow()
	_verify_simulation()
	_verify_data_and_save()
	_finish()


func _verify_flow() -> void:
	var flow: Node = FlowCoreScript.new()
	var mode: Resource = GameModeScript.new()
	mode.id = &"spine/run"
	mode.scene_path = "res://scenes/main.tscn"

	var push_result: Resource = flow.apply_request(FlowRequestScript.push(mode))
	_assert(push_result.success, "flow push should succeed")
	_assert(String(flow.current_mode().id) == "spine/run", "flow should expose current mode")

	var complete_result: Resource = flow.apply_request(
		FlowRequestScript.complete(FlowResultScript.ok(&"spine_complete", {"score": 7}))
	)
	_assert(complete_result.success, "flow complete should succeed")
	_assert(int(flow.last_result().payload["score"]) == 7, "flow should preserve result payload")
	flow.free()


func _verify_simulation() -> void:
	var simulation: Node = SimulationCoreScript.new()
	var late := RecordingSystem.new("late", 20, _tick_order)
	var early := RecordingSystem.new("early", 10, _tick_order)
	simulation.register_system(late)
	simulation.register_system(early)
	simulation.tick(0.5)
	_assert(_tick_order == ["early", "late"], "simulation should tick systems by priority")

	_tick_order.clear()
	early.enabled = false
	simulation.tick(0.5)
	_assert(_tick_order == ["late"], "simulation should skip disabled systems")

	_tick_order.clear()
	late.tick_when_paused = true
	late.pause_domain = &"ui"
	simulation.paused = true
	simulation.active_pause_domain = &"ui"
	simulation.tick(0.5)
	_assert(_tick_order == ["late"], "simulation should allow matching paused domain")
	simulation.free()


func _verify_data_and_save() -> void:
	var data_core: Node = DataCoreScript.new()
	var manifest: Resource = data_core.load_manifest_from_dictionary({
		"namespace": "spine",
		"entries": {
			"spine/player": {"name": "Player"},
			"spine/world": {"name": "World"},
		},
	})
	var report: Dictionary = data_core.validate_manifest(manifest)
	_assert(report["ok"], "data manifest should validate stable ids")
	_assert(report["ids"].size() == 2, "data manifest should expose ids")
	_assert(data_core.register_resource(&"spine/player", Resource.new()) == OK, "data core should register manifest id")

	var save_core: Node = SaveCoreScript.new()
	var snapshot: Resource = save_core.create_snapshot({"ids": data_core.list_ids(), "flow": "spine/run"})
	var save_path := "user://architecture_spine_smoke.json"
	_assert(save_core.save_json(save_path, snapshot) == OK, "save core should write snapshot")
	var loaded: Resource = save_core.load_json(save_path)
	_assert(loaded != null, "save core should load snapshot")
	_assert(String(loaded.payload["flow"]) == "spine/run", "save core should preserve payload")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	var backup_path := "%s.bak" % save_path
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_path))
	data_core.free()
	save_core.free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true


func _finish() -> void:
	quit(1 if _failed else 0)
