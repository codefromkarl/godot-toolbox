extends VBoxContainer
class_name RPGItemMenu

const ItemActionScript := preload("res://addons/godot_toolbox_architecture/rpg_battle_core/actions/item_action.gd")

signal item_used(item: Dictionary)

var items: Array[Dictionary] = []
var target: Resource


func _ready() -> void:
	_ensure_container()


func configure(next_items: Array, next_target: Resource) -> void:
	_ready()
	items.clear()
	for item in next_items:
		if typeof(item) == TYPE_DICTIONARY:
			items.append((item as Dictionary).duplicate(true))
	target = next_target
	_render()


func use_item(index: int) -> Resource:
	if index < 0 or index >= items.size():
		return null
	var item := items[index]
	if int(item.get("quantity", 0)) <= 0:
		return null
	item["quantity"] = int(item["quantity"]) - 1
	var action: Resource = ItemActionScript.new()
	action.action_id = StringName(str(item.get("id", "")))
	action.heal_amount = int(item.get("heal", 0))
	if target != null:
		action.apply(target, [target])
	item_used.emit(item.duplicate(true))
	_render()
	return action


func _render() -> void:
	var container := get_node("Items")
	for child in container.get_children():
		child.queue_free()
	for item in items:
		var button := Button.new()
		button.name = _safe_node_name(str(item.get("id", "item")))
		button.text = "%s x%s" % [str(item.get("name", item.get("id", "Item"))), int(item.get("quantity", 0))]
		button.disabled = int(item.get("quantity", 0)) <= 0
		container.add_child(button)


func _ensure_container() -> void:
	if has_node("Items"):
		return
	var container := VBoxContainer.new()
	container.name = "Items"
	add_child(container)


func _safe_node_name(value: String) -> String:
	return value.replace("/", "_").replace(":", "_")
