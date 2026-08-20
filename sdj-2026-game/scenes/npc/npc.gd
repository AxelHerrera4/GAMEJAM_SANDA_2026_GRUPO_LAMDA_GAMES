class_name Npc
extends Area2D

enum EnemyState {Patrolling, Searching, Chasing}

@export var speed: float = 100.0
@export var patrol_points: Node2D

@onready var nav_agent: NavigationAgent2D = $NavAgent
@onready var player_detect: RayCast2D = $PlayerDetect
@onready var debug_label: Label = $CanvasLayer/DebugLabel

var _patrol_points: Array[Vector2]
var _state: EnemyState = EnemyState.Patrolling
var _patrol_idx: int = 0
var _last_delta: float = 0.0

var _player_ref: Player


func _ready() -> void:
	nav_agent.max_speed = speed # DANGER: the nav_agent max_speed= is a security limit, doint this break the security
	if patrol_points:
		for node in patrol_points.get_children():
			if node is Marker2D:
				_patrol_points.append(node.global_position)

		if _patrol_points.size() < 2:
			queue_free()
			print("Npc: Not enough patrol points (%d), removing npc" % _patrol_points.size())
			return

		_player_ref = get_tree().get_first_node_in_group("player")
		if !_player_ref:
			queue_free()
			print("Npc: No player found, removing npc")
			return

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("set_target"):
		nav_agent.target_position = get_global_mouse_position()


func _physics_process(delta: float) -> void:
	process_behavior()
	update_raycast()
	update_movement(delta)
	debug_label.text = "SeePlayer: %s \n" % can_see_player()
	debug_label.text += "FOV: %.2f" % fov_angle()

func update_movement(delta: float) -> void:
	_last_delta = delta
	if nav_agent.is_navigation_finished():
		nav_agent.set_velocity(Vector2.ZERO)
		return
	var npp: Vector2 = nav_agent.get_next_path_position()
	var new_vel: Vector2 = global_position.direction_to(npp) * speed
	nav_agent.set_velocity(new_vel)

func can_see_player() -> bool:
	return player_detect.get_collider() is Player and fov_angle() < 60.0

func fov_angle() -> float:
	var dirToPlayer: Vector2 = global_position.direction_to(_player_ref.global_position)
	var angleToPlayer: float = rad_to_deg(transform.x.angle_to(dirToPlayer))
	return angleToPlayer

func update_raycast() -> void:
	player_detect.look_at(_player_ref.global_position)

func navigate_to_patrol_point() -> void:
	if _patrol_points.size() == 0: return
	nav_agent.target_position = _patrol_points[_patrol_idx]
	_patrol_idx = (_patrol_idx + 1) % _patrol_points.size()

func process_patrolling() -> void:
	if nav_agent.is_navigation_finished():
		navigate_to_patrol_point()

func process_behavior() -> void:
	match _state:
		EnemyState.Patrolling:
			process_patrolling()


func _on_nav_agent_velocity_computed(safe_velocity: Vector2) -> void:
	global_position += safe_velocity * _last_delta
 	#rotation = safe_velocity.angle()
	if safe_velocity.length() > 0.01:
		rotation = rotate_toward(rotation, safe_velocity.angle(), deg_to_rad(360) * _last_delta)
