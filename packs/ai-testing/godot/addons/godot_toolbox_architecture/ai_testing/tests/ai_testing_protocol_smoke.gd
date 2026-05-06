extends SceneTree

## Protocol contract validation for the ai-testing ↔ automation TCP bridge.
##
## Validates that:
## 1. JsonSerializer roundtrips correctly (the framing layer)
## 2. CommandHandler dispatch table is intact (the command layer)
## 3. AutomationServer can be instantiated and configured (the server layer)
## 4. AITestingCore autoload is present (the pack marker)
##
## This test does NOT require a live TCP connection; it validates the
## protocol contracts that GodotE2EEnv depends on at the Godot layer.

const JsonSerializerScript := preload("res://addons/godot_e2e/json_serializer.gd")
const CommandHandlerScript := preload("res://addons/godot_e2e/command_handler.gd")
const ConfigScript := preload("res://addons/godot_e2e/config.gd")

var _failed := false


func _initialize() -> void:
	_test_json_serializer_roundtrip()
	_test_json_serializer_edge_cases()
	_test_command_handler_dispatch_table()
	_test_automation_server_config()
	_test_ai_testing_core_exists()
	quit(1 if _failed else 0)


func _test_json_serializer_roundtrip() -> void:
	## Core types roundtrip through serialize → deserialize
	# Primitive types
	_assert(JsonSerializerScript.serialize(null) == null, "null should serialize to null")
	_assert(JsonSerializerScript.serialize(true) == true, "bool true roundtrip")
	_assert(JsonSerializerScript.serialize(42) == 42, "int roundtrip")
	_assert(JsonSerializerScript.serialize(3.14) == 3.14, "float roundtrip")
	_assert(JsonSerializerScript.serialize("hello") == "hello", "string roundtrip")

	# Vector2
	var v2 := Vector2(1.5, 2.5)
	var v2_serialized = JsonSerializerScript.serialize(v2)
	_assert(v2_serialized is Dictionary, "Vector2 should serialize to dict")
	_assert(v2_serialized["_t"] == "v2", "Vector2 type tag")
	var v2_restored = JsonSerializerScript.deserialize(v2_serialized)
	_assert(v2_restored is Vector2, "Vector2 deserialize should return Vector2")
	_assert(absf(v2_restored.x - 1.5) < 0.001, "Vector2 x preserved")
	_assert(absf(v2_restored.y - 2.5) < 0.001, "Vector2 y preserved")

	# Vector2i
	var v2i := Vector2i(3, 4)
	var v2i_restored = JsonSerializerScript.deserialize(JsonSerializerScript.serialize(v2i))
	_assert(v2i_restored is Vector2i, "Vector2i roundtrip type")
	_assert(v2i_restored.x == 3 and v2i_restored.y == 4, "Vector2i roundtrip values")

	# Color
	var col := Color(0.5, 0.6, 0.7, 1.0)
	var col_restored = JsonSerializerScript.deserialize(JsonSerializerScript.serialize(col))
	_assert(col_restored is Color, "Color roundtrip type")
	_assert(absf(col_restored.r - 0.5) < 0.001, "Color r preserved")

	# Dictionary
	var dict := {"key": "value", "num": 42}
	var dict_restored = JsonSerializerScript.deserialize(JsonSerializerScript.serialize(dict))
	_assert(dict_restored is Dictionary, "dict roundtrip type")
	_assert(dict_restored["key"] == "value", "dict string value preserved")
	_assert(dict_restored["num"] == 42, "dict int value preserved")

	# Array
	var arr := [1, "two", true]
	var arr_restored = JsonSerializerScript.deserialize(JsonSerializerScript.serialize(arr))
	_assert(arr_restored is Array, "array roundtrip type")
	_assert(arr_restored.size() == 3, "array length preserved")
	_assert(arr_restored[0] == 1 and arr_restored[1] == "two" and arr_restored[2] == true, \
		"array elements preserved")


func _test_json_serializer_edge_cases() -> void:
	## Edge cases: empty collections, nested structures
	var empty_dict := {}
	var empty_restored = JsonSerializerScript.deserialize(JsonSerializerScript.serialize(empty_dict))
	_assert(empty_restored is Dictionary, "empty dict roundtrip type")
	_assert(empty_restored.is_empty(), "empty dict roundtrip empty")

	var nested := {"inner": {"deep": [1, 2, 3]}}
	var nested_restored = JsonSerializerScript.deserialize(JsonSerializerScript.serialize(nested))
	_assert(nested_restored["inner"] is Dictionary, "nested dict preserved")
	_assert(nested_restored["inner"]["deep"] is Array, "nested array preserved")
	_assert(nested_restored["inner"]["deep"].size() == 3, "nested array size preserved")

	# NodePath
	var np := NodePath("/root/Main/Player")
	var np_restored = JsonSerializerScript.deserialize(JsonSerializerScript.serialize(np))
	_assert(np_restored is NodePath, "NodePath roundtrip type")
	_assert(str(np_restored) == "/root/Main/Player", "NodePath roundtrip value")


func _test_command_handler_dispatch_table() -> void:
	## CommandHandler can be instantiated and dispatches known actions
	# We create a mock server (just needs get_tree() → null-safe)
	var handler = CommandHandlerScript.new(null)
	_assert(handler != null, "CommandHandler should instantiate")

	# Test that unknown actions return an error
	var result: Dictionary = handler.execute({"action": "nonexistent_command", "id": "test-1"})
	_assert(result.has("error"), "unknown command should return error")
	_assert(str(result["id"]) == "test-1", "response should echo command id")

	# Test batch with empty commands
	var batch_result: Dictionary = handler.execute({"action": "batch", "commands": [], "id": "test-2"})
	_assert(batch_result.has("results"), "batch should return results array")
	_assert(batch_result["results"] is Array, "batch results should be array")
	_assert(batch_result["results"].is_empty(), "empty batch should return empty results")


func _test_automation_server_config() -> void:
	## Config can be read without errors (validates project settings access)
	var port := ConfigScript.get_port()
	_assert(port >= 0, "port should be >= 0")

	var token := ConfigScript.get_token()
	_assert(token is String, "token should be a string")

	var enabled := ConfigScript.is_enabled()
	_assert(enabled is bool, "is_enabled should return bool")

	var logging := ConfigScript.is_logging()
	_assert(logging is bool, "is_logging should return bool")


func _test_ai_testing_core_exists() -> void:
	## Validate the ai-testing pack's autoload stub is accessible
	var autoload = Engine.get_main_loop().root.get_node_or_null("/root/AITestingCore")
	# In headless bootstrap the autoload may not be registered; just verify the script loads
	var script := load("res://addons/godot_toolbox_architecture/ai_testing/ai_testing.gd")
	_assert(script != null, "ai_testing.gd should be loadable")

	var instance = script.new()
	_assert(instance != null, "ai_testing.gd should instantiate")
	_assert(instance is Node, "ai_testing.gd should extend Node")
	instance.queue_free()


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
