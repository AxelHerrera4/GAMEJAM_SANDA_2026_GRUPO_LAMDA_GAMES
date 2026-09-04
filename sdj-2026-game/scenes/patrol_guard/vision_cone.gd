@tool
class_name VisionCone
extends PointLight2D

## Cono de linterna del guardia. Es LUZ de verdad: aclara el suelo bajo el
## CanvasModulate "Obscure" de room.tscn, en todos los mapas.
##
## Para eso hace falta una textura con forma de cuna, y esa textura se hornea
## por codigo en una ImageTexture. No hay alternativa: un PointLight2D sin
## textura no ilumina, y GradientTexture2D solo rellena Linear / Radial /
## Square, o sea que no tiene modo angular y nunca puede dar una cuna. La
## imagen son ~64 KiB y NO se guarda en el .tscn (ver _validate_property).
##
## Aparte, y apagado por defecto, hay un Polygon2D hijo interno ("ConePolygon")
## que dibuja la misma cuna como geometria encima. No ilumina nada, solo marca
## el borde mas nitido. Se enciende con `cone_overlay`.
##
## Nada de esto detecta al jugador: eso lo hace patrol_guard.gd por raycast.

## Degradado de la punta del cono (offset 0) hacia afuera (offset 1).
## El alpha decide cuanto ilumina; el RGB tinta (se multiplica con `color`).
## OJO: un Gradient recien creado en el inspector viene negro->blanco con alpha
## 1, que como luz se ve fatal. Usa blanco opaco -> blanco transparente.
@export var light_gradient: Gradient:
	set(value):
		if light_gradient == value:
			return
		if light_gradient and light_gradient.changed.is_connected(_rebuild):
			light_gradient.changed.disconnect(_rebuild)
		light_gradient = value
		if light_gradient and not light_gradient.changed.is_connected(_rebuild):
			light_gradient.changed.connect(_rebuild)
		_rebuild()

## Apertura TOTAL del cono en grados. patrol_guard.gd la sobreescribe con
## angles_of_view segun el estado, asi que en juego manda ese valor, no este.
@export_range(5.0, 360.0, 1.0) var aperture_degrees: float = 140.0:
	set(value):
		# @export_range solo limita el slider del inspector, no las escrituras
		# por codigo. Sin esto, un valor > 360 da un circulo en vez de un cono.
		value = clampf(value, 5.0, 360.0)
		if is_equal_approx(aperture_degrees, value):
			return
		aperture_degrees = value
		if not _is_configuring:
			_rebuild()

## Largo del cono en pixeles LOCALES
@export_range(16.0, 2000.0, 1.0) var reach: float = 400.0:
	set(value):
		if is_equal_approx(reach, value):
			return
		reach = value
		if not _is_configuring:
			_update_reach()

## Que tan difuminado esta el borde lateral del cono (0 = filo duro).
@export_range(0.0, 1.0, 0.01) var edge_softness: float = 0.20:
	set(value):
		if is_equal_approx(edge_softness, value):
			return
		edge_softness = value
		_rebuild()

@export_range(64, 512, 64) var texture_resolution: int = 128:
	set(value):
		if texture_resolution == value:
			return
		texture_resolution = value
		_rebuild()

@export_group("Overlay")
## Dibuja encima un Polygon2D con la misma cuna, para que el borde se lea mas
## nitido sobre suelos ya iluminados. No ilumina: es pintura, no luz.
@export var cone_overlay: bool = false:
	set(value):
		cone_overlay = value
		_rebuild()

## Tinte e intensidad del overlay. El alpha es la intensidad.
@export var cone_color: Color = Color(1.0, 0.95, 0.78, 0.2):
	set(value):
		cone_color = value
		_rebuild()

## El overlay se suma a lo que hay debajo en vez de taparlo.
@export var cone_additive: bool = true:
	set(value):
		cone_additive = value
		_rebuild()

## Cortes a lo ancho del arco del overlay. Mas = borde curvo mas limpio.
@export_range(6, 96, 1) var cone_segments: int = 28:
	set(value):
		cone_segments = value
		_rebuild()

## Anillos a lo largo del overlay. Mas = sigue mejor los puntos intermedios del
## Gradient. Con 1 solo se verian los extremos.
@export_range(1, 16, 1) var cone_rings: int = 6:
	set(value):
		cone_rings = value
		_rebuild()

# Compartido por todos los guardias: si nadie asigna un gradiente, se usa este
# en vez de dejar el cono sin reconstruir.
static var _fallback_gradient: Gradient

var _cone: Polygon2D
var _is_configuring: bool = false


func _ready() -> void:
	if light_gradient and not light_gradient.changed.is_connected(_rebuild):
		light_gradient.changed.connect(_rebuild)
	_rebuild()


func _active_gradient() -> Gradient:
	if light_gradient:
		return light_gradient
	if _fallback_gradient == null:
		_fallback_gradient = _make_default_gradient()
	return _fallback_gradient


## `texture` y `texture_scale` los escribe _rebuild() en cada carga: ni se
## guardan en el .tscn (si no, Godot incrusta la imagen en la escena) ni se
## pueden tocar a mano. Para cambiar el aspecto usa `light_gradient`.
func _validate_property(property: Dictionary) -> void:
	if property.name in ["texture", "texture_scale"]:
		property.usage &= ~PROPERTY_USAGE_STORAGE
		property.usage |= PROPERTY_USAGE_READ_ONLY


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not is_equal_approx(scale.x, scale.y):
		warnings.append("La escala del cono no es uniforme (%.2f, %.2f): el cono se vera deformado y dejara de coincidir con lo que el guardia detecta. Ponla en (1, 1) y usa 'view_distance' del PatrolGuard para el largo." % [scale.x, scale.y])
	if light_gradient != null and _is_dark_gradient(light_gradient):
		warnings.append("El gradiente esta casi todo en negro o transparente: la luz no se vera. Un Gradient nuevo del inspector viene negro->blanco con alpha 1; cambialo a blanco opaco -> blanco transparente.")
	return warnings


## Cambia apertura y largo
func configure(new_aperture_degrees: float, new_reach: float) -> void:
	new_aperture_degrees = clampf(new_aperture_degrees, 5.0, 360.0)
	var aperture_changed: bool = not is_equal_approx(aperture_degrees, new_aperture_degrees)
	var reach_changed: bool = not is_equal_approx(reach, new_reach)
	if not aperture_changed and not reach_changed:
		return

	_is_configuring = true
	aperture_degrees = new_aperture_degrees
	reach = new_reach
	_is_configuring = false

	if aperture_changed:
		_rebuild()
	elif reach_changed:
		_update_reach()


func _update_reach() -> void:
	var center: float = float(texture_resolution) * 0.5
	texture_scale = reach / center
	var cone: Polygon2D = _cone_node()
	if cone != null and cone_overlay:
		_rebuild_cone(cone, _active_gradient())


## Blanco opaco en la punta -> transparente al final.
static func _make_default_gradient() -> Gradient:
	var g: Gradient = Gradient.new()
	g.set_offset(0, 0.0)
	g.set_color(0, Color(1.0, 1.0, 1.0, 1.0))
	g.set_offset(1, 1.0)
	g.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	g.add_point(0.55, Color(1.0, 1.0, 1.0, 0.35))
	return g


## Un gradiente cuyo brillo*alpha es casi cero en todo el recorrido no ilumina
## nada, y desde el editor no hay forma de darse cuenta salvo por esto.
static func _is_dark_gradient(g: Gradient) -> bool:
	var brightest: float = 0.0
	for i in 16:
		var c: Color = g.sample(float(i) / 15.0)
		brightest = maxf(brightest, maxf(c.r, maxf(c.g, c.b)) * c.a)
	return brightest < 0.08


func _rebuild() -> void:
	var gradient: Gradient = _active_gradient()
	_rebuild_light(gradient)
	var cone: Polygon2D = _cone_node()
	if cone != null:
		cone.visible = cone_overlay
		if cone_overlay:
			_rebuild_cone(cone, gradient)
	update_configuration_warnings()


## Hornea la cuna en la textura de la luz. La forma sale del angulo de cada
## pixel respecto al centro; el gradiente pone color y desvanecido por distancia.
func _rebuild_light(gradient: Gradient) -> void:
	var n: int = texture_resolution
	var center: float = float(n) * 0.5
	var half_angle: float = deg_to_rad(aperture_degrees) * 0.5
	var soft: float = maxf(deg_to_rad(1.0), half_angle * edge_softness)

	# Gradient.sample() por pixel es caro y la distancia solo tiene `n` valores
	# utiles, asi que lo cacheamos una vez por reconstruccion.
	var lut: PackedColorArray = PackedColorArray()
	lut.resize(n)
	for i in n:
		lut[i] = gradient.sample(float(i) / float(n - 1))

	# create_empty ya viene en (0,0,0,0): fuera del circulo no tocamos nada.
	var img: Image = Image.create_empty(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			var dx: float = float(x) - center + 0.5
			var dy: float = float(y) - center + 0.5
			var dist: float = sqrt(dx * dx + dy * dy) / center
			if dist > 1.0:
				continue
			var ang: float = absf(atan2(dy, dx))
			var edge: float = 1.0 - smoothstep(half_angle - soft, half_angle, ang)
			var c: Color = lut[int(dist * float(n - 1))]
			c.a = clampf(c.a * edge, 0.0, 1.0)
			img.set_pixel(x, y, c)

	if texture is ImageTexture:
		var itex: ImageTexture = texture as ImageTexture
		if itex.get_width() == n and itex.get_height() == n:
			itex.update(img)
		else:
			itex.set_image(img)
	else:
		var old_tex: Texture2D = texture
		texture = ImageTexture.create_from_image(img)
		old_tex = null

	texture_scale = reach / center
	# Por si quedo apagada de cuando el cono era solo geometria.
	enabled = true


func _cone_node() -> Polygon2D:
	if is_instance_valid(_cone):
		return _cone
	_cone = get_node_or_null("ConePolygon") as Polygon2D
	if _cone == null and is_node_ready():
		_cone = Polygon2D.new()
		_cone.name = "ConePolygon"
		add_child(_cone, false, Node.INTERNAL_MODE_BACK)
	return _cone


## Construye la cuna del overlay como malla: un vertice en la punta y
## `cone_rings` anillos de `cone_segments + 1` vertices. Cada vertice lleva su
## color, asi que el degradado lo interpola la GPU sin textura de por medio.
func _rebuild_cone(cone: Polygon2D, gradient: Gradient) -> void:
	var half_angle: float = deg_to_rad(aperture_degrees) * 0.5
	var soft: float = maxf(deg_to_rad(1.0), half_angle * edge_softness)
	var arc: int = cone_segments + 1

	var points: PackedVector2Array = PackedVector2Array()
	var colors: PackedColorArray = PackedColorArray()

	# Vertice 0: la punta, pegada al guardia.
	points.append(Vector2.ZERO)
	colors.append(gradient.sample(0.0))

	for r in range(1, cone_rings + 1):
		var t: float = float(r) / float(cone_rings)
		var ring_color: Color = gradient.sample(t)
		for i in arc:
			var a: float = lerpf(-half_angle, half_angle, float(i) / float(cone_segments))
			points.append(Vector2(cos(a), sin(a)) * (reach * t))
			# Desvanecido lateral: el borde del cono se apaga hacia los lados.
			var edge: float = 1.0 - smoothstep(half_angle - soft, half_angle, absf(a))
			var c: Color = ring_color
			c.a *= edge
			colors.append(c)

	var faces: Array[PackedInt32Array] = []
	# Abanico de triangulos entre la punta y el primer anillo.
	for i in cone_segments:
		faces.append(PackedInt32Array([0, 1 + i, 1 + i + 1]))
	# Quads entre anillos consecutivos.
	for r in range(0, cone_rings - 1):
		var base: int = 1 + r * arc
		var next_ring: int = base + arc
		for i in cone_segments:
			faces.append(PackedInt32Array([base + i, base + i + 1, next_ring + i + 1, next_ring + i]))

	cone.polygon = points
	cone.polygons = faces
	cone.vertex_colors = colors
	cone.color = cone_color
	# Que las lamparas del nivel no le sumen luz encima: el overlay debe verse
	# igual en un pasillo iluminado que en uno a oscuras.
	cone.light_mask = 0
	cone.z_index = -1

	var mat: CanvasItemMaterial = cone.material as CanvasItemMaterial
	if mat == null:
		mat = CanvasItemMaterial.new()
		cone.material = mat
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD if cone_additive else CanvasItemMaterial.BLEND_MODE_MIX
