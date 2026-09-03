class_name PatrolGuard
extends Area2D

signal died(guard: PatrolGuard)

enum EnemyState {Patrolling, Searching, Chasing}

@export var speeds: Dictionary[EnemyState, float] = {
	EnemyState.Patrolling: 150.0,
	EnemyState.Searching: 170.0,
	EnemyState.Chasing: 200.0
}
@export var angles_of_view: Dictionary[EnemyState, float] = {
	EnemyState.Patrolling: 70.0,
	EnemyState.Searching: 90.0,
	EnemyState.Chasing: 120.0
}
@export var view_distance: float = 400.0

@export var patrol_points: Node2D
@export var damage: int = 20 # per bullet or per mer melee atack or per catch
@export var knockback_force: float = 250.0
@export var attack_cooldown: float = 1.2 # Segundos entre ataque


@onready var nav_agent: NavigationAgent2D = $NavAgent
@onready var player_detect: RayCast2D = $PlayerDetect
@onready var debug_label: Label = $DebugLabel
@onready var gasp_sound: AudioStreamPlayer2D = $GaspSound
@onready var attack_timer: Timer = $AttackTimer
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var vision_cone: VisionCone = $VisionCone
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var hitbox_collision_shape: CollisionShape2D = $Hitbox/hitbox_collision_shape

var _patrol_points: Array[Vector2]
var _state: EnemyState = EnemyState.Patrolling
var _patrol_idx: int = 0
var _last_delta: float = 0.0
var _player_ref: Player
var facing_direction: Vector2 = Vector2.DOWN
var is_moving: bool = false
var is_dead: bool = false

func _ready() -> void:
	nav_agent.max_speed = speeds[_state] # DANGER: the nav_agent max_speed= is a security limit, doint this break the security
	attack_timer.wait_time = attack_cooldown
	if animation_tree:
		animation_tree.set("parameters/idle/blend_position", facing_direction)
		animation_tree.set("parameters/move/blend_position", facing_direction)
	if patrol_points:
		for node in patrol_points.get_children():
			if node is Marker2D:
				_patrol_points.append(node.global_position)

		if _patrol_points.size() < 2:
			print("Npc: Advertencia: menos de 2 puntos de patrullaje (%d)" % _patrol_points.size())

	_player_ref = get_tree().get_first_node_in_group("player") as Player
	_sync_vision_cone_shape()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("set_target"):
		nav_agent.target_position = get_global_mouse_position()


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_instance_valid(_player_ref):
		_player_ref = get_tree().get_first_node_in_group("player") as Player

	update_raycast()
	detect_player()
	process_behavior()
	update_movement(delta)
	update_vision_cone()
	if debug_label:
		debug_label.text = "SeePlayer: %s \n" % can_see_player()
		debug_label.text += "FOV: %.2f\n" % fov_angle()
		debug_label.text += "\nState: %s" % EnemyState.keys()[_state]

func update_movement(delta: float) -> void:
	_last_delta = delta
	if nav_agent.is_navigation_finished():
		nav_agent.set_velocity(Vector2.ZERO)
		return
	var npp: Vector2 = nav_agent.get_next_path_position()
	var new_vel: Vector2 = global_position.direction_to(npp) * speeds[_state]
	nav_agent.set_velocity(new_vel)

## Apunta el cono hacia donde mira el guardia. Barato: solo cambia la rotacion.
func update_vision_cone() -> void:
	if not is_instance_valid(vision_cone):
		return
	vision_cone.rotation = facing_direction.angle()


## Ajusta apertura/alcance/color del cono para que coincida con la deteccion real.
## OJO: can_see_player() usa abs(fov_angle()) < angles_of_view, o sea que
## angles_of_view es MEDIO cono -> la apertura visual es el doble.
func _sync_vision_cone_shape() -> void:
	if not is_instance_valid(vision_cone):
		return
	# view_distance se compara en GLOBAL (global_position.distance_to), pero el
	# largo del cono es LOCAL y el guardia tiene scale 1.7 -> hay que dividir,
	# si no el cono se dibuja 1.7x mas largo de lo que el guardia ve de verdad.
	var world_scale: float = maxf(vision_cone.global_scale.x, 0.001)
	vision_cone.configure(angles_of_view[_state] * 2.0, view_distance / world_scale)


func can_see_player() -> bool:
	if not is_instance_valid(_player_ref):
		return false
	var dist: float = global_position.distance_to(_player_ref.global_position)
	if dist > view_distance:
		return false
	var collider: Object = player_detect.get_collider()
	var is_player_hit: bool = collider is Player or (collider is Node and (collider.get_parent() is Player or collider.owner is Player))
	return is_player_hit and abs(fov_angle()) < angles_of_view[_state]

func fov_angle() -> float:
	if not is_instance_valid(_player_ref):
		return 180.0
	var dir_to_player: Vector2 = global_position.direction_to(_player_ref.global_position)
	var angle_to_player: float = rad_to_deg(facing_direction.angle_to(dir_to_player))
	return angle_to_player

func detect_player() -> void:
	if can_see_player():
		change_state(EnemyState.Chasing)
	elif _state == EnemyState.Chasing:
		change_state(EnemyState.Searching)

func update_raycast() -> void:
	if not is_instance_valid(_player_ref):
		return
	player_detect.look_at(_player_ref.global_position)
	player_detect.target_position = Vector2(view_distance, 0)
	player_detect.force_raycast_update()

func navigate_to_patrol_point() -> void:
	if _patrol_points.size() == 0: return
	nav_agent.target_position = _patrol_points[_patrol_idx]
	_patrol_idx = (_patrol_idx + 1) % _patrol_points.size()

func process_patrolling() -> void:
	if nav_agent.is_navigation_finished():
		navigate_to_patrol_point()

func process_searching() -> void:
	if nav_agent.is_navigation_finished():
		change_state(EnemyState.Patrolling)

func process_chasing() -> void:
	if not is_instance_valid(_player_ref):
		change_state(EnemyState.Searching)
		return
	nav_agent.target_position = _player_ref.global_position

func process_behavior() -> void:
	match _state:
		EnemyState.Patrolling:
			process_patrolling()
		EnemyState.Searching:
			process_searching()
		EnemyState.Chasing:
			process_chasing()

func change_state(new_state: EnemyState) -> void:
	if _state == new_state: return
	_state = new_state
	_sync_vision_cone_shape()
	
	if _state == EnemyState.Chasing:
		gasp_sound.play()
		attack_timer.start(attack_cooldown)
	else:
		attack_timer.stop()
	if _state == EnemyState.Patrolling:
		return
	if _state == EnemyState.Searching:
		return
		

func _on_nav_agent_velocity_computed(safe_velocity: Vector2) -> void:
	if is_dead:
		return
		
	global_position += safe_velocity * _last_delta
	if safe_velocity.length() > 0.01:
		is_moving = true
		facing_direction = safe_velocity.normalized()
		if animation_tree:
			animation_tree.set("parameters/idle/blend_position", facing_direction)
			animation_tree.set("parameters/move/blend_position", facing_direction)
	else:
		is_moving = false


func _on_attack_timer_timeout() -> void:
	attack_timer.wait_time = randf_range(attack_cooldown, attack_cooldown * 2.0)
	print(attack_timer.wait_time)

func deactivate_guard() -> void:
	
	is_moving = false

	if nav_agent:
		nav_agent.set_velocity(Vector2.ZERO)
	if hitbox_collision_shape:
		hitbox_collision_shape.set_deferred(&"disabled", true)
	if collision_shape_2d:
		collision_shape_2d.set_deferred(&"disabled", true)
	if attack_timer:
		attack_timer.stop.call_deferred()
	if vision_cone:
		vision_cone.hide.call_deferred()


func die() -> void:
	print("guard trying to be killed")

	if is_dead:
		return

	if not can_see_player():
		GameManager.fade_in_out(func():
			is_dead = true
			deactivate_guard()
			died.emit(self)
		)
