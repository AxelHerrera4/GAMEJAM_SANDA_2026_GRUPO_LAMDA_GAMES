class_name Bullet
extends Area2D

@export var speed: float = 300.0

var _velocity: Vector2 = Vector2.ZERO

func setup(direction: Vector2) -> void:
	_velocity = direction * speed
	rotation = direction.angle()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	position += _velocity * delta


func _on_body_entered(body: Node2D) -> void:
	queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
