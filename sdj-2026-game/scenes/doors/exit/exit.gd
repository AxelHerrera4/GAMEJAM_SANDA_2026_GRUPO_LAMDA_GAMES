class_name Exit
extends Area2D

@export_file("*.tscn") var next_scene: String = ""
@export var prompt_text: String = "Salir"
@export_group("Dialogic")
@export_file("*.dtl") var timeline_path: String = ""

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
	Transition.play_open_door()

	if not timeline_path.is_empty() and is_instance_valid(Dialogic):
		SignalHub.player_control_blocked.emit(true)
		Dialogic.start(timeline_path)
		await Dialogic.timeline_ended
		SignalHub.player_control_blocked.emit(false)

	SignalHub.ending_requested.emit()

