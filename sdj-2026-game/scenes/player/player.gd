class_name Player
extends CharacterBody2D

@export var speed: float = 120.0
@export var health: int = 100
@export var max_health: int = 100
@export var hurt_duration: float = 0.4
@export var knockback_friction: float = 10.0

###Stamina
@export_group("Stamina")
@export var stamina: float = 100.0
@export var max_stamina: float = 100.0
@export var stamina_regen_rate: float = 20.0
@export var stamina_regen_delay: float = 1.0
@export var sprint_cost: float = 25.0
@export var sprint_speed_multiplier: float = 1.6

@onready var hurt_timer: Timer = $HurtTimer
@onready var stamina_regen_timer: Timer = $StaminaRegenTimer
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var attack_timer: Timer = $AttackTimer
@onready var melee_area: Area2D = $MeleeArea
@onready var attack_sound: AudioStreamPlayer = $AttackSound

var facing_direction: Vector2 = Vector2.DOWN

#stamina
var _is_sprinting: bool = false
var _is_regenerating_stamina: bool = false
#stamina/
var _nearby_interactables: Array[Node] = []
var _current_interactable: Node = null
var _is_hurt: bool = false
var _knockback_velocity: Vector2 = Vector2.ZERO
var _control_blocked: bool = false
var _has_attack_fragment: bool = false
var _can_attack: bool = true

var is_hurt: bool:
	get: return _is_hurt
var is_sprinting: bool:
	get: return _is_sprinting
var is_still: bool:
	get: return is_zero_approx(velocity.length())
var is_attacking: bool # TODO: use for activate the attack animation with AnimationTree

func _ready() -> void:
	_setup_spawn_position()
	if hurt_timer:
		hurt_timer.wait_time = hurt_duration
	if stamina_regen_timer:
		stamina_regen_timer.wait_time = stamina_regen_delay
	if animation_tree:
		animation_tree.set("parameters/idle/blend_position", facing_direction)
		animation_tree.set("parameters/move/blend_position", facing_direction)
	SignalHub.emit_on_player_health_changed(health, max_health)
	SignalHub.emit_on_player_stamina_changed(stamina, max_stamina)
	SignalHub.player_control_blocked.connect(_on_control_blocked)
	_has_attack_fragment = FragmentManager.has_fragment(FragmentManager.ATTACK)
	#_has_attack_fragment = true #DANGER For test
	_can_attack = _has_attack_fragment
	FragmentManager.fragment_granted.connect(_on_fragment_granted)

func _setup_spawn_position() -> void:
	var spawn: Node2D = get_parent().get_node_or_null("PlayerPos") if get_parent() else null
	if spawn == null and get_tree().current_scene:
		spawn = get_tree().current_scene.find_child("PlayerPos", true, false) as Node2D
	if spawn:
		global_position = spawn.global_position

func _on_fragment_granted(fragment_id: StringName) -> void:
	if fragment_id == FragmentManager.ATTACK:
		_has_attack_fragment = true
		_can_attack = _has_attack_fragment

func _on_control_blocked(blocked: bool) -> void:
	_control_blocked = blocked

func _unhandled_input(event: InputEvent) -> void:
	if _control_blocked:
		return
	if event.is_action_pressed("interact") and _current_interactable != null:
		get_viewport().set_input_as_handled()
		try_interact()
	if _can_attack and event.is_action_pressed("attack"):
		#get_viewport().set_input_as_handled()
		print("input attack")
		perform_attack()

###Stamina
func _handle_stamina(delta: float) -> float:
	var wants_to_sprint: bool = not _control_blocked and Input.is_action_pressed("sprint") and !is_still and not _is_hurt
	
	if wants_to_sprint and stamina > 0.0:
		_is_sprinting = true
		stamina = max(0.0, stamina - sprint_cost * delta)
		_is_regenerating_stamina = false
		stamina_regen_timer.stop()
		SignalHub.emit_on_player_stamina_changed(stamina, max_stamina)
		return speed * sprint_speed_multiplier
	else:
		_is_sprinting = false
		# Iniciamos el temporizador de retraso solo si no está corriendo y no estamos regenerando ya
		if stamina < max_stamina and !_is_regenerating_stamina and stamina_regen_timer.is_stopped():
			stamina_regen_timer.start()
		if _is_regenerating_stamina and stamina < max_stamina:
			stamina = min(max_stamina, stamina + stamina_regen_rate * delta)
			SignalHub.emit_on_player_stamina_changed(stamina, max_stamina)
		return speed

func _on_stamina_regen_timer_timeout() -> void:
	_is_regenerating_stamina = true

###Stamina/

### Health
func take_damage(amount: int, knockback_force: float, source_position: Vector2) -> void:
	if _is_hurt or health <= 0:
		return
	
	health = max(0, health - amount)
	SignalHub.emit_on_player_health_changed(health, max_health)
	
	if health <= 0:
		die()
		return
	
	_is_hurt = true
	var knockback_direction: Vector2 = (global_position - source_position).normalized()
	if knockback_direction == Vector2.ZERO:
		knockback_direction = Vector2.LEFT
	
	_knockback_velocity = knockback_direction * knockback_force
	hurt_timer.start(hurt_duration)


func die() -> void:
	hide()
	get_tree().paused = true
	SignalHub.emit_on_game_over(false)


func _on_hurt_timer_timeout() -> void:
	_is_hurt = false
### Health/


func _physics_process(delta: float) -> void:
	_knockback_velocity = _knockback_velocity.lerp(Vector2.ZERO, knockback_friction * delta)
	
	var input: Vector2 = Vector2.ZERO
	if not _is_hurt and not _control_blocked:
		input = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if input != Vector2.ZERO:
		facing_direction = input
		melee_area.rotation = facing_direction.angle()
		if animation_tree:
			animation_tree.set("parameters/idle/blend_position", facing_direction)
			animation_tree.set("parameters/move/blend_position", facing_direction)
		
	var current_speed: float = _handle_stamina(delta)
	
	velocity = (input * current_speed) + _knockback_velocity
	move_and_slide()
	_update_current_interactable()

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
		SignalHub.emit_on_interactable_changed(_current_interactable)

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

func perform_attack() -> void:
	print("perform_attack")
	is_attacking = true
	_can_attack = false
	attack_timer.start()
	
	for area in melee_area.get_overlapping_areas():
		_try_hit_target(area)
	
	attack_sound.play()
	await get_tree().create_timer(0.25).timeout
	is_attacking = false

func _on_attack_timer_timeout() -> void:
	_can_attack = true
	
func _try_hit_target(area: Area2D) -> void:
	print("_try_hit_target")
	if is_attacking and area.get_parent() is PatrolGuard:
		print("area parent was patrol guard")
		area.get_parent().die()
