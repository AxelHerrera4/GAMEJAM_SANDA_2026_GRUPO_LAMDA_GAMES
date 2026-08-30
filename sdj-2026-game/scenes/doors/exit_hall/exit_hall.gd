class_name ExitHall
extends Area2D

@export var prompt_text: String = "Abrir puerta"
@export_file("*.tscn") var next_scene: String = "res://scenes/room/office/office.tscn"

@export_group("Dialogic Timelines")
@export_file("*.dtl") var locked_timeline: String = "res://dialogues/doors/exit_hall_locked.dtl"
@export_file("*.dtl") var opened_timeline: String = "res://dialogues/doors/exit_hall_opened.dtl"

var _done: int = 0
var _total: int = 0


func _ready() -> void:
	SignalHub.access_points_changed.connect(_on_access_points_changed)


func is_unlocked() -> bool:
	return _total > 0 and _done >= _total


func get_prompt_text() -> String:
	return prompt_text


func interact(_player: Node) -> void:
	if not is_unlocked():
		Transition.play_locked_door()
		if not locked_timeline.is_empty() and is_instance_valid(Dialogic):
			SignalHub.player_control_blocked.emit(true)
			Dialogic.start(locked_timeline)
			await Dialogic.timeline_ended
			SignalHub.player_control_blocked.emit(false)
		return

	if not opened_timeline.is_empty() and is_instance_valid(Dialogic):
		SignalHub.player_control_blocked.emit(true)
		Dialogic.start(opened_timeline)
		await Dialogic.timeline_ended
		SignalHub.player_control_blocked.emit(false)

	Transition.change_scene(next_scene)


func _on_access_points_changed(done: int, total: int) -> void:
	_done = done
	_total = total

