class_name Player
extends CharacterBody2D

@export var speed: float = 120.0

var _nearby_interactables: Array[Node] = []
var _current_interactable: Node = null


func _physics_process(_delta: float) -> void:
	var input: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input * speed
	move_and_slide()
	_update_current_interactable()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and _current_interactable != null:
		get_viewport().set_input_as_handled()
		try_interact()


func try_interact() -> void:
	if _current_interactable == null:
		return
	if _current_interactable.has_method("interact"):
		_current_interactable.interact(self)
	else:
		print("Player: %s esta en el grupo interactable pero no tiene interact()" % _current_interactable.name)


func get_current_interactable() -> Node:
	return _current_interactable


func _update_current_interactable() -> void:
	var closest: Node = null
	var closest_dist: float = INF

	for i in range(_nearby_interactables.size() - 1, -1, -1):
		var target: Node = _nearby_interactables[i]
		if not is_instance_valid(target):
			_nearby_interactables.remove_at(i)
			continue
		var dist: float = global_position.distance_squared_to(target.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = target

	if closest != _current_interactable:
		_current_interactable = closest
		SignalHub.interactable_changed.emit(_current_interactable)


func _add_interactable(node: Node) -> void:
	if node.is_in_group("interactable") and not _nearby_interactables.has(node):
		_nearby_interactables.append(node)


func _remove_interactable(node: Node) -> void:
	_nearby_interactables.erase(node)


func _on_interact_zone_area_entered(area: Area2D) -> void:
	_add_interactable(area)


func _on_interact_zone_area_exited(area: Area2D) -> void:
	_remove_interactable(area)


func _on_interact_zone_body_entered(body: Node2D) -> void:
	_add_interactable(body)


func _on_interact_zone_body_exited(body: Node2D) -> void:
	_remove_interactable(body)
