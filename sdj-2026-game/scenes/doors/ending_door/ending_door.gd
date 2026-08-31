class_name EndingDoor
extends Area2D

@export var prompt_text: String = "Salir"

@export_group("Dialogic")
@export_file("*.dtl") var timeline_path: String = ""


func _ready() -> void:
	add_to_group("interactable")


func get_prompt_text() -> String:
	return prompt_text


func interact(_player: Node) -> void:
	GameManager.play_open_door()

	if not timeline_path.is_empty() and is_instance_valid(Dialogic):
		SignalHub.emit_on_player_control_blocked(true)
		Dialogic.start(timeline_path)
		await Dialogic.timeline_ended
		SignalHub.emit_on_player_control_blocked(false)

	SignalHub.emit_on_ending_requested()
