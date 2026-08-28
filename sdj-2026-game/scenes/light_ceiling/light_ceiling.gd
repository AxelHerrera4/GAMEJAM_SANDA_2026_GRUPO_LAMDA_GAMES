extends PointLight2D


func _ready():
	# Inicia el ciclo de la luz en cuanto arranca el nivel
	_ciclo_de_parpadeo()

func _ciclo_de_parpadeo():
	# Este 'while true' hace que el ciclo se repita infinitamente
	while true:
		# 1. Luz normal por 5 segundos
		energy = 1.0
		await get_tree().create_timer(5.0).timeout
		
		# 2. El foco falla y parpadea rápido unas cuantas veces
		for i in range(3): # Cambia el 3 si quieres más o menos parpadeos
			energy = randf_range(0.1, 0.5) # Baja la intensidad
			await get_tree().create_timer(0.1).timeout # Espera una fracción de segundo
			energy = 1.0 # Vuelve a la normalidad
			await get_tree().create_timer(0.1).timeout
