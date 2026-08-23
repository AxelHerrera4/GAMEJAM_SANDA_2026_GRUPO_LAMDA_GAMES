extends Node

const OPEN_DOOR_PATH: String = "res://assets/SFX/Things/OpenDoor.ogg"
const DOOR_CLOSE_PATH: String = "res://assets/SFX/Things/DoorClose.ogg"

const FADE_IN_TIME: float = 0.4
const BLACK_HOLD: float = 0.35
const FADE_OUT_TIME: float = 0.5

var _layer: CanvasLayer
var _fade: ColorRect
var _open_sfx: AudioStreamPlayer
var _close_sfx: AudioStreamPlayer
var _busy: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_layer = CanvasLayer.new()
	_layer.layer = 128
	add_child(_layer)

	_fade = ColorRect.new()
	_fade.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_STOP
	_fade.hide()
	_layer.add_child(_fade)

	_open_sfx = AudioStreamPlayer.new()
	_open_sfx.stream = load(OPEN_DOOR_PATH)
	add_child(_open_sfx)

	_close_sfx = AudioStreamPlayer.new()
	_close_sfx.stream = load(DOOR_CLOSE_PATH)
	add_child(_close_sfx)


func is_busy() -> bool:
	return _busy


func play_locked_door() -> void:
	if _close_sfx.stream != null:
		_close_sfx.play()


func play_open_door() -> void:
	if _open_sfx.stream != null:
		_open_sfx.play()


func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true

	SignalHub.player_control_blocked.emit(true)

	_fade.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade.show()

	var fade_in: Tween = create_tween()
	fade_in.tween_property(_fade, "color:a", 1.0, FADE_IN_TIME)
	await fade_in.finished

	play_open_door()
	await get_tree().create_timer(BLACK_HOLD, true).timeout

	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame

	get_tree().paused = false
	SignalHub.player_control_blocked.emit(false)

	var fade_out: Tween = create_tween()
	fade_out.tween_property(_fade, "color:a", 0.0, FADE_OUT_TIME)
	await fade_out.finished

	_fade.hide()
	_busy = false
