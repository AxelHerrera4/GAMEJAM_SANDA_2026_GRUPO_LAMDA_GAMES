class_name Bullet
extends Area2D

@export var speed: float = 300.0

@export var damage: int = 25
@export var knockback_force: float = 200.0

var _velocity: Vector2 = Vector2.ZERO

func setup(direction: Vector2, custom_damage: int = damage, custom_knockback: float = knockback_force) -> void:
	damage = custom_damage
	knockback_force = custom_knockback
	_velocity = direction * speed
	rotation = direction.angle()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	position += _velocity * delta


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.take_damage(damage, knockback_force, global_position)
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	var player: Player = area.owner as Player if (area.owner is Player) else (area.get_parent() as Player)
	if player:
		player.take_damage(damage, knockback_force, global_position)
	queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
