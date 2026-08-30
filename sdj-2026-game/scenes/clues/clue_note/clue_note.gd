class_name ClueNote
extends Clue

@export_group("Dialogic")
@export_file("*.dtl") var timeline_path: String = ""



func show_clue(first_time: bool) -> void:
	if not timeline_path.is_empty() and is_instance_valid(Dialogic):
		await _show_with_dialogic()
		return

func _show_with_dialogic() -> void:
	SignalHub.emit_on_player_control_blocked(true)
	Dialogic.start(timeline_path)
	await Dialogic.timeline_ended
	SignalHub.emit_on_player_control_blocked(false)

