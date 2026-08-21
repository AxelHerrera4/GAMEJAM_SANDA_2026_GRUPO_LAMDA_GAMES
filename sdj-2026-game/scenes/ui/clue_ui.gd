extends CanvasLayer


const TOAST_TIME: float = 3.5
const BLACKOUT_IN: float = 0.28
const BLACKOUT_HOLD: float = 0.7
const BLACKOUT_OUT: float = 0.55

@onready var interact_prompt: Label = $InteractPrompt
@onready var photo_panel: Panel = $PhotoPanel
@onready var photo_title: Label = $PhotoPanel/Margin/VBox/PhotoTitle
@onready var photo_image: TextureRect = $PhotoPanel/Margin/VBox/PhotoFrame/PhotoImage
@onready var photo_caption: Label = $PhotoPanel/Margin/VBox/PhotoCaption
@onready var dialogue_box: Panel = $DialogueBox
@onready var dialogue_speaker: Label = $DialogueBox/Margin/VBox/Speaker
@onready var dialogue_text: Label = $DialogueBox/Margin/VBox/DialogueText
@onready var hack_minigame: HackMinigame = $HackMinigame
@onready var fragment_toast: Panel = $FragmentToast
@onready var toast_name: Label = $FragmentToast/Margin/VBox/ToastName
@onready var blackout: ColorRect = $Blackout
@onready var paper_sfx: AudioStreamPlayer = $PaperSfx
@onready var glass_sfx: AudioStreamPlayer = $GlassSfx

var _input_guard: bool = false
var _current_interactable: Node = null


func _ready() -> void:
	photo_panel.hide()
	dialogue_box.hide()
	hack_minigame.hide()
	fragment_toast.hide()
	interact_prompt.hide()
	blackout.hide()
	blackout.color = Color(0.0, 0.0, 0.0, 0.0)

	SignalHub.interactable_changed.connect(_on_interactable_changed)
	SignalHub.photo_requested.connect(_on_photo_requested)
	SignalHub.dialogue_requested.connect(_on_dialogue_requested)
	SignalHub.hack_requested.connect(_on_hack_requested)
	SignalHub.shatter_requested.connect(_on_shatter_requested)
	FragmentManager.fragment_granted.connect(_on_fragment_granted)
	hack_minigame.finished.connect(_on_hack_minigame_finished)


func _process(_delta: float) -> void:
	_input_guard = false


func _unhandled_input(event: InputEvent) -> void:
	if dialogue_box.visible and not _input_guard and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		close_ui()


func is_ui_open() -> bool:
	return photo_panel.visible or dialogue_box.visible or hack_minigame.visible


func close_ui() -> void:
	if not is_ui_open():
		return
	photo_panel.hide()
	dialogue_box.hide()
	get_tree().paused = false
	_refresh_prompt()
	SignalHub.ui_closed.emit()


func _open_ui() -> void:
	_input_guard = true
	interact_prompt.hide()
	get_tree().paused = true


func _on_photo_requested(title: String, texture: Texture2D, caption: String) -> void:
	photo_title.text = title
	photo_image.texture = texture
	photo_caption.text = caption
	photo_caption.visible = not caption.is_empty()
	dialogue_box.hide()
	hack_minigame.hide()
	photo_panel.show()
	paper_sfx.play()
	_open_ui()


func _on_dialogue_requested(speaker: String, text: String) -> void:
	dialogue_speaker.text = speaker
	dialogue_speaker.visible = not speaker.is_empty()
	dialogue_text.text = text
	photo_panel.hide()
	hack_minigame.hide()
	dialogue_box.show()
	_open_ui()


func _on_hack_requested() -> void:
	photo_panel.hide()
	dialogue_box.hide()
	hack_minigame.start()
	hack_minigame.show()
	_open_ui()


func _on_hack_minigame_finished(success: bool) -> void:
	hack_minigame.hide()
	get_tree().paused = false
	_refresh_prompt()
	SignalHub.hack_finished.emit(success)


func _on_close_button_pressed() -> void:
	close_ui()


func _on_interactable_changed(interactable: Node) -> void:
	_current_interactable = interactable
	_refresh_prompt()


func _refresh_prompt() -> void:
	if _current_interactable == null or not is_instance_valid(_current_interactable) or is_ui_open():
		interact_prompt.hide()
		return

	var label: String = "Interactuar"
	if _current_interactable.has_method("get_prompt_text"):
		label = _current_interactable.get_prompt_text()
	interact_prompt.text = "[F] %s" % label
	interact_prompt.show()


func _on_shatter_requested() -> void:
	await play_shatter()
	SignalHub.shatter_finished.emit()


func _on_fragment_granted(fragment_id: StringName) -> void:
	while is_ui_open():
		await SignalHub.ui_closed

	toast_name.text = FragmentManager.get_display_name(fragment_id)
	fragment_toast.show()
	get_tree().create_timer(TOAST_TIME, true).timeout.connect(fragment_toast.hide)


func play_shatter() -> void:
	get_tree().paused = true
	blackout.color = Color(0.0, 0.0, 0.0, 0.0)
	blackout.show()

	var fade_in: Tween = create_tween()
	fade_in.tween_property(blackout, "color:a", 1.0, BLACKOUT_IN)
	await fade_in.finished

	if glass_sfx.stream != null:
		glass_sfx.play()

	await get_tree().create_timer(BLACKOUT_HOLD, true).timeout

	var fade_out: Tween = create_tween()
	fade_out.tween_property(blackout, "color:a", 0.0, BLACKOUT_OUT)
	await fade_out.finished

	blackout.hide()
	get_tree().paused = false
