# plugin.gd
# EditorPlugin entry point for the Sparkle Lite addon.
# Registers the presets autoload and the FeedbackPlayerLite inspector
# plugin on enable, and tears them down cleanly on disable.

@tool
extends EditorPlugin

const _AUTOLOAD_NAME: StringName = &"SparkleLitePresets"
const _AUTOLOAD_PATH: String = \
		"res://addons/sparkle_lite/presets/feedback_presets_autoload_lite.gd"
const _InspectorPluginScript: Script = preload(
		"res://addons/sparkle_lite/editor/sparkle_lite_inspector_plugin.gd"
)

var _inspector_plugin: SparkleLiteInspectorPlugin = null


func _enter_tree() -> void:
	add_autoload_singleton(_AUTOLOAD_NAME, _AUTOLOAD_PATH)
	_inspector_plugin = _InspectorPluginScript.new()
	_inspector_plugin.set_undo_redo(get_undo_redo())
	add_inspector_plugin(_inspector_plugin)


func _exit_tree() -> void:
	if _inspector_plugin != null:
		remove_inspector_plugin(_inspector_plugin)
		_inspector_plugin = null
	# Clean up shared editor-time state held by feedbacks that allocate
	# under the SparkleLitePresets autoload — otherwise an editor plugin
	# reload leaves orphan CanvasLayers behind.
	FeedbackScreenFlash2DLite._reset()
	remove_autoload_singleton(_AUTOLOAD_NAME)
