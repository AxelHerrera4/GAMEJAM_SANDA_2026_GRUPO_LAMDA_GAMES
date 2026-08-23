class_name HackPoint
extends Area2D

signal hacked(point: HackPoint)

@export var speaker: String = "Eddy"
@export_multiline var success_text: String = "Punto de acceso asegurado."
@export_multiline var already_done_text: String = "Este punto ya está bajo mi control."

var _hacked: bool = false
var _done: int = 0
var _total: int = 0


func _ready() -> void:
	SignalHub.access_points_changed.connect(_on_access_points_changed)


func is_hacked() -> bool:
	return _hacked


func get_prompt_text() -> String:
	if _hacked:
		return "Punto asegurado"
	return "Hackear punto de acceso"


func interact(_player: Node) -> void:
	if _hacked:
		SignalHub.dialogue_requested.emit(speaker, already_done_text)
		return

	SignalHub.hack_requested.emit()
	var success: bool = await SignalHub.hack_finished
	if not success:
		return

	_hacked = true
	hacked.emit(self)
	SignalHub.dialogue_requested.emit(speaker, "%s (%d/%d)" % [success_text, _done, _total])


func _on_access_points_changed(done: int, total: int) -> void:
	_done = done
	_total = total
