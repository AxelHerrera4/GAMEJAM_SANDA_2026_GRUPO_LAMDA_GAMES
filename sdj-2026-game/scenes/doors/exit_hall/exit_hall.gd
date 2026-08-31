class_name ExitHall
extends Area2D

@export var prompt_text: String = "Abrir puerta"
@export_file("*.tscn") var next_scene_path: String = ""
@export var next_scene: PackedScene

@export_group("Dialogic Timelines")
@export var locked_timeline:DialogicTimeline
@export var opened_timeline: DialogicTimeline

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
		GameManager.play_locked_door()
		if locked_timeline != null and is_instance_valid(Dialogic):
			SignalHub.emit_on_player_control_blocked(true)
			Dialogic.start(locked_timeline)
			await Dialogic.timeline_ended
			SignalHub.emit_on_player_control_blocked(false)
		return

	if opened_timeline != null and is_instance_valid(Dialogic):
		SignalHub.emit_on_player_control_blocked(true)
		Dialogic.start(opened_timeline)
		await Dialogic.timeline_ended
		SignalHub.emit_on_player_control_blocked(false)

	if not next_scene_path.is_empty():
		GameManager.change_scene(next_scene_path)
	elif next_scene != null:
		GameManager.change_scene(next_scene)



func _on_access_points_changed(done: int, total: int) -> void:
	_done = done
	_total = total
