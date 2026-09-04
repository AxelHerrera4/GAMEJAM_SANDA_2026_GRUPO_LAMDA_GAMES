class_name CluePhoto
extends Clue

@export var photo: Texture2D
@export_multiline var caption: String = ""

@export_group("Dialogic")
@export var first_time_timeline: DialogicTimeline

@export_group("Alternate Cycles")
@export var timeline_attack: DialogicTimeline
@export var photo_attack: Texture2D
@export var timeline_camouflage: DialogicTimeline
@export var photo_camouflage: Texture2D


func show_clue(first_time: bool) -> void:
	var active_photo: Texture2D = photo
	var active_timeline: DialogicTimeline = first_time_timeline

	if FragmentManager.has_fragment(FragmentManager.CAMOUFLAGE):
		if photo_camouflage != null:
			active_photo = photo_camouflage
		if timeline_camouflage != null:
			active_timeline = timeline_camouflage
	elif FragmentManager.has_fragment(FragmentManager.ATTACK):
		if photo_attack != null:
			active_photo = photo_attack
		if timeline_attack != null:
			active_timeline = timeline_attack

	SignalHub.emit_on_photo_requested(clue_title, active_photo, caption)

	if not first_time or active_timeline == null:
		return

	await SignalHub.ui_closed

	if active_timeline != null and is_instance_valid(Dialogic):
		SignalHub.emit_on_player_control_blocked(true)
		Dialogic.start(active_timeline)
		await Dialogic.timeline_ended
		SignalHub.emit_on_player_control_blocked(false)
		return
