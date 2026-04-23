# feedback_clipboard.gd
# Editor-session clipboard for feedback copy/paste across different
# FeedbackPlayerLite nodes.

@tool
class_name FeedbackClipboardLite
extends RefCounted

## Static, editor-session-wide clipboard for feedback copy/paste.

static var _entry: FeedbackBaseLite = null


## Copies [param feedback] into the clipboard (stored as a deep duplicate).
static func copy(feedback: FeedbackBaseLite) -> void:
	if feedback == null:
		return
	_entry = feedback.duplicate(true) as FeedbackBaseLite


## Returns a fresh deep clone of the clipboard entry, or null.
static func paste() -> FeedbackBaseLite:
	if _entry == null:
		return null
	return _entry.duplicate(true) as FeedbackBaseLite


## Returns true if there is a feedback on the clipboard.
static func has_content() -> bool:
	return _entry != null


## Returns the display label of the clipboard entry.
static func peek_label() -> String:
	if _entry == null:
		return ""
	return _entry.get_display_label()


## Clears the clipboard.
static func clear() -> void:
	_entry = null
