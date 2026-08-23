extends CanvasLayer

const FADE_TIME: float = 0.9
const TITLE_HOLD: float = 2.4
const CREDITS_HOLD: float = 1.2

@onready var backdrop: ColorRect = $Backdrop
@onready var title: Label = $ToBeContinued
@onready var credits: Label = $Credits
@onready var hint: Label = $Hint

var _playing: bool = false


func _ready() -> void:
	_reset()
	SignalHub.ending_requested.connect(play)


func is_playing() -> bool:
	return _playing


func play() -> void:
	if _playing:
		return
	_playing = true

	SignalHub.player_control_blocked.emit(true)
	_reset()
	visible = true
	get_tree().paused = true

	await _fade(backdrop, "color:a", 1.0, FADE_TIME)
	await _fade(title, "modulate:a", 1.0, FADE_TIME)
	await get_tree().create_timer(TITLE_HOLD, true).timeout
	await _fade(title, "modulate:a", 0.0, FADE_TIME)

	await _fade(credits, "modulate:a", 1.0, FADE_TIME)
	await get_tree().create_timer(CREDITS_HOLD, true).timeout
	await _fade(hint, "modulate:a", 1.0, 0.6)


func _unhandled_input(event: InputEvent) -> void:
	if not _playing:
		return
	if not event.is_action_pressed("interact") and not event.is_action_pressed("quit"):
		return

	get_viewport().set_input_as_handled()
	if hint.modulate.a >= 0.9:
		_finish()


func _finish() -> void:
	_playing = false
	_reset()
	get_tree().paused = false
	FragmentManager.clear_all()
	GameManager.load_main()


func _reset() -> void:
	visible = false
	backdrop.color = Color(0.0, 0.0, 0.0, 0.0)
	title.modulate.a = 0.0
	credits.modulate.a = 0.0
	hint.modulate.a = 0.0


func _fade(node: CanvasItem, property: String, value: float, time: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(node, property, value, time)
	await tween.finished
