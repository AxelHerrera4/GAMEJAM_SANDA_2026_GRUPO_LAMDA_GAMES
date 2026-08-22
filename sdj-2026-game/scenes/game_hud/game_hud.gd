extends Control

@onready var health_bar: TextureProgressBar = $MC/HealthBar
@onready var color_rect_game_over: ColorRect = $ColorRectGameOver
@onready var label_game_over: Label = $ColorRectGameOver/LabelGameOver

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		GameManager.load_main()

func _ready() -> void:
	if color_rect_game_over:
		color_rect_game_over.hide()
	SignalHub.player_health_changed.connect(_on_player_health_changed)
	SignalHub.game_over.connect(_on_game_over)

func _on_player_health_changed(current_health: int, max_health: int) -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

func _on_game_over(won: bool) -> void:
	if color_rect_game_over and label_game_over:
		color_rect_game_over.show()
		if won:
			label_game_over.text = "¡Has ganado!"
		else:
			label_game_over.text = "¡Has perdido!"
