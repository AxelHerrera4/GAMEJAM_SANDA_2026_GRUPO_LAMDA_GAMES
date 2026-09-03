class_name Exit
extends Area2D

@export_file("*.tscn") var next_scene_path: String = ""
@export var next_scene: PackedScene
@export var prompt_text: String = "Salir"
@export var required_fragment: StringName = &""
@export_group("Dialogic")
@export var timeline_path: DialogicTimeline

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

var _is_active: bool = false


func _ready() -> void:
	add_to_group("interactable")

	if _requirement_met():
		_activate()
	else:
		_deactivate()

	FragmentManager.fragment_granted.connect(_on_fragment_granted)


func _requirement_met() -> bool:
	if not required_fragment.is_empty():
		return FragmentManager.has_fragment(required_fragment)
	return FragmentManager.get_owned().size() >= FragmentManager.CATALOG.size() and FragmentManager.CATALOG.size() > 0


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


func _on_fragment_granted(_fragment_id: StringName) -> void:
	if _requirement_met():
		_activate()


func get_prompt_text() -> String:
	return prompt_text


func interact(_player: Node) -> void:
	GameManager.play_open_door()

	if timeline_path != null and is_instance_valid(Dialogic):
		SignalHub.emit_on_player_control_blocked(true)
		Dialogic.start(timeline_path)
		await Dialogic.timeline_ended
		SignalHub.emit_on_player_control_blocked(false)
	
	if not next_scene_path.is_empty():
		GameManager.change_scene(next_scene_path)
	elif next_scene != null:
		GameManager.change_scene(next_scene)
	else:
		SignalHub.emit_on_ending_requested()
