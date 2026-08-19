extends Node

const LEVEL_BASE = preload("uid://dfv3el8yufriw")
const MAIN = preload("uid://5b7hnaeeb4ni")

func load_level() -> void:
	get_tree().change_scene_to_packed(LEVEL_BASE)

func load_main() -> void:
	get_tree().change_scene_to_packed(MAIN)
