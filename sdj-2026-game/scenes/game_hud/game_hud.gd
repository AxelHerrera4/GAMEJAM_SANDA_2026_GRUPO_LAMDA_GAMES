extends Control

@onready var health_bar: TextureProgressBar = $MC/HealthBar
@onready var stamina_bar: TextureRect = $MC/StaminaBar
@onready var color_rect_game_over: ColorRect = $ColorRectGameOver
@onready var label_game_over: Label = $ColorRectGameOver/LabelGameOver
@onready var fragment_label: Label = $MC/FragmentLabel

var _faces: Array[CanvasItem] = []

func _ready() -> void:
	if color_rect_game_over:
		color_rect_game_over.hide()
	SignalHub.player_health_changed.connect(_on_player_health_changed)
	SignalHub.player_stamina_changed.connect(_on_player_stamina_changed)
	SignalHub.game_over.connect(_on_game_over)
	SignalHub.fragment_progress.connect(_on_fragment_progress)
	_on_fragment_progress(FragmentManager.get_owned().size(), FragmentManager.CATALOG.size())
	_collect_faces()
	_update_face()

func _collect_faces() -> void:
	_faces.clear()

	var found: Dictionary = {}
	for node in find_children("*", "CanvasItem", true, false):
		var lower_name: String = String(node.name).to_lower()
		if not lower_name.begins_with("faceui"):
			continue
		var suffix: String = lower_name.substr(6)
		if suffix.is_valid_int():
			found[suffix.to_int()] = node

	var numbers: Array = found.keys()
	numbers.sort()
	for number in numbers:
		_faces.append(found[number])

	if _faces.is_empty():
		push_warning("GameHud: no encontre ningun nodo FaceUi1, FaceUi2, ...")

func _update_face() -> void:
	if _faces.is_empty():
		return
	var owned: int = clampi(FragmentManager.get_owned().size(), 0, _faces.size() - 1)
	for i in _faces.size():
		_faces[i].visible = (i == owned)

func _on_fragment_progress(owned: int, total: int) -> void:
	if fragment_label:
		fragment_label.text = "Fragmentos: %d/%d" % [owned, total]
	_update_face()

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
