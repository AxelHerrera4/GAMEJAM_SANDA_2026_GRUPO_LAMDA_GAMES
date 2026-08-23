class_name Computer
extends Area2D

var is_hacked: bool = false

func _ready() -> void:
	add_to_group("interactable")

func get_prompt_text() -> String:
	if is_hacked:
		return "Sistema hackeado"
	return "Hackear computadora"

func interact(_player: Player) -> void:
	print("try to interact")
	if is_hacked:
		return
	
	SignalHub.emit_on_hack_requested()
	# Esperamos a que el minijuego termine
	var success: bool = await SignalHub.hack_finished
	if success:
		is_hacked = true
		FragmentManager.grant(FragmentManager.ATTACK)
