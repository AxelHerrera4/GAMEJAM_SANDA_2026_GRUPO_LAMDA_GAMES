class_name HackPoint
extends Area2D

signal hacked(point: HackPoint)

@export_group("Dialogic Timelines")
@export_file("*.dtl") var success_timeline: String = "res://dialogues/hack_points/point_secured.dtl"
@export_file("*.dtl") var already_done_timeline: String = "res://dialogues/hack_points/already_done.dtl"

@export_group("Colores")
@export var color_locked: Color = Color(0.694, 0.0, 0.043, 0.733)
@export var color_hacked: Color = Color(0.0, 0.41, 0.076, 0.675)

@onready var status_light: PointLight2D = $StatusLight

var _hacked: bool = false
var _done: int = 0
var _total: int = 0


func _update_light() -> void:
	status_light.color = color_hacked if _hacked else color_locked


func _ready() -> void:
	SignalHub.access_points_changed.connect(_on_access_points_changed)
	_update_light()


func is_hacked() -> bool:
	return _hacked


func get_prompt_text() -> String:
	if _hacked:
		return "Punto asegurado"
	return "Hackear punto de acceso"


func interact(_player: Node) -> void:
	if _hacked:
		if not already_done_timeline.is_empty() and is_instance_valid(Dialogic):
			SignalHub.player_control_blocked.emit(true)
			Dialogic.start(already_done_timeline)
			await Dialogic.timeline_ended
			SignalHub.player_control_blocked.emit(false)
		return

	SignalHub.hack_requested.emit()
	var success: bool = await SignalHub.hack_finished
	if not success:
		return

	_hacked = true
	_update_light()
	hacked.emit(self)

	if not success_timeline.is_empty() and is_instance_valid(Dialogic):
		SignalHub.player_control_blocked.emit(true)
		Dialogic.start(success_timeline)
		await Dialogic.timeline_ended
		SignalHub.player_control_blocked.emit(false)


func _on_access_points_changed(done: int, total: int) -> void:
	_done = done
	_total = total

