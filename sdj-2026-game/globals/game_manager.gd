extends Node

const FADER = preload("res://scenes/fader/fader.tscn")
const LEVEL_BASE = null
const MAIN = preload("uid://5b7hnaeeb4ni")
const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")
const GAME_HUD_SCENE: PackedScene = preload("res://scenes/game_hud/game_hud.tscn")

## Sonidos de puerta. Cada entrada es una lista porque varias tienen variantes
## y se reproducen con un AudioStreamRandomizer para que no suene siempre igual.
const DOOR_OPENING_PATHS: Array[String] = [
	"res://assets/SFX/newSFX/door/door_opening_1.ogg",
	"res://assets/SFX/newSFX/door/door_opening_2.ogg",
	"res://assets/SFX/newSFX/door/door_opening_3.ogg",
]
const DOOR_CLOSING_PATHS: Array[String] = [
	"res://assets/SFX/newSFX/door/door_closing_1.ogg",
]
const DOOR_HANDLE_PATHS: Array[String] = [
	"res://assets/SFX/newSFX/door/door_handle.ogg",
	"res://assets/SFX/newSFX/door/door_handle_2.ogg",
]
## Los .ogg de puerta vienen bajos de nivel; se suben al reproducirlos.
const DOOR_SFX_VOLUME_DB: float = 6.0
const DOOR_LOCKED_PATHS: Array[String] = [
	"res://assets/SFX/newSFX/door/door_locked_1.ogg",
	"res://assets/SFX/newSFX/door/door_locked_2.ogg",
	"res://assets/SFX/newSFX/door/door_locked_3.ogg",
]

var fader: Fader = null
var next_scene: Variant = null
var _action_during_black: Callable = Callable()

var _open_sfx: AudioStreamPlayer
var _close_sfx: AudioStreamPlayer
var _handle_sfx: AudioStreamPlayer
var _locked_sfx: AudioStreamPlayer
## True cuando el cambio de escena viene de cruzar una puerta: solo entonces
## suenan el door_opening al salir y el door_closing al entrar a la habitacion.
var _door_transition: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	fader = FADER.instantiate()
	add_child(fader)

	_open_sfx = _make_sfx_player(DOOR_OPENING_PATHS)
	_close_sfx = _make_sfx_player(DOOR_CLOSING_PATHS)
	_handle_sfx = _make_sfx_player(DOOR_HANDLE_PATHS)
	_locked_sfx = _make_sfx_player(DOOR_LOCKED_PATHS)


## Crea un reproductor cuyo stream mezcla al azar todas las variantes dadas.
func _make_sfx_player(paths: Array[String]) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = make_randomizer(paths)
	player.volume_db = DOOR_SFX_VOLUME_DB
	add_child(player)
	return player


## Helper compartido: junta varios .ogg en un AudioStreamRandomizer que evita
## repetir la misma variante dos veces seguidas.
static func make_randomizer(paths: Array[String]) -> AudioStreamRandomizer:
	var randomizer := AudioStreamRandomizer.new()
	randomizer.playback_mode = AudioStreamRandomizer.PLAYBACK_RANDOM_NO_REPEATS
	for path in paths:
		var stream: AudioStream = load(path) as AudioStream
		if stream == null:
			push_warning("GameManager: no se pudo cargar el SFX '%s'." % path)
			continue
		randomizer.add_stream(randomizer.streams_count, stream)
	return randomizer


func _play_sfx(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	var randomizer: AudioStreamRandomizer = player.stream as AudioStreamRandomizer
	if randomizer == null or randomizer.streams_count == 0:
		return
	player.play()


## Cerradura bloqueada: el jugador intenta abrir una puerta que no cede.
func play_locked_door() -> void:
	_play_sfx(_locked_sfx)


## Puerta abriendose, al salir de la habitacion actual.
func play_open_door() -> void:
	_play_sfx(_open_sfx)


## Puerta cerrandose detras del jugador, ya dentro de la habitacion nueva.
func play_close_door() -> void:
	_play_sfx(_close_sfx)


## Manija: suena en el momento en que la puerta se acciona y cede.
func play_door_handle() -> void:
	_play_sfx(_handle_sfx)


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
		if _door_transition:
			_door_transition = false
			play_close_door()
		SignalHub.emit_on_player_control_blocked(false)
	else:
		_door_transition = false
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


## through_door: la transicion es el jugador cruzando una puerta, asi que suena
## la puerta abriendose ahora y cerrandose al llegar a la habitacion nueva.
func start_transition(to_scene: Variant, through_door: bool = false) -> void:
	next_scene = to_scene
	_door_transition = through_door
	if through_door:
		play_open_door()
	SignalHub.emit_on_player_control_blocked(true)
	fade()


func change_scene(scene: Variant, through_door: bool = true) -> void:
	if scene == null:
		push_warning("GameManager: Intento de cambiar a escena nula.")
		return
	if scene is String and (scene as String).is_empty():
		push_warning("GameManager: Intento de cambiar a ruta vacía.")
		return
	start_transition(scene, through_door)


func change_scene_to_packed(scene: PackedScene, through_door: bool = true) -> void:
	if scene == null:
		push_warning("GameManager: Intento de cambiar a PackedScene nula.")
		return
	start_transition(scene, through_door)


func change_scene_to_file(path: String, through_door: bool = true) -> void:
	if path.is_empty():
		push_warning("GameManager: Intento de cambiar a ruta vacía.")
		return
	start_transition(path, through_door)


func load_level() -> void:
	start_transition(LEVEL_BASE)


func load_main() -> void:
	start_transition(MAIN)
