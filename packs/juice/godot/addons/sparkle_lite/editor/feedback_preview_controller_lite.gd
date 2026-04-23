# feedback_preview_controller.gd
# Drives in-editor preview for a FeedbackPlayerLite.

@tool
class_name FeedbackPreviewControllerLite
extends RefCounted

## Controls the in-editor Preview button on the [FeedbackPlayerLite]
## inspector panel. Calls the player's real [method FeedbackPlayerLite.play].

signal state_changed(is_running: bool)

signal preview_diagnostics(entries: Array)

var _player_ref: WeakRef = null
var _running: bool = false
var _completed_callable: Callable = Callable()
var _disabled_for_preview: Array = []


## Starts preview on [param player].
func start(player: FeedbackPlayerLite) -> void:
	if _running:
		return
	if player == null or not is_instance_valid(player):
		return
	_player_ref = weakref(player)
	var diagnostics: Array = _collect_diagnostics(player)
	preview_diagnostics.emit(diagnostics)
	_disable_failing(diagnostics)
	if not _has_runnable_feedback(player):
		_restore_disabled()
		return
	_completed_callable = Callable(self, "_on_completed")
	if not player.completed.is_connected(_completed_callable):
		player.completed.connect(
				_completed_callable, CONNECT_ONE_SHOT
		)
	_running = true
	state_changed.emit(true)
	player.play()


## Stops preview. Safe to call at any time.
func stop() -> void:
	if not _running:
		_restore_disabled()
		return
	var player: FeedbackPlayerLite = _get_player()
	if player != null:
		if (
				_completed_callable.is_valid()
				and player.completed.is_connected(_completed_callable)
		):
			player.completed.disconnect(_completed_callable)
		player.stop()
	_running = false
	_restore_disabled()
	state_changed.emit(false)


## Returns true while a preview is active.
func is_running() -> bool:
	return _running


func _on_completed() -> void:
	_running = false
	_restore_disabled()
	state_changed.emit(false)


func _get_player() -> FeedbackPlayerLite:
	if _player_ref == null:
		return null
	var ref: Object = _player_ref.get_ref()
	if ref == null or not is_instance_valid(ref):
		return null
	if not (ref is FeedbackPlayerLite):
		return null
	return ref


func _collect_diagnostics(player: FeedbackPlayerLite) -> Array:
	var out: Array = []
	for feedback in player.feedbacks:
		if feedback == null:
			continue
		if not feedback.enabled:
			continue
		var reason: String = feedback.get_preview_diagnostic(player)
		if reason.is_empty():
			continue
		out.append({
			"feedback": feedback,
			"label": feedback.get_display_label(),
			"reason": reason,
		})
	return out


func _disable_failing(diagnostics: Array) -> void:
	_disabled_for_preview.clear()
	for entry in diagnostics:
		var feedback: FeedbackBaseLite = entry.get("feedback")
		if feedback == null:
			continue
		_disabled_for_preview.append({
			"feedback": feedback,
			"was_enabled": feedback.enabled,
		})
		feedback.enabled = false


func _restore_disabled() -> void:
	for entry in _disabled_for_preview:
		var feedback: FeedbackBaseLite = entry.get("feedback")
		if feedback == null or not is_instance_valid(feedback):
			continue
		feedback.enabled = entry.get("was_enabled", true)
	_disabled_for_preview.clear()


func _has_runnable_feedback(player: FeedbackPlayerLite) -> bool:
	for feedback in player.feedbacks:
		if feedback == null:
			continue
		if feedback.enabled:
			return true
	return false
