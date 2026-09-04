extends Node2D



@export_group("Dialogic")
@export var awakening_timeline: DialogicTimeline
@export var awakening_timeline_2: DialogicTimeline
@export var awakening_timeline_3: DialogicTimeline

@onready var clues: Node2D = $Clues



func _ready() -> void:
	_play_awakening()

func _play_awakening() -> void:
	var timeline: DialogicTimeline = awakening_timeline
	if FragmentManager.has_fragment(FragmentManager.CAMOUFLAGE) and awakening_timeline_3 != null:
		timeline = awakening_timeline_3
	elif FragmentManager.has_fragment(FragmentManager.ATTACK) and awakening_timeline_2 != null:
		timeline = awakening_timeline_2

	if timeline != null and is_instance_valid(Dialogic):
		SignalHub.emit_on_player_control_blocked(true)
		Dialogic.start(timeline)
		await Dialogic.timeline_ended
		SignalHub.emit_on_player_control_blocked(false)
