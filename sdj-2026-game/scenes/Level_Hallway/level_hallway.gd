extends Node2D

var _points: Array[HackPoint] = []
var _done: int = 0


func _ready() -> void:
	for node in find_children("*", "HackPoint", true, false):
		var point: HackPoint = node
		_points.append(point)
		point.hacked.connect(_on_point_hacked)

	_emit_progress()


func _on_point_hacked(_point: HackPoint) -> void:
	_done += 1
	_emit_progress()


func _emit_progress() -> void:
	SignalHub.access_points_changed.emit(_done, _points.size())
