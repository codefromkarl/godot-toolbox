# sparkle_lite_inspector_plugin.gd
# EditorInspectorPlugin that swaps the default array editor for the
# `feedbacks` property on every FeedbackPlayerLite with a custom list UI.

@tool
class_name SparkleLiteInspectorPlugin
extends EditorInspectorPlugin

const _FEEDBACK_LIST_EDITOR_SCRIPT: Script = preload(
		"res://addons/sparkle_lite/editor/feedback_list_editor_lite.gd"
)

var _undo_redo: EditorUndoRedoManager = null


## Stores the EditorUndoRedoManager handed in by the plugin.
func set_undo_redo(ur: EditorUndoRedoManager) -> void:
	_undo_redo = ur


func _can_handle(object: Object) -> bool:
	return (
			object is FeedbackPlayerLite
			or object is FeedbackBaseLite
			or object is FeedbackPresetLite
	)


func _parse_property(
		object: Object,
		type: int,
		name: String,
		hint_type: int,
		hint_string: String,
		usage_flags: int,
		wide: bool
) -> bool:
	if name == "script":
		return true
	if not (object is FeedbackPlayerLite):
		return false
	if name != "feedbacks":
		return false
	var editor: EditorProperty = _FEEDBACK_LIST_EDITOR_SCRIPT.new()
	editor.configure(object, _undo_redo)
	add_property_editor(name, editor, true, "Feedbacks")
	return true
