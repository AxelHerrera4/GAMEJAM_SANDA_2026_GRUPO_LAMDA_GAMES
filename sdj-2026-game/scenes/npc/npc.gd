class_name Npc
extends Area2D

enum EnemyState {Patrolling, Searching, Chasing}

@export var speeds: Dictionary[EnemyState, float] = {
	EnemyState.Patrolling: 100.0,
	EnemyState.Searching: 120.0,
	EnemyState.Chasing: 150.0
}
@export var angles_of_view: Dictionary[EnemyState, float] = {
	EnemyState.Patrolling: 60.0,
	EnemyState.Searching: 90.0,
	EnemyState.Chasing: 120.0
}
@export var patrol_points: Node2D

@onready var nav_agent: NavigationAgent2D = $NavAgent
@onready var player_detect: RayCast2D = $PlayerDetect
@onready var debug_label: Label = $CanvasLayer/DebugLabel
@onready var gasp_sound: AudioStreamPlayer2D = $GaspSound

var _patrol_points: Array[Vector2]
var _state: EnemyState = EnemyState.Patrolling
var _patrol_idx: int = 0
var _last_delta: float = 0.0

var _player_ref: Player


func _ready() -> void:
	#nav_agent.max_speed = speeds[_state] # DANGER: the nav_agent max_speed= is a security limit, doint this break the security
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
	detect_player()
	process_behavior()
	update_raycast()
	update_movement(delta)
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

func can_see_player() -> bool:
	return player_detect.get_collider() is Player and abs(fov_angle()) < angles_of_view[_state]

func fov_angle() -> float:
	var dir_to_player: Vector2 = global_position.direction_to(_player_ref.global_position)
	var angle_to_player: float = rad_to_deg(transform.x.angle_to(dir_to_player))
	return angle_to_player

func detect_player() -> void:
	if can_see_player():
		change_state(EnemyState.Chasing)
	elif _state == EnemyState.Chasing:
		change_state(EnemyState.Searching)

func update_raycast() -> void:
	player_detect.look_at(_player_ref.global_position)

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
	
	if _state == EnemyState.Chasing:
		gasp_sound.play()
	if _state == EnemyState.Patrolling:
		return
	if _state == EnemyState.Searching:
		return
		

func _on_nav_agent_velocity_computed(safe_velocity: Vector2) -> void:
	global_position += safe_velocity * _last_delta
 	#rotation = safe_velocity.angle()
	if safe_velocity.length() > 0.01:
		rotation = rotate_toward(rotation, safe_velocity.angle(), deg_to_rad(360) * _last_delta)
