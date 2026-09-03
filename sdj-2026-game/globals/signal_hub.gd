extends Node


signal interactable_changed(interactable: Node)
signal clues_progress(found: int, total: int) # now used on jail
signal all_clues_inspected # now, now used on jail  #maybe for the future for show a clue counter
signal photo_requested(title: String, texture: Texture2D, caption: String)
signal ui_closed
signal shatter_requested(anim_name: StringName)
signal shatter_finished
signal player_control_blocked(blocked: bool)
signal pause_menu_toggled(open: bool)
signal access_points_changed(done: int, total: int)
signal ending_requested
signal hack_requested
signal hack_finished(success: bool)
signal player_health_changed(current_health: int, max_health: int)
signal player_stamina_changed(current_stamina: float, max_stamina: float)
signal game_over(won: bool)
signal fragment_progress(owned: int, total: int)
signal all_fragments_collected

func emit_on_interactable_changed(interactable: Node) -> void:
	interactable_changed.emit(interactable)

func emit_on_clues_progress(found: int, total: int) -> void:
	clues_progress.emit(found, total)

func emit_on_all_clues_inspected() -> void:
	all_clues_inspected.emit()

func emit_on_photo_requested(title: String, texture: Texture2D, caption: String) -> void:
	photo_requested.emit(title, texture, caption)

func emit_on_ui_closed() -> void:
	ui_closed.emit()

func emit_on_shatter_requested(anim_name: StringName = &"shatter") -> void:
	shatter_requested.emit(anim_name)

func emit_on_shatter_finished() -> void:
	shatter_finished.emit()

func emit_on_player_control_blocked(blocked: bool) -> void:
	player_control_blocked.emit(blocked)

func emit_on_pause_menu_toggled(open: bool) -> void:
	pause_menu_toggled.emit(open)

func emit_on_access_points_changed(done: int, total: int) -> void:
	access_points_changed.emit(done, total)

func emit_on_ending_requested() -> void:
	ending_requested.emit()

func emit_on_hack_requested() -> void:
	hack_requested.emit()

func emit_on_hack_finished(success: bool) -> void:
	hack_finished.emit(success)

func emit_on_player_health_changed(current_health: int, max_health: int) -> void:
	player_health_changed.emit(current_health, max_health)

func emit_on_player_stamina_changed(current_stamina: float, max_stamina: float) -> void:
	player_stamina_changed.emit(current_stamina, max_stamina)

func emit_on_game_over(won: bool) -> void:
	game_over.emit(won)

func emit_on_fragment_progress(owned: int, total: int) -> void:
	fragment_progress.emit(owned, total)

func emit_on_all_fragments_collected() -> void:
	all_fragments_collected.emit()
