# feedback_list_editor_lite.gd
# Custom EditorProperty for FeedbackPlayerLite.feedbacks. Prominent
# promo banner (Upgrade to Sparkle) + toolbar (add/paste/preview/total)
# + one FeedbackEntryEditor row per feedback. All mutations route
# through EditorUndoRedoManager.

@tool
extends EditorProperty

const _ENTRY_EDITOR_SCRIPT: Script = preload(
		"res://addons/sparkle_lite/editor/feedback_entry_editor_lite.gd"
)
const _PREVIEW_CONTROLLER_SCRIPT: Script = preload(
		"res://addons/sparkle_lite/editor/feedback_preview_controller_lite.gd"
)

const _UPGRADE_URL: String = "https://neohex-interactive.itch.io/sparkle"

var _player: FeedbackPlayerLite = null
var _undo_redo: EditorUndoRedoManager = null
var _preview: RefCounted = null

var _root: VBoxContainer = null
var _promo_banner: PanelContainer = null
var _toolbar: HBoxContainer = null
var _entries_container: VBoxContainer = null
var _preview_button: Button = null
var _paste_button: Button = null
var _duration_label: Label = null
var _empty_label: Label = null
var _diagnostic_banner: PanelContainer = null
var _diagnostic_body: VBoxContainer = null


func configure(
		player: FeedbackPlayerLite,
		ur: EditorUndoRedoManager
) -> void:
	_player = player
	_undo_redo = ur
	_preview = _PREVIEW_CONTROLLER_SCRIPT.new()
	_preview.state_changed.connect(_on_preview_state_changed)
	_preview.preview_diagnostics.connect(_on_preview_diagnostics)
	_build_ui()
	_refresh()


func _exit_tree() -> void:
	if _preview != null and _preview.is_running():
		_preview.stop()


func _update_property() -> void:
	_refresh()


func _build_ui() -> void:
	_root = VBoxContainer.new()
	_root.add_theme_constant_override("separation", 6)
	_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_root)
	set_bottom_editor(_root)

	_promo_banner = _build_promo_banner()
	_root.add_child(_promo_banner)

	_toolbar = HBoxContainer.new()
	_toolbar.add_theme_constant_override("separation", 6)
	_toolbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root.add_child(_toolbar)

	var add_btn: MenuButton = MenuButton.new()
	add_btn.text = "+ Add Feedback"
	add_btn.tooltip_text = "Append a new feedback entry"
	var popup: PopupMenu = add_btn.get_popup()
	_populate_add_menu(popup)
	_toolbar.add_child(add_btn)

	_paste_button = Button.new()
	_paste_button.text = "Paste"
	_paste_button.pressed.connect(_on_paste_pressed)
	_apply_compact_toolbar_button(_paste_button)
	_toolbar.add_child(_paste_button)
	_refresh_paste_button()

	_preview_button = Button.new()
	_preview_button.text = "Preview"
	_preview_button.tooltip_text = (
			"Fire the full sequence in the editor without entering "
			+ "play mode"
	)
	_preview_button.pressed.connect(_on_preview_pressed)
	_apply_compact_toolbar_button(_preview_button)
	_toolbar.add_child(_preview_button)

	_toolbar.add_child(_make_spacer())

	_duration_label = Label.new()
	_duration_label.modulate = Color(1, 1, 1, 0.7)
	_toolbar.add_child(_duration_label)

	_diagnostic_banner = _build_diagnostic_banner()
	_root.add_child(_diagnostic_banner)

	_entries_container = VBoxContainer.new()
	_entries_container.add_theme_constant_override("separation", 3)
	_entries_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_entries_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root.add_child(_entries_container)

	_empty_label = Label.new()
	_empty_label.text = (
			"No feedbacks yet — click \"+ Add Feedback\" to begin."
	)
	_empty_label.modulate = Color(1, 1, 1, 0.5)
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_empty_label)


# ---------------------------------------------------------------------------
# Promo banner — always visible on every FeedbackPlayerLite inspector.
# Colourful gradient fill, accented border, sparkle glyph, a short pitch,
# and an "Unlock the full Sparkle →" button that opens the itch.io page.
# This is the primary monetisation surface for the Lite release, so make
# it unmistakably visible but still in keeping with the inspector style.
# ---------------------------------------------------------------------------
func _build_promo_banner() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.23, 0.14, 0.36, 1.0)
	style.border_color = Color(1.0, 0.78, 0.25, 1.0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(1.0, 0.78, 0.25, 0.35)
	style.shadow_size = 2
	panel.add_theme_stylebox_override(&"panel", style)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 12)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(row)

	var sparkle: Label = Label.new()
	sparkle.text = "★"
	sparkle.add_theme_font_size_override(&"font_size", 24)
	sparkle.add_theme_color_override(
			&"font_color", Color(1.0, 0.86, 0.35, 1.0)
	)
	sparkle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(sparkle)

	var text_col: VBoxContainer = VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override(&"separation", 2)
	row.add_child(text_col)

	var title: RichTextLabel = RichTextLabel.new()
	title.bbcode_enabled = true
	title.fit_content = true
	title.scroll_active = false
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.text = "[b][color=#ffd86b]You're using Sparkle Lite[/color][/b]"
	text_col.add_child(title)

	var body: RichTextLabel = RichTextLabel.new()
	body.bbcode_enabled = true
	body.fit_content = true
	body.scroll_active = false
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.text = (
			"[color=#e8ddff]Please consider buying the original "
			+ "version for more feedbacks.[/color]"
	)
	text_col.add_child(body)

	var link: LinkButton = LinkButton.new()
	link.text = _UPGRADE_URL
	link.underline = LinkButton.UNDERLINE_MODE_ALWAYS
	link.uri = _UPGRADE_URL
	link.add_theme_color_override(
			&"font_color", Color(0.95, 0.82, 0.35, 1.0)
	)
	link.add_theme_color_override(
			&"font_hover_color", Color(1.0, 0.95, 0.55, 1.0)
	)
	text_col.add_child(link)

	var button_col: VBoxContainer = VBoxContainer.new()
	button_col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(button_col)

	var upgrade_btn: Button = Button.new()
	upgrade_btn.text = "  Unlock Full Sparkle  →  "
	upgrade_btn.tooltip_text = (
			"Opens https://neohex-interactive.itch.io/sparkle in your "
			+ "browser"
	)
	upgrade_btn.add_theme_color_override(
			&"font_color", Color(0.12, 0.08, 0.22, 1.0)
	)
	upgrade_btn.add_theme_color_override(
			&"font_hover_color", Color(0.05, 0.03, 0.12, 1.0)
	)
	_style_upgrade_button(upgrade_btn)
	upgrade_btn.pressed.connect(_on_upgrade_pressed)
	button_col.add_child(upgrade_btn)

	return panel


func _style_upgrade_button(button: Button) -> void:
	# Golden fill so the button pops against the purple banner. Keep the
	# border subtle so it reads as a single golden pill rather than a
	# framed rectangle.
	var base: StyleBoxFlat = StyleBoxFlat.new()
	base.bg_color = Color(1.0, 0.82, 0.30, 1.0)
	base.border_color = Color(1.0, 0.65, 0.15, 1.0)
	base.set_border_width_all(1)
	base.set_corner_radius_all(5)
	base.content_margin_left = 12
	base.content_margin_right = 12
	base.content_margin_top = 6
	base.content_margin_bottom = 6
	button.add_theme_stylebox_override(&"normal", base)

	var hover: StyleBoxFlat = base.duplicate()
	hover.bg_color = Color(1.0, 0.90, 0.45, 1.0)
	button.add_theme_stylebox_override(&"hover", hover)

	var pressed: StyleBoxFlat = base.duplicate()
	pressed.bg_color = Color(0.95, 0.72, 0.22, 1.0)
	button.add_theme_stylebox_override(&"pressed", pressed)

	var focus: StyleBoxFlat = base.duplicate()
	focus.border_color = Color(1.0, 1.0, 0.7, 1.0)
	focus.set_border_width_all(2)
	button.add_theme_stylebox_override(&"focus", focus)


func _on_upgrade_pressed() -> void:
	OS.shell_open(_UPGRADE_URL)


func _make_spacer() -> Control:
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spacer


func _apply_compact_toolbar_button(button: Button) -> void:
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for state_name in [
			&"normal", &"hover", &"pressed",
			&"disabled", &"focus", &"hover_pressed"
	]:
		if not button.has_theme_stylebox(state_name):
			continue
		var base: StyleBox = button.get_theme_stylebox(state_name)
		if base == null:
			continue
		var compact: StyleBox = base.duplicate()
		compact.content_margin_top = 2.0
		compact.content_margin_bottom = 2.0
		button.add_theme_stylebox_override(state_name, compact)


func _refresh() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _entries_container == null:
		return
	for child in _entries_container.get_children():
		child.queue_free()
	var feedbacks: Array = _player.feedbacks
	for i in range(feedbacks.size()):
		var entry: Control = _ENTRY_EDITOR_SCRIPT.new()
		entry.configure(feedbacks[i], i, _undo_redo, self)
		_entries_container.add_child(entry)
	_update_empty_state()
	_update_duration_label()


func _update_empty_state() -> void:
	if _empty_label == null:
		return
	var size: int = 0
	if _player != null and is_instance_valid(_player):
		size = _player.feedbacks.size()
	_empty_label.visible = size == 0


func _update_duration_label() -> void:
	if _duration_label == null or _player == null:
		return
	var total_ms: float = _player.get_total_duration() * 1000.0
	_duration_label.text = "Total: %d ms" % int(round(total_ms))


func _populate_add_menu(popup: PopupMenu) -> void:
	# Flat list — only 6 feedback types, no need for category submenus.
	var entries: Array = FeedbackTypeRegistryLite.get_entries()
	for i in range(entries.size()):
		popup.add_item(entries[i]["label"], i)
	popup.id_pressed.connect(_on_add_pressed)


func _on_add_pressed(id: int) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var fb: FeedbackBaseLite = FeedbackTypeRegistryLite.instantiate_at(id)
	if fb == null:
		return
	var label: String = FeedbackTypeRegistryLite.get_display_label(fb)
	var old_arr: Array = _player.feedbacks.duplicate()
	var new_arr: Array = old_arr.duplicate()
	new_arr.append(fb)
	_apply_array_action("Add Feedback (%s)" % label, old_arr, new_arr)


func _on_preview_pressed() -> void:
	if _preview == null or _player == null:
		return
	if _preview.is_running():
		_preview.stop()
	else:
		_preview.start(_player)


func _on_preview_state_changed(is_running: bool) -> void:
	if _preview_button == null:
		return
	_preview_button.text = "Stop Preview" if is_running else "Preview"


func _build_diagnostic_banner() -> PanelContainer:
	var panel: PanelContainer = PanelContainer.new()
	panel.visible = false
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.22, 0.32, 0.85)
	style.border_color = Color(0.36, 0.55, 0.78, 1.0)
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override(&"panel", style)

	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(row)

	_diagnostic_body = VBoxContainer.new()
	_diagnostic_body.add_theme_constant_override(&"separation", 2)
	_diagnostic_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_diagnostic_body)

	var dismiss: Button = Button.new()
	dismiss.flat = true
	dismiss.text = "x"
	dismiss.tooltip_text = "Hide this notice"
	dismiss.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	dismiss.pressed.connect(_hide_diagnostic_banner)
	row.add_child(dismiss)

	return panel


func _hide_diagnostic_banner() -> void:
	if _diagnostic_banner != null:
		_diagnostic_banner.visible = false


func _on_preview_diagnostics(entries: Array) -> void:
	if _diagnostic_banner == null or _diagnostic_body == null:
		return
	for child in _diagnostic_body.get_children():
		child.queue_free()
	if entries.is_empty():
		_diagnostic_banner.visible = false
		return
	var header: Label = Label.new()
	var skipped_count: int = entries.size()
	header.text = (
			"Preview skipped %d feedback%s — current scene state can't "
			+ "satisfy them:"
	) % [
			skipped_count,
			"" if skipped_count == 1 else "s",
	]
	header.modulate = Color(1, 1, 1, 0.95)
	header.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_diagnostic_body.add_child(header)
	for entry in entries:
		var row: Label = Label.new()
		row.text = "  • %s — %s" % [
				entry.get("label", "(unnamed)"),
				entry.get("reason", ""),
		]
		row.modulate = Color(1, 1, 1, 0.8)
		row.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_diagnostic_body.add_child(row)
		print_rich(
				"[color=#7fb6ff]Sparkle Lite preview:[/color] skipped %s — %s"
				% [entry.get("label", ""), entry.get("reason", "")]
		)
	_diagnostic_banner.visible = true


func _refresh_paste_button() -> void:
	if _paste_button == null:
		return
	var has: bool = FeedbackClipboardLite.has_content()
	_paste_button.disabled = not has
	if has:
		_paste_button.tooltip_text = (
				"Paste '%s' as a new feedback on this player"
				% FeedbackClipboardLite.peek_label()
		)
	else:
		_paste_button.tooltip_text = (
				"Clipboard is empty — copy a feedback via its ⋮ menu"
		)


func _on_paste_pressed() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var fb: FeedbackBaseLite = FeedbackClipboardLite.paste()
	if fb == null:
		return
	var old_arr: Array = _player.feedbacks.duplicate()
	var new_arr: Array = old_arr.duplicate()
	new_arr.append(fb)
	_apply_array_action(
			"Paste Feedback (%s)" % fb.get_display_label(),
			old_arr, new_arr
	)


# --- Called by FeedbackEntryEditor children ----------------------------

func notify_clipboard_changed() -> void:
	_refresh_paste_button()


func request_duplicate(index: int) -> void:
	if _player == null or index < 0 or index >= _player.feedbacks.size():
		return
	var source: FeedbackBaseLite = _player.feedbacks[index]
	if source == null:
		return
	var clone: FeedbackBaseLite = source.duplicate(true) as FeedbackBaseLite
	var old_arr: Array = _player.feedbacks.duplicate()
	var new_arr: Array = old_arr.duplicate()
	new_arr.insert(index + 1, clone)
	_apply_array_action(
			"Duplicate Feedback (%s)" % source.get_display_label(),
			old_arr, new_arr
	)


func request_delete(index: int) -> void:
	if _player == null or index < 0 or index >= _player.feedbacks.size():
		return
	var old_arr: Array = _player.feedbacks.duplicate()
	var new_arr: Array = old_arr.duplicate()
	var removed: FeedbackBaseLite = new_arr[index]
	new_arr.remove_at(index)
	var name: String = "Remove Feedback"
	if removed != null:
		name = "Remove Feedback (%s)" % removed.get_display_label()
	_apply_array_action(name, old_arr, new_arr)


func request_move(from_index: int, to_index: int) -> void:
	if _player == null:
		return
	if from_index == to_index:
		return
	var old_arr: Array = _player.feedbacks.duplicate()
	if from_index < 0 or from_index >= old_arr.size():
		return
	if to_index < 0 or to_index > old_arr.size():
		return
	var new_arr: Array = old_arr.duplicate()
	var moved: FeedbackBaseLite = new_arr[from_index]
	new_arr.remove_at(from_index)
	if to_index > from_index:
		to_index -= 1
	new_arr.insert(to_index, moved)
	_apply_array_action("Reorder Feedback", old_arr, new_arr)


func notify_feedback_changed() -> void:
	_update_duration_label()


func _apply_array_action(
		action_name: String, old_arr: Array, new_arr: Array
) -> void:
	if _undo_redo == null:
		_player.feedbacks = new_arr
		_refresh()
		emit_changed(get_edited_property(), _player.feedbacks)
		return
	_undo_redo.create_action(
			"Sparkle Lite: %s" % action_name,
			UndoRedo.MERGE_DISABLE,
			_player
	)
	_undo_redo.add_do_method(self, "_apply_array", _player, new_arr)
	_undo_redo.add_undo_method(self, "_apply_array", _player, old_arr)
	_undo_redo.commit_action()


func _apply_array(player: FeedbackPlayerLite, arr: Array) -> void:
	if player == null or not is_instance_valid(player):
		return
	player.feedbacks = arr.duplicate()
	_refresh()
	emit_changed(get_edited_property(), player.feedbacks)
