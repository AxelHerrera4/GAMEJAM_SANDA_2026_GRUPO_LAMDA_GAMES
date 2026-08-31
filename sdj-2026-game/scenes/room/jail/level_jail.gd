extends Node2D

@export var reward_fragment: StringName = &"hack"

@export_group("Dialogic")
@export var awakening_timeline: DialogicTimeline

@onready var clues: Node2D = $Clues

var _clues: Array[Clue] = []
var _inspected_ids: Dictionary = {}


func _ready() -> void:
	_initialice_clues()
	SignalHub.emit_on_clues_progress(0, _clues.size())
	_play_awakening()

func _play_awakening() -> void:
	if awakening_timeline != null and is_instance_valid(Dialogic):
		SignalHub.emit_on_player_control_blocked(true)
		Dialogic.start(awakening_timeline)
		await Dialogic.timeline_ended
		SignalHub.emit_on_player_control_blocked(false)

func _initialice_clues() -> void:
	for node in clues.find_children("*", "Clue", true, false):
		var clue: Clue = node
		_clues.append(clue)
		clue.inspected.connect(_on_clue_inspected)
		
func _on_clue_inspected(clue: Clue) -> void:
	_inspected_ids[clue.clue_id] = true
	SignalHub.emit_on_clues_progress(_inspected_ids.size(), _clues.size())

	if _inspected_ids.size() >= _clues.size():
		SignalHub.emit_on_all_clues_inspected()
		FragmentManager.grant(reward_fragment)
