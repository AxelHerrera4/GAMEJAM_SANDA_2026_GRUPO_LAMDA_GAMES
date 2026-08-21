class_name HackBoard
extends Control


signal solved
signal wire_connected(connected: int, total: int)
signal wire_failed

@export var wire_colors: Array[Color] = [
	Color(0.6431373, 0.2784314, 0.24705882),
	Color(0.6901961, 0.5647059, 0.28235295),
	Color(0.3019608, 0.5019608, 0.4627451),
	Color(0.44313726, 0.3764706, 0.5372549),
]

@export var plug_radius: float = 13.0
@export var grab_radius: float = 24.0
@export var wire_width: float = 6.0
@export var side_margin: float = 36.0

const BG_COLOR: Color = Color(0.031372551, 0.03529412, 0.031372551, 1)
const BG_BORDER: Color = Color(0.13725491, 0.14509805, 0.13725491, 1)
const RAIL_COLOR: Color = Color(0.09019608, 0.09411765, 0.09019608, 1)

var _right_order: Array[int] = []
var _links: Dictionary = {}
var _dragging: int = -1
var _drag_pos: Vector2 = Vector2.ZERO


func _ready() -> void:
	reset()


func reset() -> void:
	_links.clear()
	_dragging = -1

	_right_order.clear()
	for i in wire_colors.size():
		_right_order.append(i)

	for _attempt in 20:
		_right_order.shuffle()
		if not _has_straight_wire():
			break

	queue_redraw()


func is_solved() -> bool:
	return not wire_colors.is_empty() and _links.size() == wire_colors.size()


func _has_straight_wire() -> bool:
	for slot in _right_order.size():
		if _right_order[slot] == slot:
			return true
	return false


func _row_y(index: int) -> float:
	var count: int = maxi(wire_colors.size(), 1)
	var step: float = size.y / float(count)
	return step * (index + 0.5)


func _left_pos(plug: int) -> Vector2:
	return Vector2(side_margin, _row_y(plug))


func _right_pos(slot: int) -> Vector2:
	return Vector2(size.x - side_margin, _row_y(slot))


func _plug_at(point: Vector2) -> int:
	var best: int = -1
	var best_dist: float = grab_radius
	for plug in wire_colors.size():
		if _links.has(plug):
			continue
		var dist: float = point.distance_to(_left_pos(plug))
		if dist <= best_dist:
			best_dist = dist
			best = plug
	return best


func _slot_at(point: Vector2) -> int:
	var taken: Array = _links.values()
	var best: int = -1
	var best_dist: float = grab_radius
	for slot in _right_order.size():
		if taken.has(slot):
			continue
		var dist: float = point.distance_to(_right_pos(slot))
		if dist <= best_dist:
			best_dist = dist
			best = slot
	return best


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			_dragging = _plug_at(button.position)
			_drag_pos = button.position
		else:
			_release_at(button.position)
		queue_redraw()
		return

	var motion := event as InputEventMouseMotion
	if motion != null and _dragging >= 0:
		_drag_pos = motion.position
		queue_redraw()


func _release_at(point: Vector2) -> void:
	if _dragging < 0:
		return

	var plug: int = _dragging
	_dragging = -1

	var slot: int = _slot_at(point)
	if slot >= 0 and _right_order[slot] == plug:
		_links[plug] = slot
		wire_connected.emit(_links.size(), wire_colors.size())
		if is_solved():
			solved.emit()
	elif slot >= 0:
		wire_failed.emit()


func _draw() -> void:
	var board := Rect2(Vector2.ZERO, size)
	draw_rect(board, BG_COLOR)
	draw_rect(board, BG_BORDER, false, 2.0)

	for i in wire_colors.size():
		draw_line(_left_pos(i), Vector2(size.x - side_margin, _row_y(i)), RAIL_COLOR, 2.0, true)

	for plug in _links.keys():
		var color: Color = wire_colors[plug]
		draw_line(_left_pos(plug), _right_pos(_links[plug]), color, wire_width, true)

	if _dragging >= 0:
		var color: Color = wire_colors[_dragging]
		draw_line(_left_pos(_dragging), _drag_pos, color, wire_width, true)
		draw_circle(_drag_pos, plug_radius * 0.5, color)

	for slot in _right_order.size():
		var color: Color = wire_colors[_right_order[slot]]
		var center: Vector2 = _right_pos(slot)
		var taken: bool = _links.values().has(slot)
		if taken:
			draw_circle(center, plug_radius, color)
		else:
			draw_circle(center, plug_radius, color.darkened(0.75))
		draw_arc(center, plug_radius, 0.0, TAU, 24, color, 3.0, true)

	for plug in wire_colors.size():
		var color: Color = wire_colors[plug]
		var center: Vector2 = _left_pos(plug)
		draw_circle(center, plug_radius, color)
		draw_circle(center, plug_radius * 0.4, color.darkened(0.6))
