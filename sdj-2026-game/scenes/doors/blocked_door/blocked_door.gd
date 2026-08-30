class_name BlockedDoor
extends Area2D

@export var prompt_text: String = "Abrir puerta"

@export_group("Dialogic")
@export_file("*.dtl") var timeline_path: String = "res://dialogues/doors/blocked_door.dtl"


func get_prompt_text() -> String:
	return prompt_text


func interact(_player: Node) -> void:
	Transition.play_locked_door()
	if not timeline_path.is_empty() and is_instance_valid(Dialogic):
		SignalHub.player_control_blocked.emit(true)
		Dialogic.start(timeline_path)
		await Dialogic.timeline_ended
		SignalHub.player_control_blocked.emit(false)
