class_name EndingDoor
extends Area2D

@export var prompt_text: String = "Salir"
@export var speaker: String = "Paciente N° 6174"
@export_multiline var message: String = ""


func _ready() -> void:
	add_to_group("interactable")


func get_prompt_text() -> String:
	return prompt_text


func interact(_player: Node) -> void:
	Transition.play_open_door()

	if not message.is_empty():
		SignalHub.dialogue_requested.emit(speaker, message)
		await SignalHub.ui_closed

	SignalHub.ending_requested.emit()
