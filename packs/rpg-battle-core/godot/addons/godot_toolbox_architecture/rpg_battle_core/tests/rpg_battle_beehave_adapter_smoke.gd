extends SceneTree

const BeehaveAdapterScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/adapters/beehave_ai_adapter.gd")

var _failed := false


func _initialize() -> void:
	var adapter: Resource = BeehaveAdapterScript.new()
	_assert(adapter.is_optional(), "Beehave adapter should be optional")
	_assert(adapter.adapter_id() == &"beehave", "Beehave adapter should expose adapter id")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
