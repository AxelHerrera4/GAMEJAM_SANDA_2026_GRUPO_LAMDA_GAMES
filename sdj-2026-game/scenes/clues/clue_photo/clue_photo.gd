class_name CluePhoto
extends Clue

@export var photo: Texture2D
@export_multiline var caption: String = ""

@export_group("Dialogic")
@export var first_time_timeline: DialogicTimeline


func show_clue(first_time: bool) -> void:
	SignalHub.emit_on_photo_requested(clue_title, photo, caption)

	if not first_time or first_time_timeline == null:
		return

	await SignalHub.ui_closed

	if first_time_timeline != null and is_instance_valid(Dialogic):
		SignalHub.emit_on_player_control_blocked(true)
		Dialogic.start(first_time_timeline)
		await Dialogic.timeline_ended
		SignalHub.emit_on_player_control_blocked(false)
		return
