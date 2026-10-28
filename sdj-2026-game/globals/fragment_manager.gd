extends Node


const HACK: StringName = &"hack"
const ATTACK: StringName = &"attack"
const CAMOUFLAGE: StringName = &"camouflage"

const CATALOG: Dictionary = {
	HACK: {
		"name": "Fragmento de Hackeo",
		"description": "Permite forzar cerraduras electrónicas y terminales usando {interact}.",
	},
	ATTACK: {
		"name": "Fragmento de Ataque",
		"description": "Acércate a un guardia por la espalda (fuera de su cono de visión) y presiona {attack} para eliminarlo.",
	},
	CAMOUFLAGE: {
		"name": "Fragmento de Camuflaje",
		"description": "Reduce el cono de detección de los guardias un 30%.",
	},
}

signal fragment_granted(fragment_id: StringName)

var _owned: Dictionary = {}


func grant(fragment_id: StringName) -> bool:
	if not CATALOG.has(fragment_id):
		push_warning("FragmentManager: fragmento desconocido '%s'" % fragment_id)
		return false
	if _owned.has(fragment_id):
		return false
	_owned[fragment_id] = true
	fragment_granted.emit(fragment_id)
	SignalHub.emit_on_fragment_progress(_owned.size(), CATALOG.size())
	if _owned.size() >= CATALOG.size():
		SignalHub.emit_on_all_fragments_collected()

	return true


func has_fragment(fragment_id: StringName) -> bool:
	return _owned.has(fragment_id)


func get_owned() -> Array:
	return _owned.keys()


func get_display_name(fragment_id: StringName) -> String:
	if CATALOG.has(fragment_id):
		return CATALOG[fragment_id]["name"]
	return String(fragment_id)


## Lee las teclas/botones asignados a una acción en ProjectSettings -> Input Map.
## Ejemplo: para "attack" devuelve "[Click Izq] o [E]", para "interact" devuelve "[F]".
func get_action_shortcut_text(action_name: StringName) -> String:
	if not InputMap.has_action(action_name):
		return ""
	var parts: Array[String] = []
	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
			if code != 0:
				var key_name: String = OS.get_keycode_string(code)
				var formatted: String = "[%s]" % key_name
				if not parts.has(formatted):
					parts.append(formatted)
		elif event is InputEventMouseButton:
			var btn_name: String = ""
			match event.button_index:
				MOUSE_BUTTON_LEFT: btn_name = "Click Izq"
				MOUSE_BUTTON_RIGHT: btn_name = "Click Der"
				MOUSE_BUTTON_MIDDLE: btn_name = "Click Central"
				_: btn_name = "Mouse %d" % event.button_index
			var formatted: String = "[%s]" % btn_name
			if not parts.has(formatted):
				parts.append(formatted)
	return " o ".join(parts)


func get_description(fragment_id: StringName) -> String:
	if not CATALOG.has(fragment_id):
		return ""
	var raw_desc: String = CATALOG[fragment_id].get("description", "")
	var interact_shortcut: String = get_action_shortcut_text(&"interact")
	var attack_shortcut: String = get_action_shortcut_text(&"attack")
	return raw_desc.format({
		"interact": interact_shortcut if not interact_shortcut.is_empty() else "[F]",
		"attack": attack_shortcut if not attack_shortcut.is_empty() else "[E o Click Izq]"
	})


func clear_all() -> void:
	_owned.clear()
