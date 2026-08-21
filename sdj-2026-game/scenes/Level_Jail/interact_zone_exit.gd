extends Area2D

## Llamado por el Player cuando se pulsa la tecla de interactuar (F)
## estando dentro de esta zona.
func interact(_player: Node) -> void:
	print("¡Aiden llegó a la salida! Cambiando de nivel...")
	get_tree().change_scene_to_file("res://scenes/level_base/level_base.tscn")
