extends RefCounted
class_name RPGQuestSaveAdapter


static func serialize(quest_state: Dictionary) -> Dictionary:
	return quest_state.duplicate(true)


static func deserialize(saved_state: Dictionary) -> Dictionary:
	return saved_state.duplicate(true)
