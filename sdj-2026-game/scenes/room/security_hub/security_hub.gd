extends Node2D

@export_group("Dialogic")
@export var intro_timeline: DialogicTimeline

var _guards: Array[PatrolGuard] = []
var _dead_count: int = 0


func _ready() -> void:
	for node in find_children("*", "PatrolGuard", true, false):
		var guard: PatrolGuard = node
		_guards.append(guard)
		guard.died.connect(_on_guard_died)

	_emit_progress()
	_play_intro()


func _play_intro() -> void:
	if intro_timeline != null and is_instance_valid(Dialogic):
		SignalHub.emit_on_player_control_blocked(true)
		Dialogic.start(intro_timeline)
		await Dialogic.timeline_ended
		SignalHub.emit_on_player_control_blocked(false)


func _on_guard_died(_guard: PatrolGuard) -> void:
	_dead_count += 1
	_emit_progress()


func _emit_progress() -> void:
	SignalHub.emit_on_access_points_changed(_dead_count, _guards.size())
