extends Node2D

var _guards: Array[PatrolGuard] = []
var _dead_count: int = 0


func _ready() -> void:
	for node in find_children("*", "PatrolGuard", true, false):
		var guard: PatrolGuard = node
		_guards.append(guard)
		guard.died.connect(_on_guard_died)

	_emit_progress()


func _on_guard_died(_guard: PatrolGuard) -> void:
	_dead_count += 1
	_emit_progress()


func _emit_progress() -> void:
	SignalHub.emit_on_access_points_changed(_dead_count, _guards.size())
