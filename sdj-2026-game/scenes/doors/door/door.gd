class_name Door
extends Area2D

@export var locked: bool = true
@export var required_fragment: StringName = &"hack"
@export_file("*.tscn") var next_scene: String = ""

@export_group("Dialogic Timelines")
@export_file("*.dtl") var locked_timeline: String = "res://dialogues/doors/door_locked.dtl"
@export_file("*.dtl") var hack_timeline: String = "res://dialogues/doors/door_hacked.dtl"

@export_group("Prompts")
@export var prompt_locked: String = "Hackear cerradura"
@export var prompt_open: String = "Abrir puerta"


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
		GameManager.play_locked_door()
		if not locked_timeline.is_empty() and is_instance_valid(Dialogic):
			SignalHub.player_control_blocked.emit(true)
			Dialogic.start(locked_timeline)
			await Dialogic.timeline_ended
			SignalHub.player_control_blocked.emit(false)
		return

	if locked:
		SignalHub.hack_requested.emit()
		var success: bool = await SignalHub.hack_finished
		if not success:
			return
		locked = false
		if not hack_timeline.is_empty() and is_instance_valid(Dialogic):
			SignalHub.player_control_blocked.emit(true)
			Dialogic.start(hack_timeline)
			await Dialogic.timeline_ended
			SignalHub.player_control_blocked.emit(false)

	if not next_scene.is_empty():
		GameManager.change_scene(next_scene)
