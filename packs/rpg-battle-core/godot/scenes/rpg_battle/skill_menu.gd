extends VBoxContainer
class_name RPGSkillMenu

signal skill_selected(skill: Dictionary)

var skills: Array[Dictionary] = []
var actor: Resource


func _ready() -> void:
	_ensure_container()


func configure(next_skills: Array, next_actor: Resource) -> void:
	_ready()
	skills.clear()
	for skill in next_skills:
		if typeof(skill) == TYPE_DICTIONARY:
			skills.append((skill as Dictionary).duplicate(true))
	actor = next_actor
	_render()


func select_skill(index: int) -> Dictionary:
	if index < 0 or index >= skills.size():
		return {}
	var skill := skills[index].duplicate(true)
	skill_selected.emit(skill)
	return skill


func _render() -> void:
	var container := get_node("Skills")
	for child in container.get_children():
		child.queue_free()
	for skill in skills:
		var button := Button.new()
		button.name = _safe_node_name(str(skill.get("id", "skill")))
		button.text = "%s MP %s" % [str(skill.get("name", skill.get("id", "Skill"))), int(skill.get("mp_cost", 0))]
		button.disabled = actor != null and int(skill.get("mp_cost", 0)) > actor.current_mp
		container.add_child(button)


func _ensure_container() -> void:
	if has_node("Skills"):
		return
	var container := VBoxContainer.new()
	container.name = "Skills"
	add_child(container)


func _safe_node_name(value: String) -> String:
	return value.replace("/", "_").replace(":", "_")
