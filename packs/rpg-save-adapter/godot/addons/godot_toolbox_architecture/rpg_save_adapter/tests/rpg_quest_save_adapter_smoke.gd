extends SceneTree

const QuestSaveAdapterScript := preload("res://addons/godot_toolbox_architecture/rpg_save_adapter/adapters/quest_save_adapter.gd")

var _failed := false


func _initialize() -> void:
	var quest_state := {
		"quest/tutorial": {
			"state": "active",
			"objectives": {"talk_to_elder": 1},
		},
	}
	var saved: Dictionary = QuestSaveAdapterScript.serialize(quest_state)
	var restored: Dictionary = QuestSaveAdapterScript.deserialize(saved)
	_assert(restored["quest/tutorial"]["state"] == "active", "quest adapter should preserve quest state")
	_assert(restored["quest/tutorial"]["objectives"]["talk_to_elder"] == 1, "quest adapter should preserve objective progress")
	quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
