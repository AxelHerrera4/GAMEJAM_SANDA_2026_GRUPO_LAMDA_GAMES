extends Node2D


@export var reward_fragment: StringName = &"hack"

var _clues: Array[Clue] = []
var _inspected_ids: Dictionary = {}


func _ready() -> void:
	for node in find_children("*", "Clue", true, false):
		var clue: Clue = node
		_clues.append(clue)
		clue.inspected.connect(_on_clue_inspected)

	SignalHub.emit_on_clues_progress(0, _clues.size())


func _on_clue_inspected(clue: Clue) -> void:
	_inspected_ids[clue.clue_id] = true
	SignalHub.emit_on_clues_progress(_inspected_ids.size(), _clues.size())

	if _inspected_ids.size() >= _clues.size():
		SignalHub.emit_on_all_clues_inspected()
		FragmentManager.grant(reward_fragment)

