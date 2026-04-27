extends Resource
class_name GameId

@export var value: StringName


static func is_valid_id(id: StringName) -> bool:
	var text := String(id)
	if text.is_empty() or text != text.strip_edges():
		return false
	if text.begins_with("/") or text.ends_with("/") or text.contains("//"):
		return false
	for character in text:
		if character == " " or character == "\t" or character == "\n" or character == "\r":
			return false
	return true


func is_valid() -> bool:
	return is_valid_id(value)
