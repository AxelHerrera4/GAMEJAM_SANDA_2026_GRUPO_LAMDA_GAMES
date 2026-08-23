class_name CluePhoto
extends Clue

@export var photo: Texture2D
@export_multiline var caption: String = ""

@export_group("Primera vez")
@export var speaker: String = "Eddy"
@export_multiline var first_time_text: String = ""


func show_clue(first_time: bool) -> void:
	SignalHub.photo_requested.emit(clue_title, photo, caption)

	if not first_time or first_time_text.is_empty():
		return

	await SignalHub.ui_closed
	SignalHub.dialogue_requested.emit(speaker, first_time_text)
	await SignalHub.ui_closed
