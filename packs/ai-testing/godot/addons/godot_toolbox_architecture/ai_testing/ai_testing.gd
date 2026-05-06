extends Node
## AITestingCore autoload.
##
## Singleton for the ai-testing pack. Provides:
## - Pack enabled marker (signifies ai-testing is active)
## - Episode tracking (count and status registry)
## - Observation export (collects state for Python-side analysis)
##
## Actual AI testing orchestration (policies, runners, coverage) happens
## on the Python side; this autoload provides runtime session services
## that Godot-side code can query.

## Emitted when a new test session starts.
signal session_started(session_id: String)
## Emitted when a test session ends.
signal session_ended(session_id: String, status: String)

## Total episodes completed since scene load.
var episode_count: int = 0
## Episodes that ended in "passed" status.
var passed_count: int = 0
## Episodes that ended in "failed" status.
var failed_count: int = 0
## Whether the ai-testing pack is enabled (always true if autoload is active).
var pack_enabled: bool = true

## Current session ID (set by Python bridge or test harness).
var current_session_id: String = ""

## Collected observation snapshots for the current session.
## Each entry is a Dictionary with "step" and "observation" keys.
var _observation_buffer: Array[Dictionary] = []


func _ready() -> void:
	pack_enabled = true
	episode_count = 0
	passed_count = 0
	failed_count = 0


## Record a completed episode with its status.
## Call this from test harnesses to track episode results.
func record_episode(status: String) -> void:
	episode_count += 1
	match status:
		"passed":
			passed_count += 1
		"failed":
			failed_count += 1


## Begin a new test session, clearing observation buffer.
func begin_session(session_id: String) -> void:
	current_session_id = session_id
	_observation_buffer.clear()
	session_started.emit(session_id)


## End the current test session.
func end_session(status: String = "") -> void:
	session_ended.emit(current_session_id, status)
	current_session_id = ""


## Push an observation snapshot into the buffer.
func push_observation(step: int, observation: Dictionary) -> void:
	_observation_buffer.append({
		"step": step,
		"observation": observation.duplicate(true),
	})


## Return all buffered observations and clear the buffer.
func flush_observations() -> Array[Dictionary]:
	var result := _obs_buffer_duplicate()
	_observation_buffer.clear()
	return result


## Return the current buffer size without clearing.
func observation_count() -> int:
	return _observation_buffer.size()


## Return a summary dict for diagnostics and export.
func session_summary() -> Dictionary:
	return {
		"session_id": current_session_id,
		"episode_count": episode_count,
		"passed_count": passed_count,
		"failed_count": failed_count,
		"observation_count": observation_count(),
		"pack_enabled": pack_enabled,
	}


## Reset all counters and buffers. Useful between test suites.
func reset() -> void:
	episode_count = 0
	passed_count = 0
	failed_count = 0
	current_session_id = ""
	_observation_buffer.clear()


func _obs_buffer_duplicate() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	result.assign(_observation_buffer.map(
		func(entry: Dictionary) -> Dictionary:
			return entry.duplicate(true)
	))
	return result
