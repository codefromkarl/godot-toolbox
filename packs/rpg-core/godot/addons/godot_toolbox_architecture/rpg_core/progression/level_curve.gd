extends Resource
class_name LevelCurve

@export var thresholds: Array[int] = [0]


func max_level() -> int:
	return max(1, thresholds.size())


func level_for_experience(experience: int) -> int:
	var xp := max(0, experience)
	var level := 1
	for index in range(thresholds.size()):
		if xp >= thresholds[index]:
			level = index + 1
	return level


func experience_for_level(level: int) -> int:
	var clamped_level := clampi(level, 1, max_level())
	return int(thresholds[clamped_level - 1])


func add_experience(current_experience: int, gained_experience: int) -> Dictionary:
	var old_xp := max(0, current_experience)
	var old_level := level_for_experience(old_xp)
	var new_xp := max(0, old_xp + max(0, gained_experience))
	var new_level := level_for_experience(new_xp)
	return {
		"experience": new_xp,
		"old_level": old_level,
		"level": new_level,
		"levels_gained": new_level - old_level,
		"max_level_reached": new_level == max_level(),
	}
