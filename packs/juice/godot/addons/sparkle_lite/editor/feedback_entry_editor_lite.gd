# feedback_entry_editor.gd
# Single row in a feedback list. Header: drag handle + type icon +
# label + enabled toggle + expand arrow + ⋮ actions menu. Expanded
# body shows an EditorInspector for the feedback's exported
# properties. No container / nesting logic in Lite — the feedback
# list is a flat array.

@tool
extends PanelContainer

var _feedback: FeedbackBaseLite = null
var _index: int = -1
var _undo_redo: EditorUndoRedoManager = null
var _list_editor: Object = null

var _stylebox: StyleBoxFlat = null
var _label_edit: LineEdit = null
var _enabled_check: CheckBox = null
var _icon_rect: TextureRect = null
var _expand_button: Button = null
var _body_container: VBoxContainer = null
var _inspector: EditorInspector = null
var _expanded: bool = false
var _header_label: Label = null

# Drop indicator state. Rows paint a thin line along the top
# (_DROP_ABOVE) or bottom (_DROP_BELOW) edge while a valid drag is
# hovering.
const _DROP_NONE: int = 0
const _DROP_ABOVE: int = 1
const _DROP_BELOW: int = 2
const _DROP_COLOR: Color = Color(0.35, 0.95, 0.4, 1.0)
const _DROP_THICKNESS: float = 3.0
var _drop_mode: int = _DROP_NONE


func configure(
		feedback: FeedbackBaseLite,
		index: int,
		ur: EditorUndoRedoManager,
		list_editor: Object
) -> void:
	_feedback = feedback
	_index = index
	_undo_redo = ur
	_list_editor = list_editor
	_build_ui()
	_sync_from_feedback()


func _build_ui() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_stylebox = StyleBoxFlat.new()
	_stylebox.bg_color = Color(0.18, 0.18, 0.18, 1.0)
	_stylebox.border_width_left = 4
	_stylebox.set_corner_radius_all(3)
	_stylebox.content_margin_left = 8
	_stylebox.content_margin_right = 6
	_stylebox.content_margin_top = 4
	_stylebox.content_margin_bottom = 4
	add_theme_stylebox_override("panel", _stylebox)
	_apply_color()

	var root: VBoxContainer = VBoxContainer.new()
	root.add_theme_constant_override("separation", 4)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(root)

	var header: HBoxContainer = HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(header)

	var drag_handle: Label = Label.new()
	drag_handle.text = "::"
	drag_handle.modulate = Color(1, 1, 1, 0.5)
	drag_handle.tooltip_text = "Drag to reorder"
	drag_handle.mouse_default_cursor_shape = Control.CURSOR_DRAG
	header.add_child(drag_handle)

	_icon_rect = TextureRect.new()
	_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon_rect.custom_minimum_size = Vector2(16, 16)
	header.add_child(_icon_rect)

	_header_label = Label.new()
	_header_label.modulate = Color(1, 1, 1, 0.65)
	header.add_child(_header_label)

	_label_edit = LineEdit.new()
	_label_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label_edit.placeholder_text = "(default)"
	_label_edit.text_submitted.connect(_on_label_submitted)
	_label_edit.focus_exited.connect(_on_label_focus_exited)
	header.add_child(_label_edit)

	_enabled_check = CheckBox.new()
	_enabled_check.text = "Enabled"
	_enabled_check.toggled.connect(_on_enabled_toggled)
	header.add_child(_enabled_check)

	_expand_button = Button.new()
	_expand_button.flat = true
	_expand_button.custom_minimum_size = Vector2(24, 0)
	_expand_button.tooltip_text = "Expand / collapse"
	_expand_button.pressed.connect(_on_expand_pressed)
	_update_expand_icon()
	header.add_child(_expand_button)

	var actions: MenuButton = MenuButton.new()
	actions.text = "⋮"
	actions.flat = true
	actions.custom_minimum_size = Vector2(24, 0)
	actions.tooltip_text = "Duplicate / Copy / Delete"
	var popup: PopupMenu = actions.get_popup()
	popup.add_item("Duplicate", 0)
	popup.add_item("Copy", 1)
	popup.add_separator()
	popup.add_item("Delete…", 2)
	popup.id_pressed.connect(_on_action_selected)
	header.add_child(actions)

	_body_container = VBoxContainer.new()
	_body_container.add_theme_constant_override("separation", 4)
	_body_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body_container.visible = false
	root.add_child(_body_container)

	_inspector = EditorInspector.new()
	_inspector.custom_minimum_size = Vector2(0, 275)
	_inspector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inspector.property_edited.connect(_on_property_edited)
	_body_container.add_child(_inspector)

	mouse_exited.connect(_on_mouse_exited_for_drop)


func _apply_color() -> void:
	if _stylebox == null:
		return
	var color: Color = Color(0.5, 0.5, 0.5)
	if _feedback != null:
		color = FeedbackTypeRegistryLite.get_color(_feedback)
	_stylebox.border_color = color


func _sync_from_feedback() -> void:
	if _feedback == null:
		return
	_icon_rect.texture = FeedbackTypeRegistryLite.get_icon(_feedback)
	_header_label.text = FeedbackTypeRegistryLite.get_display_label(_feedback)
	# MOUSE_FILTER_PASS: receive mouse events for the tooltip but still
	# forward clicks to the outer PanelContainer so drag-to-reorder can
	# start from anywhere in the header.
	var description: String = FeedbackTypeRegistryLite.get_description(_feedback)
	_header_label.tooltip_text = description
	_header_label.mouse_filter = Control.MOUSE_FILTER_PASS
	if _icon_rect != null:
		_icon_rect.tooltip_text = description
		_icon_rect.mouse_filter = Control.MOUSE_FILTER_PASS
	_label_edit.text = _feedback.label
	_enabled_check.set_pressed_no_signal(_feedback.enabled)
	_apply_color()
	if _inspector != null and _expanded:
		_inspector.edit(_feedback)


func _on_expand_pressed() -> void:
	_expanded = not _expanded
	_body_container.visible = _expanded
	_update_expand_icon()
	if _expanded and _inspector != null:
		_inspector.edit(_feedback)


## Applies the expand/collapse triangle icon from the editor theme.
## Collapsed → right-pointing triangle ([code]GuiTreeArrowRight[/code]).
## Expanded → down-pointing triangle ([code]GuiTreeArrowDown[/code]).
## Falls back to plain text (v / ^) when the editor theme is not
## available — happens during initial inspector construction before
## the row is inside the tree.
func _update_expand_icon() -> void:
	if _expand_button == null:
		return
	var icon_name: StringName = \
			&"GuiTreeArrowDown" if _expanded else &"GuiTreeArrowRight"
	if has_theme_icon(icon_name, &"EditorIcons"):
		_expand_button.icon = get_theme_icon(icon_name, &"EditorIcons")
		_expand_button.text = ""
	else:
		_expand_button.icon = null
		_expand_button.text = "^" if _expanded else "v"


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_ENTER_TREE, NOTIFICATION_THEME_CHANGED:
			_update_expand_icon()
		NOTIFICATION_DRAG_END:
			_clear_drop_indicator()


func _on_mouse_exited_for_drop() -> void:
	_clear_drop_indicator()


func _clear_drop_indicator() -> void:
	if _drop_mode == _DROP_NONE:
		return
	_drop_mode = _DROP_NONE
	queue_redraw()


func _draw() -> void:
	if _drop_mode == _DROP_ABOVE:
		draw_rect(
				Rect2(Vector2(0, 0), Vector2(size.x, _DROP_THICKNESS)),
				_DROP_COLOR
		)
	elif _drop_mode == _DROP_BELOW:
		draw_rect(
				Rect2(
						Vector2(0, size.y - _DROP_THICKNESS),
						Vector2(size.x, _DROP_THICKNESS)
				),
				_DROP_COLOR
		)


func _on_label_submitted(new_text: String) -> void:
	_commit_label(new_text)


func _on_label_focus_exited() -> void:
	if _label_edit == null:
		return
	_commit_label(_label_edit.text)


func _commit_label(new_text: String) -> void:
	if _feedback == null or _feedback.label == new_text:
		return
	var old_text: String = _feedback.label
	_commit_property("label", old_text, new_text)
	_header_label.text = _feedback.get_display_label() \
			if new_text.is_empty() else new_text


func _on_enabled_toggled(pressed: bool) -> void:
	if _feedback == null or _feedback.enabled == pressed:
		return
	var old_val: bool = _feedback.enabled
	_commit_property("enabled", old_val, pressed)


func _commit_property(
		property: StringName, old_value: Variant, new_value: Variant
) -> void:
	if _undo_redo == null:
		_feedback.set(property, new_value)
		_notify_changed()
		return
	_undo_redo.create_action(
			"Sparkle Lite: Edit %s" % property,
			UndoRedo.MERGE_ENDS,
			_feedback
	)
	_undo_redo.add_do_property(_feedback, property, new_value)
	_undo_redo.add_undo_property(_feedback, property, old_value)
	_undo_redo.commit_action()
	_notify_changed()


func _on_property_edited(property: String) -> void:
	_notify_changed()
	if property == "label":
		_header_label.text = _feedback.get_display_label()
		_label_edit.text = _feedback.label


func _on_action_selected(id: int) -> void:
	match id:
		0:
			if _list_editor != null:
				_list_editor.request_duplicate(_index)
		1:
			FeedbackClipboardLite.copy(_feedback)
			if _list_editor != null \
					and _list_editor.has_method("notify_clipboard_changed"):
				_list_editor.notify_clipboard_changed()
		2:
			_confirm_delete()


func _confirm_delete() -> void:
	if _feedback == null or _list_editor == null:
		return
	var dialog: ConfirmationDialog = ConfirmationDialog.new()
	dialog.title = "Delete Feedback"
	dialog.dialog_text = "Delete '%s'?\n(Ctrl+Z undoes this.)" \
			% _feedback.get_display_label()
	dialog.ok_button_text = "Delete"
	add_child(dialog)
	var do_delete := func ():
		if _list_editor != null:
			_list_editor.request_delete(_index)
		dialog.queue_free()
	dialog.confirmed.connect(do_delete)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered()


func _notify_changed() -> void:
	if _list_editor != null \
			and _list_editor.has_method("notify_feedback_changed"):
		_list_editor.notify_feedback_changed()


# --- Drag & drop --------------------------------------------------------

func _get_drag_data(_position: Vector2) -> Variant:
	if _feedback == null:
		return null
	var preview: Label = Label.new()
	preview.text = "  %s  " % _feedback.get_display_label()
	preview.add_theme_stylebox_override("normal", _stylebox.duplicate())
	set_drag_preview(preview)
	return {
		"sparkle_lite_feedback_index": _index,
		"sparkle_lite_source": _list_editor,
	}


func _can_drop_data(pos: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if not data.has("sparkle_lite_feedback_index"):
		return false
	# Only same-list reorders are supported in Lite (there's only one
	# list per player — no containers). Silently reject drops coming
	# from a different list editor.
	if data.get("sparkle_lite_source") != _list_editor:
		return false
	var desired: int = _DROP_NONE
	var self_hover: bool = (
			int(data.get("sparkle_lite_feedback_index", -1)) == _index
	)
	if not self_hover:
		desired = _DROP_ABOVE if pos.y < size.y * 0.5 else _DROP_BELOW
	if desired != _drop_mode:
		_drop_mode = desired
		queue_redraw()
	return true


func _drop_data(pos: Vector2, data: Variant) -> void:
	# Figure out the target slot BEFORE clearing state. Above-this-row
	# lands at `_index`; below-this-row lands at `_index + 1` — that's
	# the bisection the ghost indicator is already showing the user,
	# so the drop has to match or the visual is a lie.
	var drop_below: bool = pos.y >= size.y * 0.5
	var target_index: int = _index + (1 if drop_below else 0)
	_clear_drop_indicator()
	var source: Object = data.get("sparkle_lite_source", null)
	var from_index: int = data["sparkle_lite_feedback_index"]
	if source == _list_editor and source != null:
		_list_editor.request_move(from_index, target_index)
