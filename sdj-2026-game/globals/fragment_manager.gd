extends Node


const HACK: StringName = &"hack"

const CATALOG: Dictionary = {
	HACK: {
		"name": "Fragmento de Hackeo",
		"description": "Un retazo de código capaz de forzar cerraduras electrónicas.",
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
	return true


func has_fragment(fragment_id: StringName) -> bool:
	return _owned.has(fragment_id)


func get_owned() -> Array:
	return _owned.keys()


func get_display_name(fragment_id: StringName) -> String:
	if CATALOG.has(fragment_id):
		return CATALOG[fragment_id]["name"]
	return String(fragment_id)


func get_description(fragment_id: StringName) -> String:
	if CATALOG.has(fragment_id):
		return CATALOG[fragment_id]["description"]
	return ""


func clear_all() -> void:
	_owned.clear()
