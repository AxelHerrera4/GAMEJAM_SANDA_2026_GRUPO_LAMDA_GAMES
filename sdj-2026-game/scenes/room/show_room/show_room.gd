class_name ShowRoom
extends Node2D

@onready var room: Node2D = $Room
@onready var trigger_area: Area2D = $TriggerArea

var _is_player_inside: bool = false
var _guards_inside: Array[PatrolGuard] = []

func _ready() -> void:
	if room != null:
		room.hide()
		var room_wall: TileMapLayer = room.get_node_or_null("Walls")
		if room_wall != null:
			room_wall.collision_enabled = false

func _get_level_root() -> Node:
	if owner != null:
		return owner
	if get_parent() != null and get_parent().get_parent() != null:
		return get_parent().get_parent()
	return null

func _get_level_guards() -> Array[PatrolGuard]:
	var guards: Array[PatrolGuard] = []
	var level = _get_level_root()
	if level != null:
		for node in level.find_children("*", "PatrolGuard", true, false):
			if node is PatrolGuard:
				guards.append(node)
	return guards

func _get_guard_from_area(area: Area2D) -> PatrolGuard:
	if area is PatrolGuard:
		return area as PatrolGuard
	if area.get_parent() is PatrolGuard:
		return area.get_parent() as PatrolGuard
	return null

func _clean_guards_inside() -> void:
	_guards_inside = _guards_inside.filter(func(g): return is_instance_valid(g) and not g.is_dead)

func _update_guards_visibility() -> void:
	_clean_guards_inside()
	for guard in _get_level_guards():
		if not is_instance_valid(guard):
			continue
		if _is_player_inside:
			var is_inside: bool = _guards_inside.has(guard)
			guard.set_exterior_hidden(not is_inside)
		else:
			guard.set_exterior_hidden(false)

func _on_trigger_area_body_entered(body: Node2D) -> void:
	if body.is_in_group('player'):
		_is_player_inside = true
		if room != null:
			room.show()
			var room_wall: TileMapLayer = room.get_node_or_null("Walls")
			if room_wall != null:
				room_wall.collision_enabled = true
		
		var level = _get_level_root()
		if level != null:
			var world: Node2D = level.get_node_or_null("Tiles")
			if world != null:
				world.hide()
				var world_wall: TileMapLayer = world.get_node_or_null("Walls")
				if world_wall != null:
					world_wall.collision_enabled = false

		if trigger_area != null:
			for area in trigger_area.get_overlapping_areas():
				var guard: PatrolGuard = _get_guard_from_area(area)
				if guard != null and not _guards_inside.has(guard):
					_guards_inside.append(guard)

		_update_guards_visibility()

func _on_trigger_area_body_exited(body: Node2D) -> void:
	if body.is_in_group('player'):
		_is_player_inside = false
		if room != null:
			room.hide()
			var room_wall: TileMapLayer = room.get_node_or_null("Walls")
			if room_wall != null:
				room_wall.collision_enabled = false
		
		var level = _get_level_root()
		if level != null:
			var world: Node2D = level.get_node_or_null("Tiles")
			if world != null:
				world.show()
				var world_wall: TileMapLayer = world.get_node_or_null("Walls")
				if world_wall != null:
					world_wall.collision_enabled = true

		_update_guards_visibility()

func _on_trigger_area_area_entered(area: Area2D) -> void:
	var guard: PatrolGuard = _get_guard_from_area(area)
	if guard != null:
		if not _guards_inside.has(guard):
			_guards_inside.append(guard)
		if _is_player_inside:
			guard.set_exterior_hidden(false)

func _on_trigger_area_area_exited(area: Area2D) -> void:
	var guard: PatrolGuard = _get_guard_from_area(area)
	if guard != null:
		_guards_inside.erase(guard)
		if _is_player_inside:
			guard.set_exterior_hidden(true)
