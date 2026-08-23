class_name Door
extends Area2D

@export var locked: bool = true
@export var required_fragment: StringName = &"hack"
@export_file("*.tscn") var next_scene: String = ""
@export_multiline var locked_text: String = "La puerta está sellada con una cerradura electrónica. Necesito algo con qué forzar el sistema."
@export_multiline var hack_text: String = "Conectas el fragmento a la cerradura. El panel parpadea y los cerrojos ceden con un chasquido."
@export_multiline var open_text: String = ""

@export_group("Prompts")
@export var prompt_locked: String = "Hackear cerradura"
@export var prompt_open: String = "Abrir puerta"
@export var speaker_name: String = "Eddy"


func _ready() -> void:
	add_to_group("interactable")


func get_prompt_text() -> String:
	if locked:
		if FragmentManager.has_fragment(required_fragment):
			return prompt_locked
		return prompt_open
	return prompt_open


func interact(_player: Node) -> void:
	if locked and not FragmentManager.has_fragment(required_fragment):
		Transition.play_locked_door()
		if not locked_text.is_empty():
			SignalHub.dialogue_requested.emit(speaker_name, locked_text)
		return

	if locked:
		SignalHub.hack_requested.emit()
		var success: bool = await SignalHub.hack_finished
		if not success:
			return
		locked = false
		if not hack_text.is_empty():
			SignalHub.dialogue_requested.emit(speaker_name, hack_text)
			await SignalHub.ui_closed

	if not next_scene.is_empty():
		#GameManager.change_scene(next_scene)
		Transition.change_scene(next_scene)
	elif not open_text.is_empty():
		SignalHub.dialogue_requested.emit(speaker_name, open_text)
