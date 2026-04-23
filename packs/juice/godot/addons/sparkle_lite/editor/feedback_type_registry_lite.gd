# feedback_type_registry_lite.gd
# Single source of truth mapping feedback script paths to their display
# metadata (label, accent color, icon). Used by the inspector list and
# the Add-Feedback menu. Editor-only — never touched by runtime.

@tool
class_name FeedbackTypeRegistryLite
extends RefCounted

## Registry of [FeedbackBaseLite] subclasses shipped with Sparkle Lite
## and their inspector presentation metadata.

const _ENTRIES: Array[Dictionary] = [
	{
		"label": "Camera Shake",
		"description": "Layered-noise shake on Camera3D(s). Per-axis toggles + Vector3 amplitudes + Curves, AUTO / ACTIVE / BY_PATH / BY_GROUP selection, optional distance falloff.",
		"script_path": "res://addons/sparkle_lite/feedbacks/feedback_camera_shake_lite.gd",
		"class_name": "FeedbackCameraShakeLite",
		"color": Color("#4A90E2"),
		"icon_path": "res://addons/sparkle_lite/editor/icons/camera_shake.svg",
	},
	{
		"label": "Camera Shake 2D",
		"description": "Layered-noise shake on Camera2D(s). Vector2 position amplitude + single rotation axis, AUTO / ACTIVE / BY_PATH / BY_GROUP selection, optional distance falloff in pixels.",
		"script_path": "res://addons/sparkle_lite/feedbacks/feedback_camera_shake_2d_lite.gd",
		"class_name": "FeedbackCameraShake2DLite",
		"color": Color("#6AB4F2"),
		"icon_path": "res://addons/sparkle_lite/editor/icons/camera_shake.svg",
	},
	{
		"label": "Hit Pause",
		"description": "Drops Engine.time_scale briefly for hit-stop impact. Lowest-wins stacking; hard-capped at 500 ms.",
		"script_path": "res://addons/sparkle_lite/feedbacks/feedback_hit_pause_lite.gd",
		"class_name": "FeedbackHitPauseLite",
		"color": Color("#E24A4A"),
		"icon_path": "res://addons/sparkle_lite/editor/icons/hit_pause.svg",
	},
	{
		"label": "Screen Flash 2D",
		"description": "Full-viewport colour flash on a shared CanvasLayer overlay. Max-intensity stacking, ADD or MODULATE blend.",
		"script_path": "res://addons/sparkle_lite/feedbacks/feedback_screen_flash_2d_lite.gd",
		"class_name": "FeedbackScreenFlash2DLite",
		"color": Color("#FFFFFF"),
		"icon_path": "res://addons/sparkle_lite/editor/icons/screen_flash_2d.svg",
	},
	{
		"label": "Audio",
		"description": "Plays an audio clip with pitch randomisation. POOL / CACHE / ONE_TIME allocation.",
		"script_path": "res://addons/sparkle_lite/feedbacks/feedback_audio_lite.gd",
		"class_name": "FeedbackAudioLite",
		"color": Color("#E2C64A"),
		"icon_path": "res://addons/sparkle_lite/editor/icons/audio.svg",
	},
	{
		"label": "Scale Punch",
		"description": "Elastic scale pop on a Node2D / Node3D / Control target. Last-starts-wins per target.",
		"script_path": "res://addons/sparkle_lite/feedbacks/feedback_scale_punch_lite.gd",
		"class_name": "FeedbackScalePunchLite",
		"color": Color("#FF8C42"),
		"icon_path": "res://addons/sparkle_lite/editor/icons/scale_punch.svg",
	},
	{
		"label": "Call",
		"description": "Calls a method or emits a signal on a target node. Bridge between a feedback sequence and gameplay code.",
		"script_path": "res://addons/sparkle_lite/feedbacks/feedback_call_lite.gd",
		"class_name": "FeedbackCallLite",
		"color": Color("#9EB24A"),
		"icon_path": "res://addons/sparkle_lite/editor/icons/call.svg",
	},
]


## Returns every registered entry in its declared order.
static func get_entries() -> Array[Dictionary]:
	return _ENTRIES.duplicate()


## Returns the entry matching [param feedback], or an empty dict.
static func lookup(feedback: FeedbackBaseLite) -> Dictionary:
	if feedback == null:
		return {}
	var script: Script = feedback.get_script()
	if script == null:
		return {}
	var path: String = script.resource_path
	for entry in _ENTRIES:
		if entry["script_path"] == path:
			return entry
	return {}


## Loads the icon [Texture2D] for a feedback.
static func get_icon(feedback: FeedbackBaseLite) -> Texture2D:
	var entry: Dictionary = lookup(feedback)
	if entry.is_empty():
		return null
	var path: String = entry["icon_path"]
	if not ResourceLoader.exists(path):
		return null
	var resource: Resource = load(path)
	if resource is Texture2D:
		return resource
	return null


## Instantiates a new feedback of the type at [param index].
static func instantiate_at(index: int) -> FeedbackBaseLite:
	if index < 0 or index >= _ENTRIES.size():
		return null
	var script: Script = load(_ENTRIES[index]["script_path"])
	if script == null:
		return null
	var fb: FeedbackBaseLite = script.new()
	fb.label = _ENTRIES[index]["label"]
	return fb


## Accent color for a feedback's row border.
static func get_color(feedback: FeedbackBaseLite) -> Color:
	var entry: Dictionary = lookup(feedback)
	if entry.is_empty():
		return Color(0.5, 0.5, 0.5)
	return entry["color"]


## Display label for a registered feedback type.
static func get_display_label(feedback: FeedbackBaseLite) -> String:
	var entry: Dictionary = lookup(feedback)
	if entry.is_empty():
		if feedback == null:
			return "Unknown"
		return feedback._get_default_label()
	return entry["label"]


## One-line human-readable description for [param feedback].
static func get_description(feedback: FeedbackBaseLite) -> String:
	var entry: Dictionary = lookup(feedback)
	if entry.is_empty():
		return ""
	return entry.get("description", "")
