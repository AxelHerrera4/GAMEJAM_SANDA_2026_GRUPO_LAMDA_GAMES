extends Node


@warning_ignore("unused_signal")
signal interactable_changed(interactable: Node)


@warning_ignore("unused_signal")
signal clues_progress(found: int, total: int)
@warning_ignore("unused_signal")
signal all_clues_inspected


@warning_ignore("unused_signal")
signal photo_requested(title: String, texture: Texture2D, caption: String)
@warning_ignore("unused_signal")
signal dialogue_requested(speaker: String, text: String)
@warning_ignore("unused_signal")
signal ui_closed
@warning_ignore("unused_signal")
signal shatter_requested
@warning_ignore("unused_signal")
signal shatter_finished


@warning_ignore("unused_signal")
signal player_control_blocked(blocked: bool)
@warning_ignore("unused_signal")
signal pause_menu_toggled(open: bool)


@warning_ignore("unused_signal")
signal access_points_changed(done: int, total: int)


@warning_ignore("unused_signal")
signal hack_requested

func emit_on_hack_requested() -> void:
	hack_requested.emit()

@warning_ignore("unused_signal")
signal hack_finished(success: bool)

func emit_on_hack_finished(success: bool) -> void:
	hack_finished.emit(success)
	
signal player_health_changed(current_health: int, max_health: int)
signal player_stamina_changed(current_stamina: float, max_stamina: float)
signal game_over(won: bool)

func emit_on_game_over(won: bool) -> void:
	game_over.emit(won)

func emit_on_player_health_changed(current_health: int, max_health: int) -> void:
	player_health_changed.emit(current_health, max_health)

func emit_on_player_stamina_changed(current_stamina: float, max_stamina: float) -> void:
	player_stamina_changed.emit(current_stamina, max_stamina)
