extends Node

const LEVEL_BASE = preload("uid://dfv3el8yufriw")
const MAIN = preload("uid://5b7hnaeeb4ni")

func load_level() -> void:
	get_tree().change_scene_to_packed(LEVEL_BASE)

func load_main() -> void:
	get_tree().change_scene_to_packed(MAIN)

func change_scene(scene_path: String) -> void:
	if scene_path.is_empty():
		push_warning("GameManager: Intento de cambiar a una ruta de escena vacía.")
		return
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		push_error("GameManager: La escena '%s' no existe." % scene_path)
