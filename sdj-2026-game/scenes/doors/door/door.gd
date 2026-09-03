class_name Door
extends Area2D

@export var locked: bool = true
@export var required_fragment: StringName = &"hack"
@export_file("*.tscn") var next_scene_path: String = ""
@export var next_scene: PackedScene

@export_group("All Fragments Collected")
@export_file("*.tscn") var next_scene_path_all_fragments: String = ""
@export var next_scene_all_fragments: PackedScene

@export_group("Dialogic Timelines")
@export var locked_timeline: DialogicTimeline
@export var hack_timeline: DialogicTimeline

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
		if locked_timeline != null and is_instance_valid(Dialogic):
			SignalHub.emit_on_player_control_blocked(true)
			Dialogic.start(locked_timeline)
			await Dialogic.timeline_ended
			SignalHub.emit_on_player_control_blocked(false)
		return

	if locked:
		SignalHub.emit_on_hack_requested()
		var success: bool = await SignalHub.hack_finished
		if not success:
			return
		locked = false
		if hack_timeline != null and is_instance_valid(Dialogic):
			SignalHub.emit_on_player_control_blocked(true)
			Dialogic.start(hack_timeline)
			await Dialogic.timeline_ended
			SignalHub.emit_on_player_control_blocked(false)

	var target_path: String = next_scene_path
	var target_scene: PackedScene = next_scene

	var all_fragments_collected: bool = FragmentManager.get_owned().size() >= FragmentManager.CATALOG.size() and FragmentManager.CATALOG.size() > 0
	if all_fragments_collected:
		if not next_scene_path_all_fragments.is_empty():
			target_path = next_scene_path_all_fragments
			target_scene = null
		elif next_scene_all_fragments != null:
			target_path = ""
			target_scene = next_scene_all_fragments

	if not target_path.is_empty():
		GameManager.change_scene(target_path)
	elif target_scene != null:
		GameManager.change_scene(target_scene)
