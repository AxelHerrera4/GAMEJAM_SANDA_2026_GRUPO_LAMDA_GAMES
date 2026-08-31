extends CanvasLayer

const MUSIC_BUS: StringName = &"Music"
@onready var resume_button: Button = $Panel/Margin/VBox/ResumeButton
@onready var music_slider: HSlider = $Panel/Margin/VBox/MusicSlider
@onready var music_value: Label = $Panel/Margin/VBox/MusicHeader/MusicValue
@onready var quit_button: Button = $Panel/Margin/VBox/QuitButton

var _open: bool = false
var _was_paused: bool = false
var _music_bus: int = -1


func _ready() -> void:
	_music_bus = AudioServer.get_bus_index(MUSIC_BUS)
	visible = false

	music_slider.value_changed.connect(_on_music_slider_changed)
	resume_button.pressed.connect(close_menu)
	quit_button.pressed.connect(_on_quit_pressed)

	if _music_bus >= 0:
		music_slider.set_value_no_signal(db_to_linear(AudioServer.get_bus_volume_db(_music_bus)))
	_update_music_label(music_slider.value)


func is_open() -> bool:
	return _open


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("quit"):
		return
	if not _open and not _can_open():
		return

	get_viewport().set_input_as_handled()
	if _open:
		close_menu()
	else:
		open_menu()


func open_menu() -> void:
	if _open:
		return
	_open = true
	_was_paused = get_tree().paused
	get_tree().paused = true
	visible = true
	SignalHub.emit_on_pause_menu_toggled(true)
	resume_button.grab_focus()


func close_menu() -> void:
	if not _open:
		return
	_open = false
	visible = false
	get_tree().paused = _was_paused
	SignalHub.emit_on_pause_menu_toggled(false)


func _can_open() -> bool:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return false
	return scene.scene_file_path != GameManager.MAIN.resource_path


func _on_music_slider_changed(value: float) -> void:
	_update_music_label(value)
	if _music_bus < 0:
		return
	AudioServer.set_bus_mute(_music_bus, value <= 0.001)
	AudioServer.set_bus_volume_db(_music_bus, linear_to_db(maxf(value, 0.0001)))


func _update_music_label(value: float) -> void:
	music_value.text = "%d%%" % roundi(value * 100.0)


func _on_quit_pressed() -> void:
	_open = false
	visible = false
	get_tree().paused = false
	SignalHub.emit_on_pause_menu_toggled(false)
	GameManager.load_main()
