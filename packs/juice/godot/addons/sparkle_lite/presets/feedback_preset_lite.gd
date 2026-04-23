# feedback_preset.gd
# Pure data container. Saves and loads a complete FeedbackPlayerLite
# configuration as a Resource.

@tool
@icon("res://addons/sparkle_lite/icon.svg")
class_name FeedbackPresetLite
extends Resource

## A saved [FeedbackPlayerLite] configuration. Write the array you want
## on a player, save the [FeedbackPresetLite] as a [code].tres[/code]
## file, then load and apply it at runtime via
## [method FeedbackPresetsAutoloadLite.play].

## The feedbacks saved in this preset.
@export var feedbacks: Array[FeedbackBaseLite] = []
