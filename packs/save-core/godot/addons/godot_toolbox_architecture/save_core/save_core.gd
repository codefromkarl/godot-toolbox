extends Node
class_name SaveCoreService

const CURRENT_SCHEMA_VERSION := 1
const SaveSnapshotScript := preload("res://addons/godot_toolbox_architecture/save_core/save_snapshot.gd")
const SaveSlotScript := preload("res://addons/godot_toolbox_architecture/save_core/save_slot.gd")

signal snapshot_saved(path: String)
signal snapshot_loaded(path: String, snapshot: Resource)

var keep_backup_on_overwrite: bool = true
var _migrations: Dictionary = {}


func create_snapshot(payload: Dictionary = {}) -> Resource:
	var snapshot: Resource = SaveSnapshotScript.new()
	snapshot.schema_version = CURRENT_SCHEMA_VERSION
	snapshot.payload = payload.duplicate(true)
	return snapshot


func create_slot(id: StringName, display_name: String, path: String) -> Resource:
	var slot: Resource = SaveSlotScript.new()
	slot.id = id
	slot.display_name = display_name
	slot.path = path
	slot.schema_version = CURRENT_SCHEMA_VERSION
	slot.updated_at_unix = int(Time.get_unix_time_from_system())
	return slot


func register_migration(from_version: int, migration: Callable) -> void:
	_migrations[from_version] = migration


func save_json(path: String, snapshot: Resource) -> Error:
	if snapshot == null:
		return ERR_INVALID_PARAMETER
	if not snapshot.has_method("to_dictionary"):
		return ERR_INVALID_PARAMETER
	if path.is_empty():
		return ERR_INVALID_PARAMETER
	var err := _ensure_parent_dir(path)
	if err != OK:
		return err
	var tmp_path := "%s.tmp" % path
	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot.to_dictionary(), "\t"))
	file.close()
	err = _commit_tmp_file(tmp_path, path)
	if err == OK:
		snapshot_saved.emit(path)
	return err


func load_json(path: String) -> Resource:
	if not FileAccess.file_exists(path):
		return null
	var text := FileAccess.get_file_as_string(path)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	var snapshot: Resource = SaveSnapshotScript.from_dictionary(parsed)
	snapshot = _apply_migrations(snapshot)
	snapshot_loaded.emit(path, snapshot)
	return snapshot


func _apply_migrations(snapshot: Resource) -> Resource:
	while snapshot != null and snapshot.schema_version < CURRENT_SCHEMA_VERSION:
		var migration: Callable = _migrations.get(snapshot.schema_version, Callable())
		if not migration.is_valid():
			break
		var migrated: Variant = migration.call(snapshot)
		if migrated is Resource:
			snapshot = migrated
		else:
			break
	return snapshot


func _ensure_parent_dir(path: String) -> Error:
	var base_dir := path.get_base_dir()
	if base_dir.is_empty() or base_dir == path:
		return OK
	var absolute_dir := ProjectSettings.globalize_path(base_dir)
	return DirAccess.make_dir_recursive_absolute(absolute_dir)


func _commit_tmp_file(tmp_path: String, path: String) -> Error:
	var absolute_tmp_path := ProjectSettings.globalize_path(tmp_path)
	var absolute_path := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(path):
		return DirAccess.rename_absolute(absolute_tmp_path, absolute_path)

	var backup_path := "%s.bak" % path
	var absolute_backup_path := ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(absolute_backup_path)

	var err := DirAccess.rename_absolute(absolute_path, absolute_backup_path)
	if err != OK:
		DirAccess.remove_absolute(absolute_tmp_path)
		return err

	err = DirAccess.rename_absolute(absolute_tmp_path, absolute_path)
	if err != OK:
		DirAccess.rename_absolute(absolute_backup_path, absolute_path)
		return err

	if not keep_backup_on_overwrite:
		DirAccess.remove_absolute(absolute_backup_path)
	return OK
