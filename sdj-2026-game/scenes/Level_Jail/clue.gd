class_name Clue
extends Area2D


signal inspected(clue: Clue)

@export var clue_id: StringName = &""
@export var clue_title: String = "Pista"

var _already_inspected: bool = false


func _ready() -> void:
	if clue_id == &"":
		clue_id = StringName(name)


func get_prompt_text() -> String:
	return "Inspeccionar"


func interact(_player: Node) -> void:
	var first_time: bool = not _already_inspected
	_already_inspected = true

	@warning_ignore("redundant_await")
	await show_clue(first_time)

	if first_time:
		inspected.emit(self)


func is_inspected() -> bool:
	return _already_inspected


func show_clue(_first_time: bool) -> void:
	push_warning("Clue: '%s' no implementa show_clue()" % name)
