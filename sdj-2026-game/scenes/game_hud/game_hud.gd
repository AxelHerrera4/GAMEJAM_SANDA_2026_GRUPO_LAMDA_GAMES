extends Control

@onready var health_bar: TextureProgressBar = $MC/HealthBar
@onready var stamina_bar: TextureRect = $MC/StaminaBar
@onready var color_rect_game_over: ColorRect = $ColorRectGameOver
@onready var label_game_over: Label = $ColorRectGameOver/LabelGameOver

func _ready() -> void:
	if color_rect_game_over:
		color_rect_game_over.hide()
	SignalHub.player_health_changed.connect(_on_player_health_changed)
	SignalHub.player_stamina_changed.connect(_on_player_stamina_changed)
	SignalHub.game_over.connect(_on_game_over)

func _on_player_health_changed(current_health: int, max_health: int) -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

func _on_player_stamina_changed(current_stamina: float, max_stamina: float) -> void:
	if stamina_bar and max_stamina > 0.0:
		var ratio: float = clampf(current_stamina / max_stamina, 0.0, 1.0)
		var frame_index: int = clampi(roundi((1.0 - ratio) * 11.0), 0, 11)
		var atlas := stamina_bar.texture as AtlasTexture
		if atlas:
			atlas.region = Rect2(frame_index * 32, 0, 32, 32)

func _on_game_over(won: bool) -> void:
	if color_rect_game_over and label_game_over:
		color_rect_game_over.show()
		if won:
			label_game_over.text = "¡Has ganado!"
		else:
			label_game_over.text = "¡Has perdido!"
