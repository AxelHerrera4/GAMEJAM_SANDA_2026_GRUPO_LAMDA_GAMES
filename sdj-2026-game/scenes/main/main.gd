extends Control

@export var jail : PackedScene

@onready var panel_credits = $Panel_Credits
@onready var panel_options = $Panel_Options
@onready var audio_hover = $Audio_Hover


func _ready():
	# Ocultamos los paneles al iniciar
	panel_credits.hide()
	panel_options.hide()
	get_tree().paused = false

func _on_button_hovered():
	audio_hover.play()

# --- MAIN MENU BUTTONS ---

func _on_button_play_pressed():
	FragmentManager.clear_all()
	get_tree().paused = false
	GameManager.change_scene(jail, false)

func _on_button_options_pressed():
	panel_options.show()

func _on_button_credits_pressed():
	panel_credits.show()

# --- CLOSE BUTTONS FOR PANELS ---

func _on_button_close_credits_pressed():
	panel_credits.hide()

func _on_button_close_options_pressed():
	panel_options.hide()

# --- VOLUME CONTROL ---

func _on_slider_volume_value_changed(value):
	# Convierte el valor del slider (0.0001 a 1) a decibelios y cambia el volumen general
	var bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(value))
