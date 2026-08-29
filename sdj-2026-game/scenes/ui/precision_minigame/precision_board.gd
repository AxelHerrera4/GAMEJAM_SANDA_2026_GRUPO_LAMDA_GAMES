class_name PrecisionBoard
extends Control

signal hit(count: int, required: int)
signal missed(remaining: int)
signal failed
signal solved

@export var cursor_speed: float = 400.0        # px/seg
@export var zone_width_start: float = 120.0
@export var zone_shrink_factor: float = 0.65    # se reduce cada acierto
@export var hits_required: int = 3
@export var max_misses: int = 3

@export_group("Pista")
@export_range(0.0, 0.5) var track_left_fraction: float = 0.10
@export_range(0.0, 0.5) var track_right_fraction: float = 0.09
@export_range(0.0, 1.0) var track_center_y_fraction: float = 0.196

@onready var background: TextureRect = $Background
@onready var solved_label: Label = $SolvedLabel

var _cursor_x: float = 0.0
var _direction: int = 1
var _zone_x: float = 0.0
var _zone_width: float = 0.0
var _hits: int = 0
var _misses: int = 0


func _track_bounds() -> Vector3:
	var bg_pos: Vector2 = Vector2.ZERO
	var bg_size: Vector2 = size
	if background != null:
		bg_pos = background.position
		bg_size = background.size
	var left: float = bg_pos.x + bg_size.x * track_left_fraction
	var right: float = bg_pos.x + bg_size.x * (1.0 - track_right_fraction)
	var center_y: float = bg_pos.y + bg_size.y * track_center_y_fraction
	return Vector3(left, right - left, center_y)


func reset() -> void:
	var bounds: Vector3 = _track_bounds()
	_cursor_x = bounds.x
	_direction = 1
	_zone_width = zone_width_start
	_hits = 0
	_misses = 0
	solved_label.hide()
	_pick_new_zone()


func _pick_new_zone() -> void:
	var bounds: Vector3 = _track_bounds()
	var track_length: float = bounds.y
	_zone_x = bounds.x + randf() * maxf(track_length - _zone_width, 0.0)


func _process(delta: float) -> void:
	var bounds: Vector3 = _track_bounds()
	var left: float = bounds.x
	var right: float = bounds.x + bounds.y
	_cursor_x += _direction * cursor_speed * delta
	if _cursor_x >= right:
		_cursor_x = right
		_direction = -1
	elif _cursor_x <= left:
		_cursor_x = left
		_direction = 1
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_accept"):  # o una acción custom "interact"
		try_hit()


func try_hit() -> void:
	if _cursor_x >= _zone_x and _cursor_x <= _zone_x + _zone_width:
		_hits += 1
		hit.emit(_hits, hits_required)
		if _hits >= hits_required:
			solved_label.show()
			solved.emit()
			return
		_zone_width *= zone_shrink_factor
		_pick_new_zone()
	else:
		_hits = 0
		_misses += 1
		var remaining: int = max_misses - _misses
		missed.emit(remaining)
		if _misses >= max_misses:
			failed.emit()


func _draw() -> void:
	var bounds: Vector3 = _track_bounds()
	var left: float = bounds.x
	var length: float = bounds.y
	var bar_y: float = bounds.z
	draw_line(Vector2(left, bar_y), Vector2(left + length, bar_y), Color.GRAY, 6.0)
	draw_rect(Rect2(_zone_x, bar_y - 4.0, _zone_width, 8.0), Color.GREEN)
	draw_line(Vector2(_cursor_x, bar_y - 14.0), Vector2(_cursor_x, bar_y + 14.0), Color.WHITE, 3.0)
