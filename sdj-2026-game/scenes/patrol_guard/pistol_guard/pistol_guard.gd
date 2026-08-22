extends PatrolGuard

@onready var laser_sound: AudioStreamPlayer2D = $LaserSound
const BULLET = preload("uid://ceoopnav21q5a")

func shoot() -> void:
	if _state != EnemyState.Chasing: return
	laser_sound.play()
	var new_bullet: Bullet = BULLET.instantiate()
	new_bullet.position = global_position
	new_bullet.setup(global_position.direction_to(_player_ref.global_position))
	get_tree().current_scene.add_child.call_deferred(new_bullet)
	
func _on_attack_timer_timeout() -> void:
	attack_timer.wait_time = randf_range(1.5, 3.0)
	print(attack_timer.wait_time)
	shoot()
