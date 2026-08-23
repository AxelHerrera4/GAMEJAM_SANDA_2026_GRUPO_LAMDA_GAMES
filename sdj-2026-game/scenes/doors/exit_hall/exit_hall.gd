class_name ExitHall
extends Area2D

@export var speaker: String = "Paciente N° 6174"
@export var prompt_text: String = "Abrir puerta"
@export_file("*.tscn") var next_scene: String = "res://scenes/level_base/level_base.tscn"
@export_multiline var locked_text: String = "Está trancada desde el otro lado. Primero necesito desbloquearla: hace falta acceso de tres puntos."
@export_multiline var opened_text: String = "Los tres puntos responden a la vez. Los cerrojos ceden."

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
		SignalHub.dialogue_requested.emit(speaker, "%s (%d/%d puntos)" % [locked_text, _done, _total])
		return

	SignalHub.dialogue_requested.emit(speaker, opened_text)
	await SignalHub.ui_closed
	Transition.change_scene(next_scene)


func _on_access_points_changed(done: int, total: int) -> void:
	_done = done
	_total = total
