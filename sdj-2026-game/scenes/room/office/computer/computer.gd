class_name Computer
extends Area2D

@export var speaker: String = "Paciente N° 6174"
@export var reward_fragment: StringName = &"weapons"
@export_multiline var memory_text: String = "Con que esto era antes... un capitán de las fuerzas armadas. Creo que ya voy entendiendo quién soy."
@export_multiline var leave_text: String = "Es hora de salir de aquí..."

var is_hacked: bool = false


func _ready() -> void:
	add_to_group("interactable")


func get_prompt_text() -> String:
	if is_hacked:
		return "Sistema hackeado"
	return "Hackear computadora"


func interact(_player: Player) -> void:
	if is_hacked:
		return

	SignalHub.emit_on_hack_requested()
	var success: bool = await SignalHub.hack_finished
	if not success:
		return

	is_hacked = true

	SignalHub.shatter_requested.emit()
	await SignalHub.shatter_finished

	SignalHub.dialogue_requested.emit(speaker, memory_text)
	await SignalHub.ui_closed

	FragmentManager.grant(reward_fragment)

	SignalHub.dialogue_requested.emit(speaker, leave_text)
	await SignalHub.ui_closed
