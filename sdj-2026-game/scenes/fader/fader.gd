class_name Fader
extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func fade() -> void:
	animation_player.play("fade")


func change_scene() -> void:
	GameManager.change_to_next_scene()
