class_name HackPoint
extends Area2D

signal hacked(point: HackPoint)

@export var speaker: String = "Paciente N° 6174"
@export_multiline var success_text: String = "Punto de acceso asegurado."
@export_multiline var already_done_text: String = "Este punto ya está bajo mi control."
@export var color_locked: Color = Color(0.694, 0.0, 0.043, 0.733)
@export var color_hacked: Color = Color(0.0, 0.41, 0.076, 0.675)

@onready var status_light: PointLight2D = $StatusLight

var _hacked: bool = false
var _done: int = 0
var _total: int = 0


func _update_light() -> void:
	status_light.color = color_hacked if _hacked else color_locked


func _ready() -> void:
	SignalHub.access_points_changed.connect(_on_access_points_changed)
	_update_light()


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
	_update_light()
	hacked.emit(self)
	SignalHub.dialogue_requested.emit(speaker, "%s (%d/%d)" % [success_text, _done, _total])


func _on_access_points_changed(done: int, total: int) -> void:
	_done = done
	_total = total
