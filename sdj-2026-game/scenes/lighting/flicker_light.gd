class_name FlickerLight
extends PointLight2D

enum Phase { STEADY, DIM, LIT }

@export var flicker_enabled: bool = true

@export_group("Luz estable")
@export var steady_time_min: float = 3.0
@export var steady_time_max: float = 9.0

@export_group("Rafaga de parpadeo")
@export var blinks_min: int = 2
@export var blinks_max: int = 5
@export var blink_time_min: float = 0.04
@export var blink_time_max: float = 0.14
@export var dim_ratio_min: float = 0.05
@export var dim_ratio_max: float = 0.45

@export_group("Arranque")
@export var start_delay_min: float = 0.0
@export var start_delay_max: float = 6.0

var _rng := RandomNumberGenerator.new()
var _timer: Timer
var _base_energy: float = 1.0
var _phase: Phase = Phase.STEADY
var _blinks_left: int = 0


func _ready() -> void:
	_base_energy = energy
	_rng.randomize()

	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)

	if flicker_enabled:
		_timer.start(_rng.randf_range(start_delay_min, start_delay_max))


func set_flicker_enabled(value: bool) -> void:
	flicker_enabled = value
	if flicker_enabled:
		if _timer.is_stopped():
			_phase = Phase.STEADY
			_timer.start(_random_steady_time())
	else:
		_timer.stop()
		energy = _base_energy


func get_base_energy() -> float:
	return _base_energy


func _on_timer_timeout() -> void:
	match _phase:
		Phase.STEADY:
			_blinks_left = _rng.randi_range(blinks_min, blinks_max)
			_go_dim()

		Phase.LIT:
			_go_dim()

		Phase.DIM:
			energy = _base_energy
			_blinks_left -= 1
			if _blinks_left > 0:
				_phase = Phase.LIT
				_timer.start(_random_blink_time())
			else:
				_phase = Phase.STEADY
				_timer.start(_random_steady_time())


func _go_dim() -> void:
	_phase = Phase.DIM
	energy = _base_energy * _rng.randf_range(dim_ratio_min, dim_ratio_max)
	_timer.start(_random_blink_time())


func _random_blink_time() -> float:
	return _rng.randf_range(blink_time_min, blink_time_max)


func _random_steady_time() -> float:
	return _rng.randf_range(steady_time_min, steady_time_max)
