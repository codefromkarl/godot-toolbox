extends RefCounted
class_name DialogueContentAdapter

## Bridges dialogue content IDs to data-core GameId validation.
## Dialogue Manager uses resource paths and speaker names as content identifiers.
## This adapter validates those against data-core's GameId conventions and provides
## stable ID extraction for registry lookups.

const GameIdScript := preload("res://addons/godot_toolbox_architecture/data_core/game_id.gd")


static func speaker_to_game_id(speaker_name: String) -> StringName:
	## Convert a dialogue speaker name to a stable data-core GameId.
	## Example: "Elder" -> "speaker/elder"
	if speaker_name.strip_edges().is_empty():
		return &""
	var id_text := "speaker/" + speaker_name.to_lower().replace(" ", "_")
	var id: StringName = StringName(id_text)
	if GameIdScript.is_valid_id(id):
		return id
	return &""


static func resource_path_to_dialogue_id(path: String) -> StringName:
	## Convert a dialogue resource path to a stable data-core GameId.
	## Example: "res://dialogue/elder_quest.tres" -> "dialogue/elder_quest"
	if path.is_empty():
		return &""
	var file_name: String = path.get_file().replace("." + path.get_extension(), "")
	if file_name.is_empty():
		return &""
	var id_text := "dialogue/" + file_name
	var id: StringName = StringName(id_text)
	if GameIdScript.is_valid_id(id):
		return id
	return &""


static func validate_speaker_id(speaker_name: String) -> bool:
	var id := speaker_to_game_id(speaker_name)
	return not String(id).is_empty()


static func validate_dialogue_id(path: String) -> bool:
	var id := resource_path_to_dialogue_id(path)
	return not String(id).is_empty()
