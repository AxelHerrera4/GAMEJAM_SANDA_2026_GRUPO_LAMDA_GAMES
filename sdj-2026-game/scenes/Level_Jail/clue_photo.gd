extends Area2D

var ya_revisada = false

# Esta es la función especial que se ejecutará sola cuando presiones la 'F'
func interact(_player: Node) -> void:
	if not ya_revisada:
		ya_revisada = true
		print("Has mirado la foto de la chica en la habitación.")
		
		# Le avisamos al script principal del nivel que sume una pista
		get_parent().registrar_pista()
	else:
		print("Ya guardaste esta foto en tu inventario.")
