class_name ClueNote
extends Clue

@export_group("Dialogic")
@export var timeline_path: DialogicTimeline

@export var reward_fragment: StringName = &"hack"

func show_clue(first_time: bool) -> void:
	if first_time and timeline_path != null and is_instance_valid(Dialogic):
		await _show_with_dialogic()
		return

func _show_with_dialogic() -> void:
	SignalHub.emit_on_player_control_blocked(true)
	Dialogic.start(timeline_path)
	await Dialogic.timeline_ended
	FragmentManager.grant(reward_fragment)
	SignalHub.emit_on_player_control_blocked(false)
	
