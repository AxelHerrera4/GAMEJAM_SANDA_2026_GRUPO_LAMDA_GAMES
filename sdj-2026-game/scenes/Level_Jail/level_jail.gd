extends Node2D

var pistas_encontradas = 0

func registrar_pista():
	pistas_encontradas += 1
	print("Pistas encontradas: ", pistas_encontradas, "/2")
