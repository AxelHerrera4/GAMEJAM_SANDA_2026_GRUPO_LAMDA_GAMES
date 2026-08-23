class_name Exit
extends Area2D

@export_file("*.tscn") var next_scene: String = ""
@export var prompt_text: String = "Salir"

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var _is_active: bool = false


func _ready() -> void:
	add_to_group("interactable")
	
	if FragmentManager.get_owned().size() >= FragmentManager.CATALOG.size() and FragmentManager.CATALOG.size() > 0:
		_activate()
	else:
		_deactivate()
	
	SignalHub.all_fragments_collected.connect(_on_all_fragments_collected)


func _activate() -> void:
	_is_active = true
	show()
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	if collision_shape_2d:
		collision_shape_2d.set_deferred("disabled", false)


func _deactivate() -> void:
	_is_active = false
	hide()
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	if collision_shape_2d:
		collision_shape_2d.set_deferred("disabled", true)


func _on_all_fragments_collected() -> void:
	_activate()


func get_prompt_text() -> String:
	return prompt_text


func interact(_player: Node) -> void:
	if not _is_active:
		return
	print("¡El jugador llegó a la salida!")
	if not next_scene.is_empty():
		Transition.change_scene(next_scene)

