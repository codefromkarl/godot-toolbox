# feedback_presets_autoload.gd
# Autoload singleton registered by plugin.gd. Hosts the global preset
# registry and the shared SparkleLiteAudioPool parent node for pooled
# audio stream players.

@tool
class_name FeedbackPresetsAutoloadLite
extends Node

## Autoload singleton exposing named [FeedbackPresetLite]s to gameplay
## code. Registered as [code]SparkleLitePresets[/code] by
## [code]plugin.gd[/code]. Also owns the persistent audio pool parent.

const _AUDIO_POOL_NAME: StringName = &"SparkleLiteAudioPool"

var _presets: Dictionary = {}
var _audio_pool: Node = null


func _ready() -> void:
	_audio_pool = Node.new()
	_audio_pool.name = _AUDIO_POOL_NAME
	add_child(_audio_pool)


## Registers a preset under [param name]. Overwrites any existing entry.
func register_preset(name: StringName, preset: FeedbackPresetLite) -> void:
	if preset == null:
		push_warning(
			"Sparkle Lite: register_preset('%s', null) ignored." % name
		)
		return
	_presets[name] = preset


## Returns the preset registered under [param name], or null.
func get_preset(name: StringName) -> FeedbackPresetLite:
	return _presets.get(name, null)


## Returns true if a preset is registered under [param name].
func has_preset(name: StringName) -> bool:
	return _presets.has(name)


## Returns the list of registered preset names.
func list_presets() -> Array:
	return _presets.keys()


## Finds the nearest [FeedbackPlayerLite] in the current scene and
## plays the named preset on it.
func play(name: StringName, intensity: float = 1.0) -> void:
	var preset: FeedbackPresetLite = get_preset(name)
	if preset == null:
		push_warning(
			"Sparkle Lite: preset '%s' is not registered." % name
		)
		return
	var target: Node = _find_nearest_player()
	if target == null:
		push_warning(
			("Sparkle Lite: no FeedbackPlayerLite found in the current "
			+ "scene to play preset '%s' on.") % name
		)
		return
	play_on(name, target, intensity)


## Plays [param name] on the given [param player], temporarily swapping
## its feedback list. Restores the player's original feedbacks when
## the preset completes or is stopped.
func play_on(
		name: StringName,
		player: Node,
		intensity: float = 1.0
) -> void:
	if player == null or not is_instance_valid(player):
		return
	var preset: FeedbackPresetLite = get_preset(name)
	if preset == null:
		push_warning(
			"Sparkle Lite: preset '%s' is not registered." % name
		)
		return
	if not (player is FeedbackPlayerLite):
		push_warning(
			"Sparkle Lite: play_on target is not a FeedbackPlayerLite (%s)."
			% player.get_class()
		)
		return
	var fp: FeedbackPlayerLite = player
	var snapshot: Array = fp.feedbacks.duplicate()
	fp.feedbacks = preset.feedbacks.duplicate()
	var restore := func ():
		if is_instance_valid(fp):
			fp.feedbacks = snapshot
	fp.completed.connect(restore, CONNECT_ONE_SHOT)
	fp.play(intensity)


## Scans [param path] for [code].tres[/code] files, loads each as a
## [FeedbackPresetLite], and registers them by filename.
func load_preset_folder(path: String) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		push_warning(
			"Sparkle Lite: could not open preset folder '%s'." % path
		)
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if (
				not dir.current_is_dir()
				and file_name.get_extension() == "tres"
		):
			var full_path: String = path.path_join(file_name)
			var loaded: Resource = ResourceLoader.load(full_path)
			if loaded is FeedbackPresetLite:
				var base: String = file_name.get_basename()
				register_preset(base, loaded)
			else:
				push_warning(
					"Sparkle Lite: '%s' is not a FeedbackPresetLite — skipping."
					% full_path
				)
		file_name = dir.get_next()
	dir.list_dir_end()


func _find_nearest_player() -> Node:
	var tree: SceneTree = get_tree()
	if tree == null or tree.current_scene == null:
		return null
	return _search_player(tree.current_scene)


func _search_player(node: Node) -> Node:
	if node is FeedbackPlayerLite:
		return node
	for child in node.get_children():
		var found: Node = _search_player(child)
		if found != null:
			return found
	return null
