extends Node

const OPEN_DOOR_PATH: String = "res://assets/SFX/Things/OpenDoor.ogg"
const DOOR_CLOSE_PATH: String = "res://assets/SFX/Things/DoorClose.ogg"

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const GAME_HUD_SCENE: PackedScene = preload("res://scenes/game_hud/game_hud.tscn")

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


func fade_in_out(action_during_black: Callable = Callable(), hold_time: float = BLACK_HOLD) -> void:
	if _busy:
		return
	_busy = true

	SignalHub.emit_on_player_control_blocked(true)

	_fade.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade.show()

	var fade_in: Tween = create_tween()
	fade_in.tween_property(_fade, "color:a", 1.0, FADE_IN_TIME)
	await fade_in.finished

	if action_during_black.is_valid():
		action_during_black.call()

	if hold_time > 0.0:
		await get_tree().create_timer(hold_time, true).timeout

	SignalHub.emit_on_player_control_blocked(false)

	var fade_out: Tween = create_tween()
	fade_out.tween_property(_fade, "color:a", 0.0, FADE_OUT_TIME)
	await fade_out.finished

	_fade.hide()
	_busy = false


func change_scene(path: String) -> void:
	if _busy:
		return
	_busy = true

	SignalHub.emit_on_player_control_blocked(true)

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

	_setup_scene_entities(get_tree().current_scene)

	get_tree().paused = false
	SignalHub.emit_on_player_control_blocked(false)


	var fade_out: Tween = create_tween()
	fade_out.tween_property(_fade, "color:a", 0.0, FADE_OUT_TIME)
	await fade_out.finished

	_fade.hide()
	_busy = false


func _setup_scene_entities(scene: Node) -> void:
	if not scene:
		return

	# Si la escena es un menú o pantalla de final, no spawnear HUD ni Player
	if scene is Control:
		return

	# 1. Asegurar GameHud
	var existing_hud: Node = scene.find_child("GameHud", true, false)
	if existing_hud == null:
		var canvas_layer := CanvasLayer.new()
		canvas_layer.name = "HudCanvasLayer"
		var hud := GAME_HUD_SCENE.instantiate()
		canvas_layer.add_child(hud)
		scene.add_child(canvas_layer)

	# 2. Asegurar Player
	var existing_player: Player = scene.find_child("Player", true, false) as Player
	if existing_player == null:
		var player_node: Node = get_tree().get_first_node_in_group("player")
		if player_node is Player:
			existing_player = player_node

	var spawn_pos: Marker2D = scene.find_child("PlayerPos", true, false) as Marker2D
	if spawn_pos == null:
		spawn_pos = scene.get_node_or_null("PlayerPos") as Marker2D

	if existing_player == null:
		var new_player := PLAYER_SCENE.instantiate() as Player
		if spawn_pos:
			new_player.global_position = spawn_pos.global_position
		scene.add_child(new_player)
	else:
		if spawn_pos:
			existing_player.global_position = spawn_pos.global_position
