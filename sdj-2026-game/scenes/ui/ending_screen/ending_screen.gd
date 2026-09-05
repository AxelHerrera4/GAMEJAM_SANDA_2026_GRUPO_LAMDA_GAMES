extends CanvasLayer

@onready var backdrop: ColorRect = $Backdrop
@onready var newspaper: TextureRect = $NewspaperGirl
@onready var title: Label = $ToBeContinued
@onready var credits: Label = $Credits
@onready var hint: Label = $Hint
@onready var animation_player: AnimationPlayer = $AnimationPlayer

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

	if newspaper and newspaper.size != Vector2.ZERO:
		newspaper.pivot_offset = newspaper.size / 2.0

	animation_player.play("ending")


func _unhandled_input(event: InputEvent) -> void:
	if not _playing:
		return
	if not event.is_action_pressed("interact") and not event.is_action_pressed("quit"):
		return

	get_viewport().set_input_as_handled()
	# Permitir salir al menú cuando se hayan mostrado los créditos/hint
	if hint.modulate.a >= 0.8 or not animation_player.is_playing():
		_finish()


func _finish() -> void:
	_playing = false
	_reset()
	get_tree().paused = false
	FragmentManager.clear_all()
	GameManager.load_main()


func _reset() -> void:
	visible = false
	if animation_player:
		animation_player.play("RESET")
