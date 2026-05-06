class_name InteractionTestHelper
extends Node
## Reusable interaction test helper singleton/autoload.
##
## Provides standardized input simulation, UI button interaction,
## and screenshot capture utilities for interaction evidence runners.
## Adapted from stardrifter's testing utilities with class_name added.


## Simulate a key press with hold duration.
## @param action_name: InputMap action name (e.g. "fire_primary")
## @param hold_frames: Number of physics frames to hold the key
func simulate_key_press(action_name: String, hold_frames: int = 1) -> void:
	Input.action_press(action_name)
	for _i in range(hold_frames):
		await Engine.get_main_loop().physics_frame
	Input.action_release(action_name)
	await Engine.get_main_loop().physics_frame


## Click a UI button via pressed.emit().
## @param button: The Button node to click
func click_button(button: Button) -> void:
	button.pressed.emit()
	await Engine.get_main_loop().process_frame


## Simulate a mouse click at a position in a viewport.
## Creates an InputEventMouseButton and sends it via viewport.push_input().
## @param viewport: The target Viewport
## @param position: Click position in viewport coordinates
func simulate_mouse_click(viewport: Viewport, position: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = position
	event.pressed = true
	viewport.push_input(event)
	await Engine.get_main_loop().process_frame
	event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = position
	event.pressed = false
	viewport.push_input(event)
	await Engine.get_main_loop().process_frame


## Capture screenshot to file.
## Returns a status string: "saved", "image_unavailable_headless", "image_null", or "save_failed".
## @param viewport: The Viewport to capture
## @param path: Absolute file path for the PNG output
func capture_screenshot(viewport: Viewport, path: String) -> String:
	if DisplayServer.get_name() == "headless":
		return "image_unavailable_headless"
	var image := viewport.get_texture().get_image()
	if image == null:
		return "image_null"
	return "saved" if image.save_png(path) == OK else "save_failed"


## Wait for a condition to become true, with timeout.
## @param condition: Callable that returns bool
## @param max_frames: Maximum physics frames to wait
## @param step_frames: Physics frames between checks
## @return: true if condition met within timeout, false otherwise
func wait_for(condition: Callable, max_frames: int = 60, step_frames: int = 1) -> bool:
	for _i in range(max_frames):
		if condition.call():
			return true
		for _j in range(step_frames):
			await Engine.get_main_loop().physics_frame
	return false


## Build a standard timestamp dictionary for evidence records.
func build_timestamp_dict() -> Dictionary:
	return {
		"utc": Time.get_datetime_string_from_system(),
		"unix_ms": Time.get_unix_time_from_system() * 1000.0,
		"ticks_msec": Time.get_ticks_msec(),
	}
