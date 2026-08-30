class_name Computer
extends Area2D

@export var reward_fragment: StringName = &"attack"

@export_group("Dialogic")
@export_file("*.dtl") var timeline_path: String = "res://dialogues/office/computer_memory.dtl"

var is_hacked: bool = false


func _ready() -> void:
	add_to_group("interactable")


func get_prompt_text() -> String:
	if is_hacked:
		return "Sistema hackeado"
	return "Hackear computadora"


func interact(_player: Player) -> void:
	if is_hacked:
		return

	SignalHub.emit_on_hack_requested()
	var success: bool = await SignalHub.hack_finished
	if not success:
		return

	is_hacked = true

	if not timeline_path.is_empty() and is_instance_valid(Dialogic):
		SignalHub.emit_on_player_control_blocked(true)
		Dialogic.start(timeline_path)
		await Dialogic.timeline_ended
		FragmentManager.grant(reward_fragment)
		SignalHub.emit_on_player_control_blocked(false)
		return


	FragmentManager.grant(reward_fragment)
