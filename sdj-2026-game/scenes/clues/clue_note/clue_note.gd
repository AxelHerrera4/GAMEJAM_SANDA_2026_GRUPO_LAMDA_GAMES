class_name ClueNote
extends Clue

@export_group("Dialogic")
@export var timeline_path: DialogicTimeline

@export var reward_fragment: StringName = &"hack"

@export_group("Alternate Dialogues")
@export var timeline_already_collected: DialogicTimeline
@export var timeline_attack: DialogicTimeline
@export var timeline_camouflage: DialogicTimeline


func show_clue(first_time: bool) -> void:
	if not is_instance_valid(Dialogic):
		return

	if not reward_fragment.is_empty() and FragmentManager.has_fragment(reward_fragment):
		var alt_timeline: DialogicTimeline = timeline_already_collected
		if FragmentManager.has_fragment(FragmentManager.CAMOUFLAGE) and timeline_camouflage != null:
			alt_timeline = timeline_camouflage
		elif FragmentManager.has_fragment(FragmentManager.ATTACK) and timeline_attack != null:
			alt_timeline = timeline_attack

		if alt_timeline != null:
			await _play_timeline(alt_timeline)
		return

	if first_time and timeline_path != null:
		await _play_timeline(timeline_path)
		if not reward_fragment.is_empty():
			FragmentManager.grant(reward_fragment)


func _play_timeline(timeline: DialogicTimeline) -> void:
	SignalHub.emit_on_player_control_blocked(true)
	Dialogic.start(timeline)
	await Dialogic.timeline_ended
	SignalHub.emit_on_player_control_blocked(false)
	
