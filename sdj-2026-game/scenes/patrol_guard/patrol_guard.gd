class_name PatrolGuard
extends Area2D

signal died(guard: PatrolGuard)

enum EnemyState {Patrolling, Searching, Chasing}

@export var speeds: Dictionary[EnemyState, float] = {
	EnemyState.Patrolling: 150.0,
	EnemyState.Searching: 170.0,
	EnemyState.Chasing: 200.0
}
## Apertura TOTAL del cono de vision en grados, no el medio angulo: 120 = el
## guardia ve 60 grados a cada lado. Es el mismo numero que dibuja la luz, asi
## que lo que se ve iluminado es exactamente lo que detecta.
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
@export var target_chase_distance: float = 45.0
@export var target_patrol_distance: float = 25.0
@export var search_duration: float = 3.0
@export var search_scan_angle: float = 45.0
@export var search_scan_speed: float = 3.0


@onready var nav_agent: NavigationAgent2D = $NavAgent
@onready var player_detect: RayCast2D = $PlayerDetect
@onready var debug_label: Label = $DebugLabel
@onready var gasp_sound: AudioStreamPlayer2D = $GaspSound
@onready var steps_sound: AudioStreamPlayer2D = $StepsSound
@onready var attack_timer: Timer = $AttackTimer
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var vision_cone: VisionCone = $VisionCone
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var hitbox_collision_shape: CollisionShape2D = $Hitbox/hitbox_collision_shape
@onready var sprite_2d: Sprite2D = $Sprite2D

var _patrol_points: Array[Vector2]
var _state: EnemyState = EnemyState.Patrolling
var _patrol_idx: int = 0
var _last_delta: float = 0.0
var _player_ref: Player
var facing_direction: Vector2 = Vector2.DOWN
var is_moving: bool = false
var is_dead: bool = false
var is_exterior_hidden: bool = false

var last_known_player_position: Vector2 = Vector2.ZERO
var _search_timer: Timer
var _is_inspecting: bool = false
var _inspect_base_angle: float = 0.0
var _inspect_time_elapsed: float = 0.0

func _ready() -> void:
	nav_agent.max_speed = speeds[_state] # DANGER: the nav_agent max_speed= is a security limit, doint this break the security
	nav_agent.target_desired_distance = target_patrol_distance
	attack_timer.wait_time = attack_cooldown
	
	_search_timer = Timer.new()
	_search_timer.name = "SearchTimer"
	_search_timer.one_shot = true
	_search_timer.timeout.connect(_on_search_timer_timeout)
	add_child(_search_timer)
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
	_make_loopable(steps_sound.stream)
	_update_exterior_visibility()


## Los pasos son un bucle continuo mientras el guardia camina, asi que hay que
## marcar el .ogg como loopable en runtime (el import viene con loop = false).
func _make_loopable(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD


## Arranca o corta los pasos segun si el guardia se esta moviendo de verdad.
func _update_steps_sound() -> void:
	if steps_sound == null or steps_sound.stream == null:
		return
	var should_play: bool = is_moving and not is_dead
	if should_play and not steps_sound.playing:
		steps_sound.play()
	elif not should_play and steps_sound.playing:
		steps_sound.stop()

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
	process_behavior(delta)
	update_movement(delta)
	update_vision_cone()
	if debug_label:
		debug_label.text = "SeePlayer: %s \n" % can_see_player()
		debug_label.text += "FOV: %.2f\n" % fov_angle()
		debug_label.text += "\nState: %s" % EnemyState.keys()[_state]

func update_movement(delta: float) -> void:
	_last_delta = delta
	if _is_inspecting:
		nav_agent.set_velocity(Vector2.ZERO)
		return
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


## Ajusta apertura/alcance del cono para que coincida con la deteccion real.
func _sync_vision_cone_shape() -> void:
	if not is_instance_valid(vision_cone):
		return
	# view_distance se compara en GLOBAL (global_position.distance_to), pero el
	# largo del cono es LOCAL y el guardia tiene scale 1.7 -> hay que dividir,
	# si no el cono se dibuja 1.7x mas largo de lo que el guardia ve de verdad.
	var world_scale: float = maxf(vision_cone.global_scale.x, 0.001)
	vision_cone.configure(angles_of_view[_state], view_distance / world_scale)


func can_see_player() -> bool:
	if not is_instance_valid(_player_ref):
		return false
	var dist: float = global_position.distance_to(_player_ref.global_position)
	if dist > view_distance:
		return false
	var collider: Object = player_detect.get_collider()
	var is_player_hit: bool = collider is Player or (collider is Node and (collider.get_parent() is Player or collider.owner is Player))
	return is_player_hit and absf(fov_angle()) < angles_of_view[_state] * 0.5

func fov_angle() -> float:
	if not is_instance_valid(_player_ref):
		return 180.0
	var dir_to_player: Vector2 = global_position.direction_to(_player_ref.global_position)
	var angle_to_player: float = rad_to_deg(facing_direction.angle_to(dir_to_player))
	return angle_to_player

func detect_player() -> void:
	if can_see_player():
		last_known_player_position = _player_ref.global_position
		if _state != EnemyState.Chasing:
			change_state(EnemyState.Chasing)
	elif _state == EnemyState.Chasing:
		change_state(EnemyState.Searching)

func update_raycast() -> void:
	if not is_instance_valid(_player_ref):
		return
	player_detect.look_at(_player_ref.global_position)
	player_detect.target_position = Vector2(view_distance, 0)
	player_detect.force_raycast_update()

func _find_closest_patrol_point_index() -> int:
	if _patrol_points.is_empty():
		return 0
	var closest_idx: int = 0
	var min_dist: float = INF
	for i in range(_patrol_points.size()):
		var d: float = global_position.distance_to(_patrol_points[i])
		if d < min_dist:
			min_dist = d
			closest_idx = i
	return closest_idx

func navigate_to_patrol_point() -> void:
	if _patrol_points.size() == 0: return
	nav_agent.target_position = _patrol_points[_patrol_idx]
	_patrol_idx = (_patrol_idx + 1) % _patrol_points.size()

func process_patrolling() -> void:
	if nav_agent.is_navigation_finished():
		navigate_to_patrol_point()

func process_searching(delta: float) -> void:
	if not _is_inspecting:
		if nav_agent.is_navigation_finished():
			_is_inspecting = true
			_inspect_base_angle = facing_direction.angle()
			_inspect_time_elapsed = 0.0
			nav_agent.set_velocity(Vector2.ZERO)
			_search_timer.start(search_duration)
	else:
		_inspect_time_elapsed += delta
		var sweep_offset: float = sin(_inspect_time_elapsed * search_scan_speed) * deg_to_rad(search_scan_angle)
		facing_direction = Vector2.from_angle(_inspect_base_angle + sweep_offset)
		if animation_tree:
			animation_tree.set("parameters/idle/blend_position", facing_direction)
			animation_tree.set("parameters/move/blend_position", facing_direction)

func _on_search_timer_timeout() -> void:
	if _state == EnemyState.Searching:
		change_state(EnemyState.Patrolling)

func process_chasing() -> void:
	if not is_instance_valid(_player_ref):
		change_state(EnemyState.Searching)
		return
	nav_agent.target_position = _player_ref.global_position

func process_behavior(delta: float) -> void:
	match _state:
		EnemyState.Patrolling:
			process_patrolling()
		EnemyState.Searching:
			process_searching(delta)
		EnemyState.Chasing:
			process_chasing()

func change_state(new_state: EnemyState) -> void:
	if _state == new_state: return
	_state = new_state
	_sync_vision_cone_shape()
	
	if _state == EnemyState.Chasing:
		_is_inspecting = false
		if _search_timer and not _search_timer.is_stopped():
			_search_timer.stop()
		nav_agent.target_desired_distance = target_chase_distance
		gasp_sound.play()
		attack_timer.start(attack_cooldown)
	else:
		attack_timer.stop()
		nav_agent.target_desired_distance = target_patrol_distance

	if _state == EnemyState.Searching:
		_is_inspecting = false
		_inspect_time_elapsed = 0.0
		if last_known_player_position != Vector2.ZERO:
			nav_agent.target_position = last_known_player_position

	if _state == EnemyState.Patrolling:
		_is_inspecting = false
		if _search_timer and not _search_timer.is_stopped():
			_search_timer.stop()
		_patrol_idx = _find_closest_patrol_point_index()
		navigate_to_patrol_point()

	_update_exterior_visibility()

func set_exterior_hidden(hidden: bool) -> void:
	is_exterior_hidden = hidden
	_update_exterior_visibility()

func _update_exterior_visibility() -> void:
	if not is_inside_tree() or sprite_2d == null:
		return
	if is_dead:
		sprite_2d.visible = true
		if vision_cone:
			vision_cone.visible = false
		return

	if is_exterior_hidden:
		sprite_2d.visible = false
		if vision_cone:
			# Si el guardia esta persiguiendo o buscando al jugador, la linterna se mantiene visible
			vision_cone.visible = (_state == EnemyState.Chasing or _state == EnemyState.Searching)
	else:
		sprite_2d.visible = true
		if vision_cone:
			vision_cone.visible = true

func _on_nav_agent_velocity_computed(safe_velocity: Vector2) -> void:
	if is_dead:
		return
		
	global_position += safe_velocity * _last_delta
	if safe_velocity.length() > 0.01:
		is_moving = true
	else:
		is_moving = false

	if _state == EnemyState.Chasing and is_instance_valid(_player_ref):
		var dir_to_target: Vector2 = global_position.direction_to(_player_ref.global_position)
		if dir_to_target != Vector2.ZERO:
			facing_direction = dir_to_target
			if animation_tree:
				animation_tree.set("parameters/idle/blend_position", facing_direction)
				animation_tree.set("parameters/move/blend_position", facing_direction)
	elif not _is_inspecting and is_moving:
		facing_direction = safe_velocity.normalized()
		if animation_tree:
			animation_tree.set("parameters/idle/blend_position", facing_direction)
			animation_tree.set("parameters/move/blend_position", facing_direction)

	_update_steps_sound()


func _on_attack_timer_timeout() -> void:
	attack_timer.wait_time = randf_range(attack_cooldown, attack_cooldown * 2.0)
	print(attack_timer.wait_time)

func deactivate_guard() -> void:
	
	is_moving = false
	_update_steps_sound()

	if _search_timer:
		_search_timer.stop.call_deferred()
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
	_update_exterior_visibility()


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
