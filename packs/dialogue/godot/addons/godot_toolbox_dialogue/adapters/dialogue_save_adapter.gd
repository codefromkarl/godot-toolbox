extends RefCounted
class_name DialogueSaveAdapter

## Bridges dialogue state to save-core persistence via rpg-save-adapter.
## Dialogue Manager tracks active dialogue, visited lines, and variable state.
## This adapter serializes/deserializes dialogue state as a save payload fragment
## that rpg-save-adapter can include in its snapshot.


static func serialize(dialogue_state: Dictionary) -> Dictionary:
	## Serialize dialogue state for save-core snapshot.
	## Expected input: { "active_dialogue": "...", "variables": {...}, "visited": [...] }
	if dialogue_state.is_empty():
		return {}
	return dialogue_state.duplicate(true)


static func deserialize(saved_state: Dictionary) -> Dictionary:
	## Deserialize dialogue state from save-core snapshot.
	if saved_state.is_empty():
		return {
			"active_dialogue": "",
			"variables": {},
			"visited": [],
		}
	return saved_state.duplicate(true)


static func make_empty_state() -> Dictionary:
	return {
		"active_dialogue": "",
		"variables": {},
		"visited": [],
	}
