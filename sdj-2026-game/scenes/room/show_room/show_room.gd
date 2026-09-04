class_name ShowRoom
extends Node2D

@onready var room: Node2D = $Room

func _on_trigger_area_body_entered(body: Node2D) -> void:
	if(body.is_in_group('player')):
		if room != null:
			room.show()
			var room_wall: TileMapLayer = room.get_node_or_null("Walls")
			if room_wall != null:
				room_wall.collision_enabled = true
		var world: Node2D = get_parent().get_parent().get_node_or_null("Tiles")
		if world != null:
			world.hide()
			var world_wall: TileMapLayer = world.get_node_or_null("Walls")
			if world_wall != null:
				world_wall.collision_enabled = false
			


func _on_trigger_area_body_exited(body: Node2D) -> void:
	if(body.is_in_group('player')):
		if room != null:
			room.hide()
			var room_wall: TileMapLayer = room.get_node_or_null("Walls")
			if room_wall != null:
				room_wall.collision_enabled = false
		var world: Node2D = get_parent().get_parent().get_node_or_null("Tiles")
		if world != null:
			world.show()
			var world_wall: TileMapLayer = world.get_node_or_null("Walls")
			if world_wall != null:
				world_wall.collision_enabled = true
			
