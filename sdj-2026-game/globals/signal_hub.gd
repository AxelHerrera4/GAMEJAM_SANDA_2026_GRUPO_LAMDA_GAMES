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
signal hack_requested
@warning_ignore("unused_signal")
signal hack_finished(success: bool)



signal player_health_changed(current_health: int, max_health: int)
signal game_over(won: bool)

func emit_on_game_over(won: bool) -> void:
	emit_signal("game_over", won)

func emit_on_player_health_changed(current_health: int, max_health: int) -> void:
	emit_signal("player_health_changed", current_health, max_health)
