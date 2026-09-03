extends Node2D



@export_group("Dialogic")
@export var awakening_timeline: DialogicTimeline

@onready var clues: Node2D = $Clues



func _ready() -> void:
	_play_awakening()

func _play_awakening() -> void:
	if awakening_timeline != null and is_instance_valid(Dialogic):
		SignalHub.emit_on_player_control_blocked(true)
		Dialogic.start(awakening_timeline)
		await Dialogic.timeline_ended
		SignalHub.emit_on_player_control_blocked(false)
