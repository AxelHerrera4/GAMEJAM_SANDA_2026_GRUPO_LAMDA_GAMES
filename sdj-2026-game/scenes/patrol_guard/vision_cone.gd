@tool
class_name VisionCone
extends PointLight2D

## Cono de luz tipo linterna 
@export_range(5.0, 360.0, 1.0) var aperture_degrees: float = 140.0:
	set(value):
		if is_equal_approx(aperture_degrees, value):
			return
		aperture_degrees = value
		_rebuild()

## Largo del cono en pixeles LOCALES
@export_range(16.0, 2000.0, 1.0) var reach: float = 400.0:
	set(value):
		if is_equal_approx(reach, value):
			return
		reach = value
		_rebuild()

## Que tan difuminado esta el borde lateral del cono (0 = filo duro).
@export_range(0.0, 1.0, 0.01) var edge_softness: float = 0.20:
	set(value):
		if is_equal_approx(edge_softness, value):
			return
		edge_softness = value
		_rebuild()

## Que tan rapido se apaga la luz con la distancia (mas alto = se apaga antes).
@export_range(0.5, 6.0, 0.1) var distance_falloff: float = 1.6:
	set(value):
		if is_equal_approx(distance_falloff, value):
			return
		distance_falloff = value
		_rebuild()

@export_range(64, 512, 64) var texture_resolution: int = 128:
	set(value):
		if texture_resolution == value:
			return
		texture_resolution = value
		_rebuild()


func _ready() -> void:
	_rebuild()


## La textura se genera por codigo en cada carga, asi que NO debe guardarse
## dentro del .tscn (si no, Godot incrusta ~1 MB de binario en la escena).
func _validate_property(property: Dictionary) -> void:
	if property.name in ["texture", "texture_scale"]:
		property.usage &= ~PROPERTY_USAGE_STORAGE


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not is_equal_approx(scale.x, scale.y):
		warnings.append("La escala del cono no es uniforme (%.2f, %.2f): el cono se vera deformado. Usa 'reach' para el largo, no la escala." % [scale.x, scale.y])
	return warnings


## Cambia apertura y largo
func configure(new_aperture_degrees: float, new_reach: float) -> void:
	aperture_degrees = new_aperture_degrees
	reach = new_reach


func _rebuild() -> void:
	var n: int = texture_resolution
	var center: float = float(n) * 0.5
	var half_angle: float = deg_to_rad(aperture_degrees) * 0.5
	var soft: float = maxf(deg_to_rad(1.0), half_angle * edge_softness)

	var img: Image = Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var dx: float = float(x) - center + 0.5
			var dy: float = float(y) - center + 0.5
			var dist: float = sqrt(dx * dx + dy * dy) / center
			var alpha: float = 0.0
			if dist <= 1.0:
				var ang: float = absf(atan2(dy, dx))
				var edge: float = 1.0 - smoothstep(half_angle - soft, half_angle, ang)
				var fall: float = pow(1.0 - dist, distance_falloff)
				alpha = clampf(edge * fall, 0.0, 1.0)
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))

	texture = ImageTexture.create_from_image(img)
	texture_scale = reach / center
