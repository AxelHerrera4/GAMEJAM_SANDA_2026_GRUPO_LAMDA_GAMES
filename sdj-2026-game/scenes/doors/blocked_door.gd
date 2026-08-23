class_name BlockedDoor
extends Area2D

@export var speaker: String = "Eddy"
@export var prompt_text: String = "Abrir puerta"
@export_multiline var message: String = "No puedo entrar aquí."


func get_prompt_text() -> String:
	return prompt_text


func interact(_player: Node) -> void:
	SignalHub.dialogue_requested.emit(speaker, message)
