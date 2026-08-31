extends Node

const FADER = preload("res://scenes/fader/fader.tscn")
const LEVEL_BASE = null
const MAIN = preload("uid://5b7hnaeeb4ni")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const GAME_HUD_SCENE: PackedScene = preload("res://scenes/game_hud/game_hud.tscn")

const OPEN_DOOR_PATH: String = "res://assets/SFX/Things/OpenDoor.ogg"
const DOOR_CLOSE_PATH: String = "res://assets/SFX/Things/DoorClose.ogg"

var fader: Fader = null
var next_scene: Variant = null
var _action_during_black: Callable = Callable()

var _open_sfx: AudioStreamPlayer
var _close_sfx: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	fader = FADER.instantiate()
	add_child(fader)

	_open_sfx = AudioStreamPlayer.new()
	_open_sfx.stream = load(OPEN_DOOR_PATH)
	add_child(_open_sfx)

	_close_sfx = AudioStreamPlayer.new()
	_close_sfx.stream = load(DOOR_CLOSE_PATH)
	add_child(_close_sfx)


func play_locked_door() -> void:
	if _close_sfx and _close_sfx.stream != null:
		_close_sfx.play()


func play_open_door() -> void:
	if _open_sfx and _open_sfx.stream != null:
		_open_sfx.play()


func fade() -> void:
	if fader:
		fader.fade()


func fade_in_out(action_during_black: Callable = Callable()) -> void:
	_action_during_black = action_during_black
	SignalHub.emit_on_player_control_blocked(true)
	fade()


func change_to_next_scene() -> void:
	if _action_during_black.is_valid():
		_action_during_black.call()
		_action_during_black = Callable()

	if next_scene != null:
		var scene_to_change: Variant = next_scene
		next_scene = null

		if scene_to_change is PackedScene:
			get_tree().change_scene_to_packed(scene_to_change)
		elif scene_to_change is String:
			get_tree().change_scene_to_file(scene_to_change)
		else:
			push_error("GameManager: La escena '%s' no es válida." % str(scene_to_change))
			SignalHub.emit_on_player_control_blocked(false)
			return

		await get_tree().process_frame
		await get_tree().process_frame

		_setup_scene_entities(get_tree().current_scene)
		get_tree().paused = false
		SignalHub.emit_on_player_control_blocked(false)
	else:
		SignalHub.emit_on_player_control_blocked(false)


func _setup_scene_entities(scene: Node) -> void:
	if not scene:
		return
		
	if scene is Control:
		return

	var existing_hud: Node = scene.find_child("GameHud", true, false)
	if existing_hud == null:
		var canvas_layer := CanvasLayer.new()
		canvas_layer.name = "HudCanvasLayer"
		var hud := GAME_HUD_SCENE.instantiate()
		canvas_layer.add_child(hud)
		scene.add_child(canvas_layer)

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


func start_transition(to_scene: Variant) -> void:
	next_scene = to_scene
	SignalHub.emit_on_player_control_blocked(true)
	fade()


func change_scene(scene: Variant) -> void:
	if scene == null:
		push_warning("GameManager: Intento de cambiar a escena nula.")
		return
	if scene is String and (scene as String).is_empty():
		push_warning("GameManager: Intento de cambiar a ruta vacía.")
		return
	start_transition(scene)


func change_scene_to_packed(scene: PackedScene) -> void:
	if scene == null:
		push_warning("GameManager: Intento de cambiar a PackedScene nula.")
		return
	start_transition(scene)


func change_scene_to_file(path: String) -> void:
	if path.is_empty():
		push_warning("GameManager: Intento de cambiar a ruta vacía.")
		return
	start_transition(path)


func load_level() -> void:
	start_transition(LEVEL_BASE)


func load_main() -> void:
	start_transition(MAIN)
