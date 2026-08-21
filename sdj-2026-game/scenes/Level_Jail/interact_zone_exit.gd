extends Area2D


@export var locked: bool = true
@export var required_fragment: StringName = &"hack"
@export_file("*.tscn") var next_scene: String = "res://scenes/level_base/level_base.tscn"
@export_multiline var locked_text: String = "La puerta está sellada con una cerradura electrónica. Necesito algo con qué forzar el sistema."
@export_multiline var hack_text: String = "Conectas el fragmento a la cerradura. El panel parpadea y los cerrojos ceden con un chasquido."


func get_prompt_text() -> String:
	if locked and FragmentManager.has_fragment(required_fragment):
		return "Hackear cerradura"
	return "Abrir puerta"


func interact(_player: Node) -> void:
	if locked and not FragmentManager.has_fragment(required_fragment):
		SignalHub.dialogue_requested.emit("Eddy", locked_text)
		return

	if locked:
		SignalHub.hack_requested.emit()
		var success: bool = await SignalHub.hack_finished
		if not success:
			return
		locked = false

	SignalHub.dialogue_requested.emit("Eddy", hack_text)
	await SignalHub.ui_closed
	get_tree().change_scene_to_file(next_scene)
