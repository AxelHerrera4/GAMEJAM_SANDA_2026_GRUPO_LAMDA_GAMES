class_name Bullet
extends Area2D

@export var speed: float = 500.0

@export var damage: int = 25
@export var knockback_force: float = 200.0

@onready var impact_sound: AudioStreamPlayer2D = $ImpactSound

var _velocity: Vector2 = Vector2.ZERO
## Se marca al impactar para que la bala deje de existir para el juego mientras
## el sonido termina de sonar.
var _spent: bool = false

func setup(direction: Vector2, custom_damage: int = damage, custom_knockback: float = knockback_force) -> void:
	damage = custom_damage
	knockback_force = custom_knockback
	_velocity = direction * speed
	rotation = direction.angle()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	position += _velocity * delta


func _on_body_entered(body: Node2D) -> void:
	if _spent:
		return
	if body is Player:
		body.take_damage(damage, knockback_force, global_position)
		_impact()
		return
	queue_free()


func _on_area_entered(area: Area2D) -> void:
	if _spent:
		return
	var player: Player = area.owner as Player if (area.owner is Player) else (area.get_parent() as Player)
	if player:
		player.take_damage(damage, knockback_force, global_position)
		_impact()
		return
	queue_free()


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	if _spent:
		return
	queue_free()


## La bala impacto al jugador: se apaga al instante pero se mantiene viva hasta
## que el sonido de impacto acabe, porque queue_free() lo cortaria de golpe.
func _impact() -> void:
	_spent = true
	set_physics_process(false)
	hide()
	set_deferred(&"monitoring", false)
	set_deferred(&"monitorable", false)

	if impact_sound == null or impact_sound.stream == null:
		queue_free()
		return

	impact_sound.play()
	await impact_sound.finished
	queue_free()
