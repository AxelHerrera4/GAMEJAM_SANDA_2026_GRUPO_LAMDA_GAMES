class_name HackMinigame
extends Panel


signal finished(success: bool)

const INTRO_TIME: float = 0.45
const OUTRO_TIME: float = 0.25
const SOLVED_DELAY: float = 0.7

const HINT_TEXT: String = "Conecta cada cable con su terminal."

@onready var board: HackBoard = $Margin/VBox/Board
@onready var status: Label = $Margin/VBox/Status
@onready var cancel_button: Button = $Margin/VBox/CancelButton
@onready var show_sfx: AudioStreamPlayer = $ShowSfx
@onready var loop_sfx: AudioStreamPlayer = $LoopSfx
@onready var solve_sfx: AudioStreamPlayer = $SolveSfx
@onready var fail_sfx: AudioStreamPlayer = $FailSfx

var _rest_y: float = 0.0


func _ready() -> void:
	board.solved.connect(_on_solved)
	board.wire_connected.connect(_on_wire_connected)
	board.wire_failed.connect(_on_wire_failed)
	_make_loopable(loop_sfx.stream)


func _make_loopable(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD


func start() -> void:
	board.reset()
	status.text = HINT_TEXT
	cancel_button.disabled = false
	_rest_y = position.y
	_play_intro()

	show_sfx.play()
	loop_sfx.play()


func _play_intro() -> void:
	position.y = _rest_y + get_viewport_rect().size.y
	modulate.a = 0.0

	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", _rest_y, INTRO_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, INTRO_TIME * 0.6)


func _play_outro() -> void:
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", _rest_y + get_viewport_rect().size.y, OUTRO_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "modulate:a", 0.0, OUTRO_TIME)
	await tween.finished

	position.y = _rest_y
	modulate.a = 1.0


func _on_wire_connected(connected: int, total: int) -> void:
	status.text = "Circuitos enlazados: %d/%d" % [connected, total]


func _on_wire_failed() -> void:
	status.text = "Ese cable no encaja ahi."
	fail_sfx.play()


func _on_solved() -> void:
	status.text = "Cerradura anulada."
	cancel_button.disabled = true
	loop_sfx.stop()
	solve_sfx.play()
	await get_tree().create_timer(SOLVED_DELAY, true).timeout
	await _play_outro()
	finished.emit(true)


func force_close() -> void:
	loop_sfx.stop()
	position.y = _rest_y
	modulate.a = 1.0
	finished.emit(false)


func _on_cancel_button_pressed() -> void:
	cancel_button.disabled = true
	loop_sfx.stop()
	await _play_outro()
	finished.emit(false)
