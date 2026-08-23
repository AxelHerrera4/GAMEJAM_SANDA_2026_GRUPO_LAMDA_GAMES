class_name BlockedDoor
extends Area2D

@export var speaker: String = "Paciente N° 6174"
@export var prompt_text: String = "Abrir puerta"
@export_multiline var message: String = "No puedo entrar aquí."


func get_prompt_text() -> String:
	return prompt_text


func interact(_player: Node) -> void:
	Transition.play_locked_door()
	SignalHub.dialogue_requested.emit(speaker, message)
