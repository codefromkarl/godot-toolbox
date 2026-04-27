extends Resource
class_name ContentManifest

@export var content_namespace: StringName
@export var resources: Array[Resource] = []
@export var entries: Dictionary = {}


static func from_dictionary(data: Dictionary) -> Resource:
	var manifest := ContentManifest.new()
	manifest.content_namespace = StringName(str(data.get("namespace", "")))
	var raw_entries: Variant = data.get("entries", {})
	if typeof(raw_entries) == TYPE_DICTIONARY:
		manifest.entries = (raw_entries as Dictionary).duplicate(true)
	return manifest


static func from_json_file(path: String) -> Resource:
	if not FileAccess.file_exists(path):
		return null
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	return from_dictionary(parsed)


func ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for id in entries.keys():
		result.append(StringName(str(id)))
	result.sort()
	return result
