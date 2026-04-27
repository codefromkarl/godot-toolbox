extends SceneTree

var _failed := false


func _initialize() -> void:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://content/rpg_example/rpg_example_content.json"))
	_assert(parsed is Dictionary, "example content should parse as a dictionary")
	var content: Dictionary = parsed
	_verify_required_collections(content)
	_verify_unique_ids(content)
	_verify_stats_and_rewards(content)
	if not _failed:
		print("RPG_EDGE_CONTENT_OK heroes=%s enemies=%s skills=%s items=%s equipment=%s" % [
			content["heroes"].size(),
			content["enemies"].size(),
			content["skills"].size(),
			content["items"].size(),
			content["equipment"].size(),
		])
	quit(1 if _failed else 0)


func _verify_required_collections(content: Dictionary) -> void:
	for key in ["heroes", "enemies", "skills", "items", "equipment"]:
		_assert(content.has(key), "example content should include %s" % key)
		_assert(content.get(key, []) is Array, "example content %s should be an array" % key)
		_assert((content.get(key, []) as Array).size() > 0, "example content %s should not be empty" % key)


func _verify_unique_ids(content: Dictionary) -> void:
	var seen := {}
	for key in ["heroes", "enemies", "skills", "items", "equipment"]:
		for row in content[key]:
			_assert(row is Dictionary, "%s row should be a dictionary" % key)
			_assert(str(row.get("id", "")) != "", "%s row should have an id" % key)
			var id := str(row["id"])
			_assert(not seen.has(id), "example content id should be unique: %s" % id)
			seen[id] = true
			_assert(id.begins_with(_expected_prefix(key)), "%s id should use expected prefix: %s" % [key, id])


func _verify_stats_and_rewards(content: Dictionary) -> void:
	for hero in content["heroes"]:
		_verify_stat_row(hero, "hero")
	for enemy in content["enemies"]:
		_verify_stat_row(enemy, "enemy")
		_assert(int(enemy.get("reward_xp", -1)) >= 0, "enemy reward_xp should be non-negative")
		_assert(int(enemy.get("reward_gold", -1)) >= 0, "enemy reward_gold should be non-negative")
	for skill in content["skills"]:
		_assert(int(skill.get("mp_cost", -1)) >= 0, "skill mp_cost should be non-negative")
		_assert(skill.has("power") or skill.has("heal"), "skill should expose power or heal")
		_assert(int(skill.get("power", skill.get("heal", -1))) >= 0, "skill effect value should be non-negative")
	for item in content["items"]:
		_assert(int(item.get("quantity", 0)) > 0, "item quantity should be positive")
	for equipment in content["equipment"]:
		_assert(str(equipment.get("slot", "")) != "", "equipment slot should be present")
		_assert(equipment.has("attack") or equipment.has("defense"), "equipment should expose attack or defense")
		_assert(int(equipment.get("attack", equipment.get("defense", -1))) >= 0, "equipment effect value should be non-negative")


func _verify_stat_row(row: Dictionary, label: String) -> void:
	_assert(row.get("stats", {}) is Dictionary, "%s stats should be a dictionary" % label)
	var stats: Dictionary = row["stats"]
	for stat_id in ["max_hp", "max_mp", "speed", "attack", "defense"]:
		_assert(stats.has(stat_id), "%s stats should include %s" % [label, stat_id])
	_assert(int(stats["max_hp"]) > 0, "%s max_hp should be positive" % label)
	_assert(int(stats["max_mp"]) >= 0, "%s max_mp should be non-negative" % label)
	_assert(int(stats["attack"]) >= 0, "%s attack should be non-negative" % label)
	_assert(int(stats["defense"]) >= 0, "%s defense should be non-negative" % label)


func _expected_prefix(key: String) -> String:
	match key:
		"heroes":
			return "hero/"
		"enemies":
			return "enemy/"
		"skills":
			return "skill/"
		"items", "equipment":
			return "item/"
		_:
			return ""


func _assert(condition: bool, message: String) -> void:
	if condition:
		return
	push_error(message)
	_failed = true
