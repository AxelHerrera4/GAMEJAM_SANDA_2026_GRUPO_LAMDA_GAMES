extends Node2D

@export_group("Dialogic")
@export var intro_timeline: DialogicTimeline

var _points: Array[HackPoint] = []
var _done: int = 0


func _ready() -> void:
	for node in find_children("*", "HackPoint", true, false):
		var point: HackPoint = node
		_points.append(point)
		point.hacked.connect(_on_point_hacked)

	_emit_progress()
	_play_intro()


func _play_intro() -> void:
	if intro_timeline != null and is_instance_valid(Dialogic):
		SignalHub.emit_on_player_control_blocked(true)
		Dialogic.start(intro_timeline)
		await Dialogic.timeline_ended
		SignalHub.emit_on_player_control_blocked(false)


func _on_point_hacked(_point: HackPoint) -> void:
	_done += 1
	_emit_progress()


func _emit_progress() -> void:
	SignalHub.emit_on_access_points_changed(_done, _points.size())
