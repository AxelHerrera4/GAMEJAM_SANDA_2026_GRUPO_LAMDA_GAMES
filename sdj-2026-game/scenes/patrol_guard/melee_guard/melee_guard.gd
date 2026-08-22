extends PatrolGuard

@onready var melee_hitbox: Area2D = $MeleeHitbox

var _can_attack: bool = true

func attack() -> void:
	if _player_ref == null: return
	_can_attack = false
	attack_timer.start() #using the timer defined by the randf or the @export
	# Hace daño al jugador
	_player_ref.take_damage(damage, knockback_force, global_position)
	print("MeleeGuard asestó un golpe al jugador!")
	
func _on_melee_hitbox_body_entered(body: Node2D) -> void:
	if body == _player_ref and _can_attack:
		attack()

func _on_attack_timer_timeout() -> void:
	super()
	_can_attack = true
	if _player_ref != null and melee_hitbox.overlaps_body(_player_ref):
		attack()
