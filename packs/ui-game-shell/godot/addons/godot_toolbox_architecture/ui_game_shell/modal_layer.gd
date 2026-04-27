extends Control
class_name ModalLayer

signal modal_opened(modal_id: StringName)
signal modal_closed(modal_id: StringName)

var _open_modals: Dictionary = {}


func open_modal(modal_id: StringName, modal: Control = null) -> Control:
	if modal == null:
		modal = PanelContainer.new()
	modal.name = String(modal_id)
	_open_modals[modal_id] = modal
	add_child(modal)
	modal_opened.emit(modal_id)
	return modal


func close_modal(modal_id: StringName) -> bool:
	if not _open_modals.has(modal_id):
		return false
	var modal: Node = _open_modals[modal_id]
	_open_modals.erase(modal_id)
	if is_instance_valid(modal):
		modal.queue_free()
	modal_closed.emit(modal_id)
	return true


func has_modal(modal_id: StringName) -> bool:
	return _open_modals.has(modal_id)
