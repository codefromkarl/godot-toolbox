# Contract smoke test for godot-toolbox bootstrap integrity.
# Verifies that the bootstrapped project has the expected scaffold layout:
#   - project.godot rendered from template (no stale .in file)
#   - gdUnit4 plugin installed and self-consistent
#   - main scene present
#   - GdUnitTestSuite framework loadable
extends GdUnitTestSuite

## --- project.godot rendering contracts ---


func test_project_godot_exists() -> void:
	# Bootstrap must render project.godot from project.godot.in
	assert_file("res://project.godot").exists()


func test_project_godot_in_removed() -> void:
	# Bootstrap must clean up the .in template after rendering
	assert_bool(FileAccess.file_exists("res://project.godot.in")).is_false()


func test_project_godot_is_nonempty() -> void:
	var content: String = FileAccess.get_file_as_string("res://project.godot")
	assert_bool(content.length() > 0).is_true()


func test_project_godot_has_config_version() -> void:
	var content: String = FileAccess.get_file_as_string("res://project.godot")
	assert_bool(content.find("config_version=") >= 0).is_true()


func test_project_godot_targets_godot_4() -> void:
	var content: String = FileAccess.get_file_as_string("res://project.godot")
	assert_bool(content.find("4.6") >= 0).is_true()


## --- gdUnit4 plugin contracts ---


func test_gdunit4_plugin_cfg_exists() -> void:
	assert_file("res://addons/gdUnit4/plugin.cfg").exists()


func test_gdunit4_plugin_cfg_has_name() -> void:
	var content: String = FileAccess.get_file_as_string("res://addons/gdUnit4/plugin.cfg")
	assert_bool(content.find('name="gdUnit4"') >= 0).is_true()


func test_gdunit4_plugin_cfg_has_version() -> void:
	var content: String = FileAccess.get_file_as_string("res://addons/gdUnit4/plugin.cfg")
	assert_bool(content.find("version=") >= 0).is_true()


func test_gdunit4_plugin_script_exists() -> void:
	assert_file("res://addons/gdUnit4/plugin.gd").exists()


func test_gdunit4_runtest_exists() -> void:
	assert_file("res://addons/gdUnit4/runtest.sh").exists()


## --- scene scaffold contracts ---


func test_main_scene_exists() -> void:
	assert_file("res://scenes/main.tscn").exists()


func test_main_scene_is_valid_gd_scene() -> void:
	var content: String = FileAccess.get_file_as_string("res://scenes/main.tscn")
	assert_bool(content.find("[gd_scene") >= 0).is_true()


## --- framework health ---


func test_gdunit_framework_loadable() -> void:
	# If this test runs at all, GdUnitTestSuite is available.
	# Verify the assert API works end-to-end with a non-trivial check.
	var test_value: int = 42
	assert_int(test_value).is_equal(42)
